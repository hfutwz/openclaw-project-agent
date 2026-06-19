package com.seatflow.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Date;
import java.util.List;

@Slf4j
@Component
public class JwtTokenProvider {

    private final SecretKey key;
    private final long expirationMs;

    public JwtTokenProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration}") long expirationMs) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
    }

    /**
     * 生成 JWT Token（兼容旧调用）
     */
    public String generateToken(Long userId, String username, List<String> roles) {
        return generateToken(userId, username, roles, Collections.emptyList());
    }

    /**
     * 生成 JWT Token（包含用户 ID、角色与权限 claims）
     */
    public String generateToken(Long userId, String username, List<String> roles, List<String> permissions) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expirationMs);

        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("username", username)
                .claim("roles", roles != null ? roles : Collections.emptyList())
                .claim("permissions", permissions != null ? permissions : Collections.emptyList())
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    /**
     * 生成 JWT Token（单参数版，供测试使用）
     */
    public String generateToken(String username) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expirationMs);

        return Jwts.builder()
                .subject("0")
                .claim("username", username)
                .claim("roles", Collections.emptyList())
                .claim("permissions", Collections.emptyList())
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    /**
     * 从 Token 中解析用户 ID
     */
    public Long getUserIdFromToken(String token) {
        Claims claims = parseToken(token);
        return Long.parseLong(claims.getSubject());
    }

    /**
     * 从 Token 中解析用户名
     */
    public String getUsernameFromToken(String token) {
        Claims claims = parseToken(token);
        return claims.get("username", String.class);
    }

    /**
     * 从 Token 中解析用户名（测试兼容别名）
     */
    public String getUsername(String token) {
        return getUsernameFromToken(token);
    }

    /**
     * 从 Token 中解析角色列表
     */
    @SuppressWarnings("unchecked")
    public List<String> getRolesFromToken(String token) {
        Claims claims = parseToken(token);
        List<String> roles = claims.get("roles", List.class);
        return roles != null ? roles : Collections.emptyList();
    }

    /**
     * 从 Token 中解析权限列表
     */
    @SuppressWarnings("unchecked")
    public List<String> getPermissionsFromToken(String token) {
        Claims claims = parseToken(token);
        List<String> permissions = claims.get("permissions", List.class);
        return permissions != null ? permissions : Collections.emptyList();
    }

    /**
     * 验证 Token 是否有效（未过期且签名正确）
     */
    public boolean validateToken(String token) {
        try {
            parseToken(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("Invalid JWT token: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 获取 Token 过期时间（毫秒）
     */
    public long getExpirationMs() {
        return expirationMs;
    }

    /**
     * 获取 Token 过期时间（测试兼容别名）
     */
    public long getExpiration() {
        return expirationMs;
    }

    private Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
