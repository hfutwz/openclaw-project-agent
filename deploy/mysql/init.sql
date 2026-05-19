-- SeatFlow 数据库初始化脚本
-- 由 schema.sql + data.sql 合并生成

CREATE DATABASE IF NOT EXISTS seatflow DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE seatflow;

GRANT ALL PRIVILEGES ON seatflow.* TO 'root'@'%';
FLUSH PRIVILEGES;

-- ========== 建表 ==========

-- SeatFlow Database Schema
-- Charset: utf8mb4, Collation: utf8mb4_unicode_ci
-- No foreign keys - all constraints enforced at business layer


-- 1. 院系表
CREATE TABLE IF NOT EXISTS t_department (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    deleted TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 用户表
CREATE TABLE IF NOT EXISTS t_user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    real_name VARCHAR(50),
    email VARCHAR(100),
    department_id BIGINT,
    user_type VARCHAR(20) NOT NULL DEFAULT 'STUDENT',
    deleted TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 自习室表
CREATE TABLE IF NOT EXISTS t_room (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(200),
    department_id BIGINT,
    open_time TIME NOT NULL DEFAULT '07:00:00',
    close_time TIME NOT NULL DEFAULT '22:00:00',
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    deleted TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 座位表
CREATE TABLE IF NOT EXISTS t_seat (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_id BIGINT NOT NULL,
    seat_number VARCHAR(20) NOT NULL,
    row_num INT NOT NULL,
    col_num INT NOT NULL,
    socket_type VARCHAR(20) NOT NULL DEFAULT 'NONE',
    position VARCHAR(20) NOT NULL DEFAULT 'MIDDLE',
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    deleted TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_room_seat (room_id, seat_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 预约表
CREATE TABLE IF NOT EXISTS t_reservation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    room_id BIGINT NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    cancelled_by VARCHAR(20),
    created_by VARCHAR(20) DEFAULT 'STUDENT' COMMENT '创建者: STUDENT/ADMIN',
    reminded_before TINYINT NOT NULL DEFAULT 0,
    warned_late TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_seat_date (seat_id, date, start_time, end_time),
    INDEX idx_user_date (user_id, date, start_time),
    INDEX idx_status_date (status, date, start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. 签到编码表
CREATE TABLE IF NOT EXISTS t_check_in_code (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_id BIGINT NOT NULL,
    code_date DATE NOT NULL,
    code VARCHAR(10) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_room_date (room_id, code_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. 违约表
CREATE TABLE IF NOT EXISTS t_violation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    reservation_id BIGINT NOT NULL,
    type VARCHAR(30) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. 角色表
CREATE TABLE IF NOT EXISTS t_role (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    deleted TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_name (name),
    UNIQUE KEY uk_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. 权限表
CREATE TABLE IF NOT EXISTS t_permission (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. 用户-角色关联表
CREATE TABLE IF NOT EXISTS t_user_role (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_role (user_id, role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. 角色-权限关联表
CREATE TABLE IF NOT EXISTS t_role_permission (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_role_perm (role_id, permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. 系统参数表
CREATE TABLE IF NOT EXISTS t_system_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL,
    config_value VARCHAR(200) NOT NULL,
    description VARCHAR(200),
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========== 初始数据 ==========

-- SeatFlow Seed Data
-- Password: admin123 (BCrypt hash)
-- NOTE: Run this after schema.sql

-- Departments
INSERT INTO t_department (id, name) VALUES (1, '计算机学院');
INSERT INTO t_department (id, name) VALUES (2, '电子工程学院');

-- Users (password = admin123 / student123, BCrypt hash)
INSERT INTO t_user (id, username, password, real_name, email, department_id, user_type) VALUES
(1, 'admin', '$2a$10$XiJZwcfX1LTFisLwC3LtD.vu9Q745J1dgom5nkR8CR3RQsKbUEUFK', '系统管理员', 'admin@seatflow.edu', NULL, 'ADMIN'),
(2, 'student1', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '张三', 'zhangsan@seatflow.edu', 1, 'STUDENT'),
(3, 'student2', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '李四', 'lisi@seatflow.edu', 2, 'STUDENT');

-- Roles
INSERT INTO t_role (id, name, code, description) VALUES
(1, '超级管理员', 'super_admin', '拥有全部权限'),
(2, '自习室管理员', 'room_admin', '管理自习室和座位'),
(3, '服务管理员', 'service_admin', '查看预约/违约记录，代客预约'),
(4, '只读用户', 'viewer', '仅查看预约/违约记录');

-- Permissions
INSERT INTO t_permission (id, name, code) VALUES
(1, '查看预约记录', 'reservation:view'),
(2, '查看违约记录', 'violation:view'),
(3, '代客预约和取消', 'reservation:manage'),
(4, '座位登记和注销', 'seat:manage'),
(5, '自习室登记和注销', 'room:manage'),
(6, '调整系统参数', 'system:config'),
(7, '角色和权限管理', 'role:manage'),
(8, '用户角色分配', 'user:manage');

-- Role-Permission mapping
-- super_admin: all permissions
INSERT INTO t_role_permission (role_id, permission_id) VALUES
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),(1,8);
-- room_admin: reservation:view, violation:view, seat:manage, room:manage
INSERT INTO t_role_permission (role_id, permission_id) VALUES
(2,1),(2,2),(2,4),(2,5);
-- service_admin: reservation:view, violation:view, reservation:manage
INSERT INTO t_role_permission (role_id, permission_id) VALUES
(3,1),(3,2),(3,3);
-- viewer: reservation:view, violation:view
INSERT INTO t_role_permission (role_id, permission_id) VALUES
(4,1),(4,2);

-- User-Role mapping
-- admin -> super_admin
INSERT INTO t_user_role (user_id, role_id) VALUES (1, 1);

-- System config
INSERT INTO t_system_config (config_key, config_value, description) VALUES
('max_reservation_hours', '4', '单次最大预约小时数'),
('check_in_remind_before_min', '15', '签到提前提醒（分钟）'),
('check_in_warn_after_min', '10', '签到逾期警告（分钟）'),
('check_in_cancel_after_min', '15', '签到逾期取消（分钟）');

-- Rooms
INSERT INTO t_room (id, name, location, department_id, open_time, close_time, status) VALUES
(1, '图书馆301', '图书馆3楼东侧', NULL, '07:00:00', '22:00:00', 'OPEN'),
(2, '计算机学院机房', '计算机楼B201', 1, '08:00:00', '21:00:00', 'OPEN');

-- Seats for Room 1 (图书馆301) - 4x5 grid
INSERT INTO t_seat (room_id, seat_number, row_num, col_num, socket_type, position, status) VALUES
(1, 'A1', 1, 1, 'NONE', 'WINDOW', 'AVAILABLE'),
(1, 'A2', 1, 2, 'NONE', 'MIDDLE', 'AVAILABLE'),
(1, 'A3', 1, 3, 'FIXED', 'MIDDLE', 'AVAILABLE'),
(1, 'A4', 1, 4, 'FIXED', 'MIDDLE', 'AVAILABLE'),
(1, 'A5', 1, 5, 'NONE', 'CORRIDOR', 'AVAILABLE'),
(1, 'B1', 2, 1, 'NONE', 'WINDOW', 'AVAILABLE'),
(1, 'B2', 2, 2, 'TRACK', 'MIDDLE', 'AVAILABLE'),
(1, 'B3', 2, 3, 'TRACK', 'MIDDLE', 'AVAILABLE'),
(1, 'B4', 2, 4, 'NONE', 'MIDDLE', 'AVAILABLE'),
(1, 'B5', 2, 5, 'NONE', 'CORRIDOR', 'AVAILABLE'),
(1, 'C1', 3, 1, 'FIXED', 'WINDOW', 'AVAILABLE'),
(1, 'C2', 3, 2, 'NONE', 'MIDDLE', 'AVAILABLE'),
(1, 'C3', 3, 3, 'NONE', 'MIDDLE', 'DISABLED'),
(1, 'C4', 3, 4, 'TRACK', 'MIDDLE', 'AVAILABLE'),
(1, 'C5', 3, 5, 'FIXED', 'CORRIDOR', 'AVAILABLE'),
(1, 'D1', 4, 1, 'NONE', 'WINDOW', 'AVAILABLE'),
(1, 'D2', 4, 2, 'FIXED', 'MIDDLE', 'AVAILABLE'),
(1, 'D3', 4, 3, 'NONE', 'MIDDLE', 'AVAILABLE'),
(1, 'D4', 4, 4, 'NONE', 'MIDDLE', 'AVAILABLE'),
(1, 'D5', 4, 5, 'NONE', 'CORRIDOR', 'AVAILABLE');

-- Seats for Room 2 (计算机学院机房) - 3x4 grid
INSERT INTO t_seat (room_id, seat_number, row_num, col_num, socket_type, position, status) VALUES
(2, 'A1', 1, 1, 'FIXED', 'WINDOW', 'AVAILABLE'),
(2, 'A2', 1, 2, 'FIXED', 'MIDDLE', 'AVAILABLE'),
(2, 'A3', 1, 3, 'FIXED', 'MIDDLE', 'AVAILABLE'),
(2, 'A4', 1, 4, 'FIXED', 'CORRIDOR', 'AVAILABLE'),
(2, 'B1', 2, 1, 'TRACK', 'WINDOW', 'AVAILABLE'),
(2, 'B2', 2, 2, 'TRACK', 'MIDDLE', 'AVAILABLE'),
(2, 'B3', 2, 3, 'TRACK', 'MIDDLE', 'AVAILABLE'),
(2, 'B4', 2, 4, 'TRACK', 'CORRIDOR', 'AVAILABLE'),
(2, 'C1', 3, 1, 'FIXED', 'WINDOW', 'AVAILABLE'),
(2, 'C2', 3, 2, 'FIXED', 'MIDDLE', 'AVAILABLE'),
(2, 'C3', 3, 3, 'FIXED', 'MIDDLE', 'AVAILABLE'),
(2, 'C4', 3, 4, 'FIXED', 'CORRIDOR', 'AVAILABLE');

-- 补充 created_by 字段
ALTER TABLE t_reservation ADD COLUMN IF NOT EXISTS created_by VARCHAR(20) DEFAULT 'STUDENT' COMMENT '创建者: STUDENT/ADMIN';
