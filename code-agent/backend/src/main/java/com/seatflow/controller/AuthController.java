package com.seatflow.controller;

import com.seatflow.common.result.Result;
import com.seatflow.dto.request.LoginRequest;
import com.seatflow.dto.response.LoginResponse;
import com.seatflow.dto.response.UserInfoResponse;
import com.seatflow.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * POST /api/auth/login — 用户名+密码登录，返回 JWT
     */
    @PostMapping("/login")
    public Result<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return Result.ok(response);
    }

    /**
     * GET /api/auth/me — 获取当前登录用户信息
     * [SECURITY-DISABLED] 改为传 username 参数（原从 SecurityContext 获取）
     */
    @GetMapping("/me")
    public Result<UserInfoResponse> getCurrentUser(
            @RequestParam(value = "username", required = false) String username) {
        // [SECURITY-DISABLED] 如果有 username 参数，按用户名查询；否则返回空
        if (username != null && !username.isBlank()) {
            UserInfoResponse userInfo = authService.getUserByUsername(username);
            return Result.ok(userInfo);
        }
        return Result.fail(400, "请提供 username 参数");
    }
}
