package com.seatflow.controller;

import com.seatflow.common.result.Result;
import com.seatflow.dto.request.SeatUpdateRequest;
import com.seatflow.dto.response.SeatResponse;
import com.seatflow.service.SeatService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * A-SEAT04~05: 独立路径座位更新/注销（不需要 roomId 的情况）
 */
@RestController
@RequestMapping("/api/admin/seats")
@RequiredArgsConstructor
public class AdminSeatManageController {

    private final SeatService seatService;

    /**
     * A-SEAT04: 更新座位
     */
    @PutMapping("/{id}")
    public Result<SeatResponse> update(@PathVariable Long id, @RequestBody SeatUpdateRequest request) {
        return Result.ok(seatService.update(id, request));
    }

    /**
     * A-SEAT05: 注销座位（逻辑删除）
     */
    @DeleteMapping("/{id}")
    public Result<Void> remove(@PathVariable Long id) {
        seatService.remove(id);
        return Result.ok();
    }
}
