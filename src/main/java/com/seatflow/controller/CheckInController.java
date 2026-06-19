package com.seatflow.controller;

import com.seatflow.common.result.Result;
import com.seatflow.entity.Reservation;
import com.seatflow.service.CheckInService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 学生端签到接口 — A-RES03: POST /api/reservations/check-in
 */
@RestController
@RequestMapping("/api/reservations/check-in")
@RequiredArgsConstructor
public class CheckInController {

    private final CheckInService checkInService;

    /**
     * A-RES03: 学生签到 — 只需输入签到编码，自动查找对应预约
     */
    @PostMapping
    public Result<Map<String, Object>> checkIn(@RequestBody Map<String, String> body) {
        String code = body.get("code");
        if (code == null || code.trim().isEmpty()) {
            return Result.fail(400, "请输入签到编码");
        }

        Reservation reservation = checkInService.checkIn(code.trim());
        return Result.ok(Map.of(
                "reservationId", reservation.getId(),
                "status", reservation.getStatus(),
                "message", "签到成功"
        ));
    }
}
