package com.seatflow.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.seatflow.common.result.Result;
import com.seatflow.dto.request.ReservationCreateRequest;
import com.seatflow.dto.response.ReservationResponse;
import com.seatflow.service.ReservationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/reservations")
@RequiredArgsConstructor
@PreAuthorize("hasAnyAuthority('reservation:manage', 'reservation:view')")
public class AdminReservationController {

    private final ReservationService reservationService;

    /**
     * A-RES07: 全部预约（分页+筛选）
     */
    @GetMapping
    public Result<Page<ReservationResponse>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String date) {
        return Result.ok(reservationService.listForAdmin(page, size, status, userId, date));
    }

    /**
     * A-RES08: 代客预约
     */
    @PostMapping
    @PreAuthorize("hasAuthority('reservation:manage')")
    public Result<ReservationResponse> createForUser(
            @RequestParam Long userId,
            @Valid @RequestBody ReservationCreateRequest request) {
        return Result.ok(reservationService.adminCreate(userId, request));
    }

    /**
     * A-RES09: 管理员取消预约
     */
    @PutMapping("/{id}/cancel")
    @PreAuthorize("hasAuthority('reservation:manage')")
    public Result<ReservationResponse> cancel(@PathVariable Long id) {
        return Result.ok(reservationService.adminCancel(id));
    }
}
