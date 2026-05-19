package com.seatflow.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {

    private String token;
    private long expiresIn;   // 过期时间（毫秒）
    private UserInfoResponse userInfo;  // [SECURITY-DISABLED] MVP 阶段直接返回用户信息
}
