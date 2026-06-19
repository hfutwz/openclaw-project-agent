package com.seatflow;

import com.seatflow.dto.request.LoginRequest;
import com.seatflow.entity.Permission;
import com.seatflow.entity.Role;
import com.seatflow.entity.User;
import com.seatflow.mapper.PermissionMapper;
import com.seatflow.mapper.RoleMapper;
import com.seatflow.mapper.UserMapper;
import com.seatflow.security.JwtTokenProvider;
import com.seatflow.service.AuthService;
import com.seatflow.service.impl.AuthServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("AuthService 单元测试")
class AuthServiceTest {

    @Mock private UserMapper userMapper;
    @Mock private RoleMapper roleMapper;
    @Mock private PermissionMapper permissionMapper;
    @Mock private JwtTokenProvider jwtTokenProvider;
    @Mock private PasswordEncoder passwordEncoder;

    @InjectMocks
    private AuthServiceImpl authService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("admin");
        testUser.setPassword("$2a$10$encoded_password");
        testUser.setRealName("管理员");
        testUser.setEmail("admin@seatflow.edu");
        testUser.setUserType("ADMIN");
    }

    @Test
    @DisplayName("should return token when login with correct credentials")
    void shouldReturnToken_whenLoginWithCorrectCredentials() {
        // Arrange
        when(userMapper.selectOne(any())).thenReturn(testUser);
        when(passwordEncoder.matches("admin123", testUser.getPassword())).thenReturn(true);
        when(roleMapper.selectByUserId(1L)).thenReturn(List.of(role(1L, "super_admin", "超级管理员")));
        when(permissionMapper.selectByUserId(1L)).thenReturn(List.of(permission(8L, "user:manage", "用户角色分配")));
        when(jwtTokenProvider.generateToken(1L, "admin", List.of("super_admin"), List.of("user:manage")))
                .thenReturn("jwt-token-xxx");
        when(jwtTokenProvider.getExpirationMs()).thenReturn(86400000L);

        LoginRequest request = new LoginRequest();
        request.setUsername("admin");
        request.setPassword("admin123");

        // Act
        var result = authService.login(request);

        // Assert
        assertNotNull(result);
        assertEquals("jwt-token-xxx", result.getToken());
        assertEquals(86400000L, result.getExpiresIn());
        assertEquals(List.of("super_admin"), result.getUserInfo().getRoles());
        assertEquals(List.of("user:manage"), result.getUserInfo().getPermissions());
    }

    @Test
    @DisplayName("should throw 401 when login with wrong password")
    void shouldThrow401_whenLoginWithWrongPassword() {
        when(userMapper.selectOne(any())).thenReturn(testUser);
        when(passwordEncoder.matches("wrongpwd", testUser.getPassword())).thenReturn(false);

        LoginRequest request = new LoginRequest();
        request.setUsername("admin");
        request.setPassword("wrongpwd");

        var ex = assertThrows(com.seatflow.common.exception.BusinessException.class,
                () -> authService.login(request));
        assertEquals(401, ex.getCode());
    }

    @Test
    @DisplayName("should throw 401 when login with non-existent username")
    void shouldThrow401_whenLoginWithNonExistentUsername() {
        when(userMapper.selectOne(any())).thenReturn(null);

        LoginRequest request = new LoginRequest();
        request.setUsername("nouser");
        request.setPassword("anypwd");

        var ex = assertThrows(com.seatflow.common.exception.BusinessException.class,
                () -> authService.login(request));
        assertEquals(401, ex.getCode());
    }

    private Role role(Long id, String code, String name) {
        Role role = new Role();
        role.setId(id);
        role.setCode(code);
        role.setName(name);
        return role;
    }

    private Permission permission(Long id, String code, String name) {
        Permission permission = new Permission();
        permission.setId(id);
        permission.setCode(code);
        permission.setName(name);
        return permission;
    }
}
