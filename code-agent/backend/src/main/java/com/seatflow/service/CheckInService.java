package com.seatflow.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.seatflow.common.exception.BusinessException;
import com.seatflow.entity.CheckInCode;
import com.seatflow.entity.Reservation;
import com.seatflow.entity.Room;
import com.seatflow.entity.Seat;
import com.seatflow.entity.User;
import com.seatflow.mapper.CheckInCodeMapper;
import com.seatflow.mapper.ReservationMapper;
import com.seatflow.mapper.RoomMapper;
import com.seatflow.mapper.SeatMapper;
import com.seatflow.mapper.UserMapper;
import com.seatflow.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Random;

@Service
@RequiredArgsConstructor
@Slf4j
public class CheckInService {

    private final CheckInCodeMapper checkInCodeMapper;
    private final ReservationMapper reservationMapper;
    private final RoomMapper roomMapper;
    private final ViolationService violationService;
    private final NotificationService notificationService;
    private final UserMapper userMapper;
    private final SeatMapper seatMapper;

    /**
     * 获取/生成今日签到编码
     */
    @Transactional
    public String getTodayCode(Long roomId) {
        Room room = roomMapper.selectById(roomId);
        if (room == null) throw new BusinessException(404, "自习室不存在");

        LocalDate today = LocalDate.now();
        LambdaQueryWrapper<CheckInCode> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(CheckInCode::getRoomId, roomId).eq(CheckInCode::getCodeDate, today);
        CheckInCode existing = checkInCodeMapper.selectOne(wrapper);

        if (existing != null) {
            return existing.getCode();
        }

        // 生成6位随机数字编码
        String code = String.format("%06d", new Random().nextInt(1000000));
        CheckInCode newCode = new CheckInCode();
        newCode.setRoomId(roomId);
        newCode.setCodeDate(today);
        newCode.setCode(code);
        checkInCodeMapper.insert(newCode);

        log.info("生成签到编码: roomId={}, date={}, code={}", roomId, today, code);
        return code;
    }

    /**
     * 学生签到 — 按 PRD 签到校验链路（6步）
     * 只需输入签到编码，自动查找对应预约
     */
    @Transactional
    public Reservation checkIn(String code) {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) throw new BusinessException(401, "未登录");

        // 1. 根据 code 查 t_check_in_code → 得到 room_id + code_date
        LambdaQueryWrapper<CheckInCode> codeWrapper = new LambdaQueryWrapper<>();
        codeWrapper.eq(CheckInCode::getCode, code);
        CheckInCode checkInCode = checkInCodeMapper.selectOne(codeWrapper);
        if (checkInCode == null) {
            throw new BusinessException(400, "签到编码无效");
        }

        // 2. 校验 code_date = 当日（非当日编码无效）
        LocalDate today = LocalDate.now();
        if (!checkInCode.getCodeDate().equals(today)) {
            throw new BusinessException(400, "签到编码已过期，请使用当日编码");
        }

        // 3. 查当前用户在该 room_id + 当日 的 PENDING 状态预约（取开始时间最近的）
        LocalDateTime now = LocalDateTime.now();
        LambdaQueryWrapper<Reservation> resWrapper = new LambdaQueryWrapper<>();
        resWrapper.eq(Reservation::getUserId, userId)
                .eq(Reservation::getRoomId, checkInCode.getRoomId())
                .eq(Reservation::getDate, today)
                .eq(Reservation::getStatus, "PENDING")
                .orderByAsc(Reservation::getStartTime);
        java.util.List<Reservation> pendingList = reservationMapper.selectList(resWrapper);

        // 4. 找到签到时间窗口内的预约（开始前15min ~ 结束时间）
        Reservation reservation = null;
        for (Reservation r : pendingList) {
            LocalDateTime rStart = LocalDateTime.of(r.getDate(), r.getStartTime());
            LocalDateTime rEnd = LocalDateTime.of(r.getDate(), r.getEndTime());
            if (!now.isBefore(rStart.minusMinutes(15)) && !now.isAfter(rEnd)) {
                reservation = r;
                break;
            }
        }

        // 若没有在窗口内的预约，再检查是否有任何 PENDING 预约给出更精准错误
        if (reservation == null) {
            if (pendingList.isEmpty()) {
                throw new BusinessException(400, "您在该教室无待签到预约");
            }
            // 有预约但不在窗口内
            Reservation earliest = pendingList.get(0);
            LocalDateTime eStart = LocalDateTime.of(earliest.getDate(), earliest.getStartTime());
            if (now.isBefore(eStart.minusMinutes(15))) {
                throw new BusinessException(400, "签到时间未到，请在预约开始前15分钟内签到");
            }
            throw new BusinessException(400, "预约时间已过，无法签到");
        }

        // 6. 更新预约状态 PENDING → CHECKED_IN
        reservation.setStatus("CHECKED_IN");
        reservationMapper.updateById(reservation);

        log.info("用户{}签到成功, reservationId={}, room={}", userId, reservation.getId(), reservation.getRoomId());
        return reservation;
    }

    /**
     * 超时未签到自动取消 + 记录违约
     * 由定时任务调用 — 不限制日期，检查所有 PENDING 状态且开始时间+15min < 当前时间的预约
     */
    @Transactional
    public int autoCancelTimeout() {
        LocalDateTime now = LocalDateTime.now();

        // 查找所有PENDING且开始时间+15min < 当前时间的预约（不限日期）
        LambdaQueryWrapper<Reservation> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Reservation::getStatus, "PENDING")
                .isNotNull(Reservation::getDate)
                .isNotNull(Reservation::getStartTime);

        java.util.List<Reservation> allPending = reservationMapper.selectList(wrapper);
        int count = 0;
        for (Reservation r : allPending) {
            LocalDateTime reservationStart = LocalDateTime.of(r.getDate(), r.getStartTime());
            if (now.isAfter(reservationStart.plusMinutes(15))) {
                r.setStatus("CANCELLED");
                r.setCancelledBy("SYSTEM");
                reservationMapper.updateById(r);

                // 记录违约
                violationService.recordTimeout(r.getUserId(), r.getId());

                // 发送通知
                try {
                    User user = userMapper.selectById(r.getUserId());
                    Seat seat = seatMapper.selectById(r.getSeatId());
                    Room room = roomMapper.selectById(r.getRoomId());
                    String roomName = room != null ? room.getName() : "未知自习室";
                    String seatNumber = seat != null ? seat.getSeatNumber() : "未知座位";
                    notificationService.notifyAutoCancel(r.getUserId(),
                            user != null ? user.getEmail() : null,
                            roomName, seatNumber, r.getDate().toString());
                } catch (Exception e) {
                    log.error("发送自动取消通知失败: reservationId={}", r.getId(), e);
                }

                count++;
            }
        }

        if (count > 0) {
            log.info("自动取消超时预约: {}条", count);
        }
        return count;
    }

    /**
     * 签到前15分钟提醒
     * 由定时任务调用
     */
    public int remindBeforeCheckIn() {
        LocalDateTime now = LocalDateTime.now();
        LocalDate today = now.toLocalDate();
        java.time.LocalTime currentTime = now.toLocalTime();
        java.time.LocalTime remindAfter = currentTime.plusMinutes(14);
        java.time.LocalTime remindBefore = currentTime.plusMinutes(16);

        LambdaQueryWrapper<Reservation> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Reservation::getStatus, "PENDING")
                .eq(Reservation::getDate, today)
                .ge(Reservation::getStartTime, remindAfter)
                .le(Reservation::getStartTime, remindBefore)
                .eq(Reservation::getRemindedBefore, 0);

        java.util.List<Reservation> toRemind = reservationMapper.selectList(wrapper);
        for (Reservation r : toRemind) {
            r.setRemindedBefore(1);
            reservationMapper.updateById(r);

            // 发送签到提醒通知
            try {
                User user = userMapper.selectById(r.getUserId());
                Seat seat = seatMapper.selectById(r.getSeatId());
                Room room = roomMapper.selectById(r.getRoomId());
                String roomName = room != null ? room.getName() : "未知自习室";
                String seatNumber = seat != null ? seat.getSeatNumber() : "未知座位";
                notificationService.notifyCheckInReminder(r.getUserId(),
                        user != null ? user.getEmail() : null,
                        roomName, seatNumber);
            } catch (Exception e) {
                log.error("发送签到提醒通知失败: reservationId={}", r.getId(), e);
            }

            log.info("签到提醒: userId={}, reservationId={}, startTime={}", r.getUserId(), r.getId(), r.getStartTime());
        }
        return toRemind.size();
    }

    /**
     * 签到后超时警告
     * 由定时任务调用
     */
    public int warnLateCheckIn() {
        LocalDateTime now = LocalDateTime.now();
        LocalDate today = now.toLocalDate();
        java.time.LocalTime currentTime = now.toLocalTime();

        // 已过开始时间10min但未签到的预约 → 发出警告
        LambdaQueryWrapper<Reservation> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Reservation::getStatus, "PENDING")
                .eq(Reservation::getDate, today)
                .lt(Reservation::getStartTime, currentTime.minusMinutes(10))
                .gt(Reservation::getStartTime, currentTime.minusMinutes(15))
                .eq(Reservation::getWarnedLate, 0);

        java.util.List<Reservation> toWarn = reservationMapper.selectList(wrapper);
        for (Reservation r : toWarn) {
            r.setWarnedLate(1);
            reservationMapper.updateById(r);
            log.warn("签到逾期警告: userId={}, reservationId={}", r.getUserId(), r.getId());
        }
        return toWarn.size();
    }
}
