package com.seatflow.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.seatflow.common.exception.BusinessException;
import com.seatflow.dto.response.SeatResponse;
import com.seatflow.entity.Reservation;
import com.seatflow.entity.Room;
import com.seatflow.entity.Seat;
import com.seatflow.mapper.ReservationMapper;
import com.seatflow.mapper.RoomMapper;
import com.seatflow.mapper.SeatMapper;
import com.seatflow.security.CustomUserDetails;
import com.seatflow.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * F007: 座位搜索服务
 * 学生多条件搜索可用座位
 */
@Service
@RequiredArgsConstructor
public class SeatSearchService {

    private final SeatMapper seatMapper;
    private final RoomMapper roomMapper;
    private final ReservationMapper reservationMapper;

    public List<SeatResponse> search(Long roomId, String dateStr, String startTimeStr, String endTimeStr,
                                      String socketType, String position, Long departmentId) {
        // 日期时间参数为可选，不传时不做时段冲突过滤
        LocalDate date = (dateStr != null && !dateStr.isEmpty()) ? LocalDate.parse(dateStr) : null;
        LocalTime startTime = (startTimeStr != null && !startTimeStr.isEmpty()) ? LocalTime.parse(startTimeStr) : null;
        LocalTime endTime = (endTimeStr != null && !endTimeStr.isEmpty()) ? LocalTime.parse(endTimeStr) : null;

        CustomUserDetails currentUser = SecurityUtils.getCurrentUser();
        if (currentUser == null) {
            throw new BusinessException(401, "未登录或登录已过期");
        }

        // 1. 根据当前用户身份过滤自习室：普通学生只能看全校共享或本院系自习室
        LambdaQueryWrapper<Room> roomWrapper = new LambdaQueryWrapper<>();
        roomWrapper.eq(Room::getStatus, "OPEN");
        if (roomId != null) {
            roomWrapper.eq(Room::getId, roomId);
        }
        if (SecurityUtils.isAdmin()) {
            if (departmentId != null) {
                roomWrapper.and(w -> w.isNull(Room::getDepartmentId).or().eq(Room::getDepartmentId, departmentId));
            }
        } else if (currentUser.getDepartmentId() != null) {
            roomWrapper.and(w -> w.isNull(Room::getDepartmentId).or().eq(Room::getDepartmentId, currentUser.getDepartmentId()));
        } else {
            roomWrapper.isNull(Room::getDepartmentId);
        }

        List<Room> rooms = roomMapper.selectList(roomWrapper);

        List<Long> accessibleRoomIds = rooms.stream()
                .map(Room::getId)
                .collect(Collectors.toList());

        if (accessibleRoomIds.isEmpty()) {
            return List.of();
        }

        // 2. Filter seats by room, socketType, position
        LambdaQueryWrapper<Seat> seatWrapper = new LambdaQueryWrapper<>();
        seatWrapper.in(Seat::getRoomId, accessibleRoomIds)
                .eq(Seat::getStatus, "AVAILABLE");
        if (socketType != null && !socketType.isEmpty()) {
            if ("HAS_SOCKET".equals(socketType)) {
                seatWrapper.in(Seat::getSocketType, List.of("FIXED", "TRACK"));
            } else {
                seatWrapper.eq(Seat::getSocketType, socketType);
            }
        }
        if (position != null && !position.isEmpty()) {
            seatWrapper.eq(Seat::getPosition, position);
        }

        List<Seat> seats = seatMapper.selectList(seatWrapper);

        // 3. Filter out seats that are already reserved in the time range (仅在时间参数完整时过滤)
        final List<Long> reservedSeatIds;
        if (date != null && startTime != null && endTime != null) {
            final LocalDate finalDate = date;
            final LocalTime finalStartTime = startTime;
            final LocalTime finalEndTime = endTime;
            LambdaQueryWrapper<Reservation> resWrapper = new LambdaQueryWrapper<>();
            resWrapper.eq(Reservation::getDate, finalDate)
                    .in(Reservation::getStatus, List.of("PENDING", "CHECKED_IN"))
                    .lt(Reservation::getStartTime, finalEndTime)
                    .gt(Reservation::getEndTime, finalStartTime);
            reservedSeatIds = reservationMapper.selectList(resWrapper).stream()
                    .map(Reservation::getSeatId)
                    .collect(Collectors.toList());
        } else {
            reservedSeatIds = List.of();
        }

        // 4. Build room id -> name map
        java.util.Map<Long, String> roomNameMap = rooms.stream()
                .collect(java.util.stream.Collectors.toMap(Room::getId, Room::getName));

        // 5. Build response
        return seats.stream()
                .filter(seat -> !reservedSeatIds.contains(seat.getId()))
                .map(seat -> SeatResponse.builder()
                        .id(seat.getId())
                        .roomId(seat.getRoomId())
                        .roomName(roomNameMap.getOrDefault(seat.getRoomId(), ""))
                        .seatNumber(seat.getSeatNumber())
                        .rowNum(seat.getRowNum())
                        .colNum(seat.getColNum())
                        .socketType(seat.getSocketType())
                        .position(seat.getPosition())
                        .status(seat.getStatus())
                        .isAvailable(true)
                        .build())
                .collect(Collectors.toList());
    }
}
