-- SeatFlow 数据库初始化脚本
-- 由 schema.sql + data.sql 合并生成

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

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

-- ========== 初始数据 ==========
-- 版本：v2.0（对齐 data.sql，含完整示例数据）

-- 1. 院系（6个）
INSERT IGNORE INTO t_department (name) VALUES
('计算机科学与工程学院'),
('电子信息工程学院'),
('机械与汽车工程学院'),
('经济管理学院'),
('理学院'),
('人文与社会科学学院');

-- 2. 系统参数
INSERT IGNORE INTO t_system_config (config_key, config_value, description) VALUES
('max_reservation_hours', '4', '单次最大预约小时数'),
('check_in_remind_before_min', '15', '签到提前提醒（分钟）'),
('check_in_warn_after_min', '10', '签到逾期警告（分钟）'),
('check_in_cancel_after_min', '15', '签到逾期取消（分钟）');

-- 3. 权限
INSERT IGNORE INTO t_permission (name, code) VALUES
('查看预约记录', 'reservation:view'),
('查看违约记录', 'violation:view'),
('为用户预约和取消预约', 'reservation:manage'),
('座位登记和注销', 'seat:manage'),
('自习室登记和注销', 'room:manage'),
('调整系统参数', 'system:config'),
('角色和权限管理', 'role:manage'),
('用户角色分配', 'user:manage');

-- 4. 角色
INSERT IGNORE INTO t_role (name, code, description) VALUES
('超级管理员', 'super_admin', '拥有所有权限，系统最高管理者'),
('自习室管理员', 'room_admin', '管理自习室和座位，查看预约记录'),
('服务管理员', 'service_admin', '查看预约和违约记录，代客预约/取消'),
('查看员', 'viewer', '仅查看预约和违约记录');

-- 5. 角色-权限映射（通过 code 关联，避免依赖自增 id）
-- super_admin: 所有权限
INSERT IGNORE INTO t_role_permission (role_id, permission_id)
SELECT r.id, p.id FROM t_role r, t_permission p WHERE r.code = 'super_admin';

-- room_admin: 自习室/座位管理 + 查看预约/违约
INSERT IGNORE INTO t_role_permission (role_id, permission_id)
SELECT r.id, p.id FROM t_role r, t_permission p
WHERE r.code = 'room_admin' AND p.code IN ('room:manage', 'seat:manage', 'reservation:view', 'violation:view');

-- service_admin: 查看预约/违约 + 代客预约
INSERT IGNORE INTO t_role_permission (role_id, permission_id)
SELECT r.id, p.id FROM t_role r, t_permission p
WHERE r.code = 'service_admin' AND p.code IN ('reservation:view', 'violation:view', 'reservation:manage');

-- viewer: 仅查看预约/违约
INSERT IGNORE INTO t_role_permission (role_id, permission_id)
SELECT r.id, p.id FROM t_role r, t_permission p
WHERE r.code = 'viewer' AND p.code IN ('reservation:view', 'violation:view');

-- 6. 用户（admin/admin123，student1~2/student123）
INSERT IGNORE INTO t_user (username, password, real_name, email, department_id, user_type) VALUES
('admin', '$2a$10$XiJZwcfX1LTFisLwC3LtD.vu9Q745J1dgom5nkR8CR3RQsKbUEUFK', '系统管理员', 'admin@seatflow.edu', NULL, 'ADMIN'),
('student1', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '张三', 'zhangsan@seatflow.edu', 1, 'STUDENT'),
('student2', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '李四', 'lisi@seatflow.edu', 2, 'STUDENT');

-- 7. 用户-角色映射
INSERT IGNORE INTO t_user_role (user_id, role_id)
SELECT u.id, r.id FROM t_user u, t_role r WHERE u.username = 'admin' AND r.code = 'super_admin';

-- 8. 自习室（4个）
INSERT IGNORE INTO t_room (name, location, department_id, open_time, close_time, status) VALUES
('图书馆301', '图书馆三楼东侧', NULL, '07:00:00', '22:00:00', 'OPEN'),
('图书馆302', '图书馆三楼西侧', NULL, '07:00:00', '22:00:00', 'OPEN'),
('计算机学院实验室', '计算机学院楼301', 1, '08:00:00', '21:00:00', 'OPEN'),
('电子学院自习室', '电子学院楼201', 2, '08:00:00', '21:00:00', 'OPEN');

-- 9. 座位（图书馆301 - 5行6列 = 30座）
INSERT IGNORE INTO t_seat (room_id, seat_number, row_num, col_num, socket_type, position, status)
SELECT r.id, s.seat_number, s.row_num, s.col_num, s.socket_type, s.position, s.status
FROM t_room r,
(SELECT 'A01' seat_number, 1 row_num, 1 col_num, 'FIXED'  socket_type, 'WINDOW'   position, 'AVAILABLE' status UNION ALL
 SELECT 'A02', 1, 2, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A03', 1, 3, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A04', 1, 4, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A05', 1, 5, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A06', 1, 6, 'NONE',  'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'B01', 2, 1, 'FIXED', 'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'B02', 2, 2, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B03', 2, 3, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B04', 2, 4, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B05', 2, 5, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B06', 2, 6, 'NONE',  'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'C01', 3, 1, 'FIXED', 'WINDOW',   'DISABLED'  UNION ALL
 SELECT 'C02', 3, 2, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C03', 3, 3, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C04', 3, 4, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C05', 3, 5, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C06', 3, 6, 'NONE',  'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'D01', 4, 1, 'FIXED', 'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'D02', 4, 2, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'D03', 4, 3, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'D04', 4, 4, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'D05', 4, 5, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'D06', 4, 6, 'NONE',  'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'E01', 5, 1, 'FIXED', 'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'E02', 5, 2, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'E03', 5, 3, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'E04', 5, 4, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'E05', 5, 5, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'E06', 5, 6, 'NONE',  'CORRIDOR', 'AVAILABLE') s
WHERE r.name = '图书馆301';

-- 座位（图书馆302 - 4行5列 = 20座）
INSERT IGNORE INTO t_seat (room_id, seat_number, row_num, col_num, socket_type, position, status)
SELECT r.id, s.seat_number, s.row_num, s.col_num, s.socket_type, s.position, s.status
FROM t_room r,
(SELECT 'A01' seat_number, 1 row_num, 1 col_num, 'NONE'  socket_type, 'WINDOW'   position, 'AVAILABLE' status UNION ALL
 SELECT 'A02', 1, 2, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A03', 1, 3, 'FIXED', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A04', 1, 4, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A05', 1, 5, 'NONE',  'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'B01', 2, 1, 'NONE',  'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'B02', 2, 2, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B03', 2, 3, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B04', 2, 4, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B05', 2, 5, 'NONE',  'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'C01', 3, 1, 'FIXED', 'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'C02', 3, 2, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C03', 3, 3, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C04', 3, 4, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C05', 3, 5, 'FIXED', 'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'D01', 4, 1, 'NONE',  'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'D02', 4, 2, 'FIXED', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'D03', 4, 3, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'D04', 4, 4, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'D05', 4, 5, 'NONE',  'CORRIDOR', 'AVAILABLE')) s
WHERE r.name = '图书馆302';

-- 座位（计算机学院实验室 - 3行4列 = 12座）
INSERT IGNORE INTO t_seat (room_id, seat_number, row_num, col_num, socket_type, position, status)
SELECT r.id, s.seat_number, s.row_num, s.col_num, s.socket_type, s.position, s.status
FROM t_room r,
(SELECT 'A01' seat_number, 1 row_num, 1 col_num, 'FIXED' socket_type, 'WINDOW'   position, 'AVAILABLE' status UNION ALL
 SELECT 'A02', 1, 2, 'FIXED', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A03', 1, 3, 'FIXED', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A04', 1, 4, 'FIXED', 'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'B01', 2, 1, 'TRACK', 'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'B02', 2, 2, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B03', 2, 3, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B04', 2, 4, 'TRACK', 'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'C01', 3, 1, 'FIXED', 'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'C02', 3, 2, 'FIXED', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C03', 3, 3, 'FIXED', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C04', 3, 4, 'FIXED', 'CORRIDOR', 'AVAILABLE')) s
WHERE r.name = '计算机学院实验室';

-- 座位（电子学院自习室 - 3行4列 = 12座）
INSERT IGNORE INTO t_seat (room_id, seat_number, row_num, col_num, socket_type, position, status)
SELECT r.id, s.seat_number, s.row_num, s.col_num, s.socket_type, s.position, s.status
FROM t_room r,
(SELECT 'A01' seat_number, 1 row_num, 1 col_num, 'NONE'  socket_type, 'WINDOW'   position, 'AVAILABLE' status UNION ALL
 SELECT 'A02', 1, 2, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A03', 1, 3, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'A04', 1, 4, 'NONE',  'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'B01', 2, 1, 'NONE',  'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'B02', 2, 2, 'FIXED', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B03', 2, 3, 'FIXED', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'B04', 2, 4, 'NONE',  'CORRIDOR', 'AVAILABLE' UNION ALL
 SELECT 'C01', 3, 1, 'NONE',  'WINDOW',   'AVAILABLE' UNION ALL
 SELECT 'C02', 3, 2, 'TRACK', 'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C03', 3, 3, 'NONE',  'MIDDLE',   'AVAILABLE' UNION ALL
 SELECT 'C04', 3, 4, 'NONE',  'CORRIDOR', 'AVAILABLE')) s
WHERE r.name = '电子学院自习室';

-- 10. 今日签到编码
INSERT IGNORE INTO t_check_in_code (room_id, code_date, code)
SELECT r.id, CURDATE(), codes.code
FROM t_room r
JOIN (SELECT '图书馆301' rname, 'A1B2C3' code UNION ALL
      SELECT '图书馆302', 'D4E5F6' UNION ALL
      SELECT '计算机学院实验室', 'G7H8I9' UNION ALL
      SELECT '电子学院自习室', 'J0K1L2') codes ON r.name = codes.rname;

-- 补充 created_by 字段（幂等）
ALTER TABLE t_reservation ADD COLUMN IF NOT EXISTS created_by VARCHAR(20) DEFAULT 'STUDENT' COMMENT '创建者: STUDENT/ADMIN';
