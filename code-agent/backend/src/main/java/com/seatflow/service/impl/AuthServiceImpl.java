package com.seatflow.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.seatflow.common.exception.BusinessException;
import com.seatflow.dto.request.LoginRequest;
import com.seatflow.dto.response.LoginResponse;
import com.seatflow.dto.response.UserInfoResponse;
import com.seatflow.entity.Permission;
import com.seatflow.entity.Role;
import com.seatflow.entity.User;
import com.seatflow.mapper.PermissionMapper;
import com.seatflow.mapper.RoleMapper;
import com.seatflow.mapper.UserMapper;
import com.seatflow.security.JwtTokenProvider;
import com.seatflow.security.SecurityUtils;
import com.seatflow.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserMapper userMapper;
    private final RoleMapper roleMapper;
    private final PermissionMapper permissionMapper;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;

    @Override
    public LoginResponse login(LoginRequest request) {
        User user = userMapper.selectOne(
                new LambdaQueryWrapper<User>()
                        .eq(User::getUsername, request.getUsername())
                        .eq(User::getDeleted, 0)
        );

        if (user == null) {
            throw new BusinessException(401, "用户名不存在");
        }
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BusinessException(401, "密码错误");
        }

        List<Role> roles = roleMapper.selectByUserId(user.getId());
        List<String> roleCodes = roles.stream().map(Role::getCode).collect(Collectors.toList());
        List<Permission> permissions = permissionMapper.selectByUserId(user.getId());

        // 生成 JWT Token
        String token = jwtTokenProvider.generateToken(user.getId(), user.getUsername(), roleCodes);

        UserInfoResponse userInfo = UserInfoResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .realName(user.getRealName())
                .email(user.getEmail())
                .departmentId(user.getDepartmentId())
                .userType(user.getUserType())
                .roles(roleCodes)
                .permissions(permissions.stream()
                        .map(Permission::getCode)
                        .distinct()
                        .collect(Collectors.toList()))
                .build();

        return LoginResponse.builder()
                .token(token)
                .expiresIn(jwtTokenProvider.getExpirationMs())
                .userInfo(userInfo)
                .build();
    }

    @Override
    public UserInfoResponse getCurrentUserInfo() {
        String username = SecurityUtils.getCurrentUsername();
        return getUserByUsername(username);
    }

    @Override
    public UserInfoResponse getCurrentUser(Long userId) {
        User user = userMapper.selectById(userId);

        List<Role> roles = roleMapper.selectByUserId(userId);
        List<Permission> permissions = permissionMapper.selectByUserId(userId);

        return UserInfoResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .realName(user.getRealName())
                .email(user.getEmail())
                .departmentId(user.getDepartmentId())
                .userType(user.getUserType())
                .roles(roles.stream().map(Role::getCode).collect(Collectors.toList()))
                .permissions(permissions.stream()
                        .map(Permission::getCode)
                        .distinct()
                        .collect(Collectors.toList()))
                .build();
    }

    /**
     * [SECURITY-DISABLED] 根据用户名获取用户信息
     */
    public UserInfoResponse getUserByUsername(String username) {
        User user = userMapper.selectOne(
                new LambdaQueryWrapper<User>()
                        .eq(User::getUsername, username)
                        .eq(User::getDeleted, 0)
        );

        List<Role> roles = roleMapper.selectByUserId(user.getId());
        List<Permission> permissions = permissionMapper.selectByUserId(user.getId());

        return UserInfoResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .realName(user.getRealName())
                .email(user.getEmail())
                .departmentId(user.getDepartmentId())
                .userType(user.getUserType())
                .roles(roles.stream().map(Role::getCode).collect(Collectors.toList()))
                .permissions(permissions.stream()
                        .map(Permission::getCode)
                        .distinct()
                        .collect(Collectors.toList()))
                .build();
    }
}
