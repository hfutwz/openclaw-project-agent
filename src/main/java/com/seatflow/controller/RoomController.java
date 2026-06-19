package com.seatflow.controller;

import com.seatflow.common.result.Result;
import com.seatflow.dto.response.RoomDetailResponse;
import com.seatflow.dto.response.RoomResponse;
import com.seatflow.security.CustomUserDetails;
import com.seatflow.security.SecurityUtils;
import com.seatflow.service.RoomService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;

    /**
     * A-ROOM01: 学生端自习室列表（有权限+开放的）
     */
    @GetMapping
    public Result<List<RoomResponse>> listRooms() {
        CustomUserDetails currentUser = SecurityUtils.getCurrentUser();
        Long departmentId = currentUser != null ? currentUser.getDepartmentId() : null;
        return Result.ok(roomService.listForStudent(departmentId));
    }

    /**
     * A-ROOM02: 自习室详情（含座位概览）
     */
    @GetMapping("/{id}")
    public Result<RoomDetailResponse> getRoomDetail(@PathVariable Long id) {
        return Result.ok(roomService.getDetail(id));
    }
}
