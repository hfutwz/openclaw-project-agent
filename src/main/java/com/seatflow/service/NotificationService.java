package com.seatflow.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 通知服务 — WebSocket + 邮件双通道推送
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final SimpMessagingTemplate messagingTemplate;
    private final JavaMailSender mailSender;

    /**
     * WebSocket 推送通知到指定用户
     *
     * @param userId 用户ID
     * @param type   通知类型: REMINDER, CHECK_IN_SUCCESS, AUTO_CANCEL, VIOLATION, WARNING
     * @param title  通知标题
     * @param message 通知内容
     */
    public void sendWebSocket(Long userId, String type, String title, String message) {
        try {
            Map<String, Object> payload = Map.of(
                    "type", type,
                    "title", title,
                    "message", message,
                    "timestamp", System.currentTimeMillis()
            );
            messagingTemplate.convertAndSend("/topic/notifications/" + userId, payload);
            log.info("WebSocket 通知已推送: userId={}, type={}, title={}", userId, type, title);
        } catch (Exception e) {
            log.error("WebSocket 通知推送失败: userId={}, type={}", userId, type, e);
        }
    }

    /**
     * 邮件通知
     */
    public void sendEmail(String to, String subject, String content) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(to);
            message.setSubject("SeatFlow - " + subject);
            message.setText(content);
            mailSender.send(message);
            log.info("邮件通知已发送: to={}, subject={}", to, subject);
        } catch (Exception e) {
            // 邮件发送失败不影响主流程（SMTP 可能是示例配置）
            log.warn("邮件通知发送失败: to={}, subject={}. 当前为示例配置，请配置真实 SMTP", to, subject, e);
        }
    }

    /**
     * 双通道推送（WebSocket + 邮件）
     */
    public void sendDual(Long userId, String userEmail, String type, String title, String message) {
        sendWebSocket(userId, type, title, message);
        if (userEmail != null && !userEmail.isEmpty()) {
            sendEmail(userEmail, title, message);
        }
    }

    // ==================== 业务场景快捷方法 ====================

    /**
     * 预约成功通知
     */
    public void notifyReservationCreated(Long userId, String userEmail, String roomName, String seatNumber, String date, String timeRange) {
        String title = "预约成功";
        String msg = String.format("您已成功预约 %s 的 %s 座位，时间：%s %s", roomName, seatNumber, date, timeRange);
        sendDual(userId, userEmail, "RESERVATION_CREATED", title, msg);
    }

    /**
     * 签到提醒（预约开始前15分钟）
     */
    public void notifyCheckInReminder(Long userId, String userEmail, String roomName, String seatNumber) {
        String title = "签到提醒";
        String msg = String.format("您的 %s %s 座位预约即将开始，请尽快签到！", roomName, seatNumber);
        sendDual(userId, userEmail, "CHECK_IN_REMINDER", title, msg);
    }

    /**
     * 签到成功通知
     */
    public void notifyCheckInSuccess(Long userId, String userEmail, String roomName, String seatNumber) {
        String title = "签到成功";
        String msg = String.format("您已成功签到 %s %s 座位", roomName, seatNumber);
        sendDual(userId, userEmail, "CHECK_IN_SUCCESS", title, msg);
    }

    /**
     * 自动取消通知（超时未签到）
     */
    public void notifyAutoCancel(Long userId, String userEmail, String roomName, String seatNumber, String date) {
        String title = "预约已自动取消";
        String msg = String.format("您预约的 %s %s 座位（%s）因超时未签到已被自动取消，并记录一次违约。", roomName, seatNumber, date);
        sendDual(userId, userEmail, "AUTO_CANCEL", title, msg);
    }

    /**
     * 违约通知
     */
    public void notifyViolation(Long userId, String userEmail, String reason) {
        String title = "违约通知";
        String msg = String.format("您有一条违约记录，原因：%s。请遵守预约规则。", reason);
        sendDual(userId, userEmail, "VIOLATION", title, msg);
    }

    /**
     * 管理员取消通知
     */
    public void notifyAdminCancel(Long userId, String userEmail, String roomName, String seatNumber, String date) {
        String title = "预约已被管理员取消";
        String msg = String.format("您预约的 %s %s 座位（%s）已被管理员取消。", roomName, seatNumber, date);
        sendDual(userId, userEmail, "ADMIN_CANCEL", title, msg);
    }
}
