-- SeatFlow 种子数据脚本
-- 版本：v2.0（任务A扩充）
-- 日期：2026-06-19
-- 说明：合并组员B的RBAC数据 + 组员A扩充的院系/自习室/座位数据
-- 使用 INSERT IGNORE 保证幂等，可重复执行

USE `seatflow`;

-- ========== 1. 系统参数 ==========
INSERT IGNORE INTO `t_system_config` (`config_key`, `config_value`, `description`) VALUES
('max_reservation_hours',     '4',  '单次最大预约小时数'),
('check_in_remind_before_min','15', '签到提前提醒（分钟）'),
('check_in_warn_after_min',   '10', '签到逾期警告（分钟）'),
('check_in_cancel_after_min', '15', '签到逾期取消（分钟）');

-- ========== 2. 权限 ==========
INSERT IGNORE INTO `t_permission` (`name`, `code`) VALUES
('查看预约记录',       'reservation:view'),
('查看违约记录',       'violation:view'),
('为用户预约和取消预约','reservation:manage'),
('座位登记和注销',     'seat:manage'),
('自习室登记和注销',   'room:manage'),
('调整系统参数',       'system:config'),
('角色和权限管理',     'role:manage'),
('用户角色分配',       'user:manage');

-- ========== 3. 角色 ==========
INSERT IGNORE INTO `t_role` (`name`, `code`, `description`) VALUES
('超级管理员',   'super_admin',   '拥有所有权限，系统最高管理者'),
('自习室管理员', 'room_admin',    '管理自习室和座位，查看预约记录'),
('服务管理员',   'service_admin', '查看预约和违约记录，代客预约/取消'),
('查看员',       'viewer',        '仅查看预约和违约记录'),
('学生',         'student',       '普通学生，无管理端权限');

-- ========== 4. 角色-权限映射 ==========
-- super_admin：所有权限
INSERT IGNORE INTO `t_role_permission` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `t_role` r, `t_permission` p WHERE r.code = 'super_admin';

-- room_admin：自习室/座位管理 + 查看预约
INSERT IGNORE INTO `t_role_permission` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `t_role` r, `t_permission` p
WHERE r.code = 'room_admin' AND p.code IN ('room:manage', 'seat:manage', 'reservation:view');

-- service_admin：查看预约/违约 + 代客预约
INSERT IGNORE INTO `t_role_permission` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `t_role` r, `t_permission` p
WHERE r.code = 'service_admin' AND p.code IN ('reservation:view', 'violation:view', 'reservation:manage');

-- viewer：仅查看预约/违约
INSERT IGNORE INTO `t_role_permission` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `t_role` r, `t_permission` p
WHERE r.code = 'viewer' AND p.code IN ('reservation:view', 'violation:view');

-- ========== 5. 院系 ==========
INSERT IGNORE INTO `t_department` (`id`, `name`) VALUES
(1, '计算机科学与工程学院'),
(2, '电子信息工程学院'),
(3, '机械与汽车工程学院'),
(4, '经济管理学院'),
(5, '外国语学院');

-- ========== 6. 用户 ==========
-- admin123 密码：$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iK6roS6zM59ycVcFQ4eFZ8B5WQ1a
-- student123 密码：$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G
INSERT IGNORE INTO `t_user` (`id`, `username`, `password`, `real_name`, `email`, `department_id`, `user_type`) VALUES
(1, 'admin',    '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iK6roS6zM59ycVcFQ4eFZ8B5WQ1a', '系统管理员', 'admin@seatflow.com',    NULL, 'ADMIN'),
(2, 'student1', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '张三',     'zhangsan@seatflow.edu', 1,    'STUDENT'),
(3, 'student2', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '李四',     'lisi@seatflow.edu',     2,    'STUDENT'),
(4, 'student3', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '王五',     'wangwu@seatflow.edu',   3,    'STUDENT'),
(5, 'student4', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '赵六',     'zhaoliu@seatflow.edu',  4,    'STUDENT'),
(6, 'student5', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '钱七',     'qianqi@seatflow.edu',   5,    'STUDENT');

-- ========== 7. 用户-角色映射 ==========
INSERT IGNORE INTO `t_user_role` (`user_id`, `role_id`)
SELECT u.id, r.id FROM `t_user` u, `t_role` r
WHERE u.username = 'admin' AND r.code = 'super_admin';

INSERT IGNORE INTO `t_user_role` (`user_id`, `role_id`)
SELECT u.id, r.id FROM `t_user` u, `t_role` r
WHERE u.username IN ('student1','student2','student3','student4','student5') AND r.code = 'student';

-- ========== 8. 自习室 ==========
INSERT IGNORE INTO `t_room` (`id`, `name`, `location`, `department_id`, `open_time`, `close_time`, `status`) VALUES
(1, '图书馆自习室A',     '图书馆3楼东侧',   NULL, '07:00:00', '22:00:00', 'OPEN'),
(2, '图书馆自习室B',     '图书馆3楼西侧',   NULL, '07:00:00', '22:00:00', 'OPEN'),
(3, '计算机学院机房101', '计算机楼B201',    1,    '08:00:00', '21:00:00', 'OPEN'),
(4, '电子工程实验室',    '电子楼C301',      2,    '08:00:00', '21:00:00', 'OPEN'),
(5, '经管院研讨室',      '经管楼D102',      4,    '09:00:00', '20:00:00', 'OPEN'),
(6, '综合楼通宵自习室',  '综合楼1楼大厅',   NULL, '00:00:00', '23:59:00', 'OPEN');

-- ========== 9. 座位 ==========

-- Room 1（图书馆自习室A）5×6 = 30座
INSERT IGNORE INTO `t_seat` (`room_id`, `seat_number`, `row_num`, `col_num`, `socket_type`, `position`, `status`) VALUES
(1,'A1',1,1,'NONE','WINDOW','AVAILABLE'),(1,'A2',1,2,'FIXED','WINDOW','AVAILABLE'),
(1,'A3',1,3,'FIXED','WINDOW','AVAILABLE'),(1,'A4',1,4,'NONE','WINDOW','AVAILABLE'),
(1,'A5',1,5,'TRACK','WINDOW','AVAILABLE'),(1,'A6',1,6,'NONE','WINDOW','AVAILABLE'),
(1,'B1',2,1,'NONE','CORRIDOR','AVAILABLE'),(1,'B2',2,2,'NONE','MIDDLE','AVAILABLE'),
(1,'B3',2,3,'FIXED','MIDDLE','AVAILABLE'),(1,'B4',2,4,'FIXED','MIDDLE','AVAILABLE'),
(1,'B5',2,5,'NONE','MIDDLE','AVAILABLE'),(1,'B6',2,6,'NONE','CORRIDOR','AVAILABLE'),
(1,'C1',3,1,'NONE','CORRIDOR','AVAILABLE'),(1,'C2',3,2,'TRACK','MIDDLE','AVAILABLE'),
(1,'C3',3,3,'TRACK','MIDDLE','AVAILABLE'),(1,'C4',3,4,'NONE','MIDDLE','DISABLED'),
(1,'C5',3,5,'FIXED','MIDDLE','AVAILABLE'),(1,'C6',3,6,'NONE','CORRIDOR','AVAILABLE'),
(1,'D1',4,1,'NONE','CORRIDOR','AVAILABLE'),(1,'D2',4,2,'NONE','MIDDLE','AVAILABLE'),
(1,'D3',4,3,'FIXED','MIDDLE','AVAILABLE'),(1,'D4',4,4,'FIXED','MIDDLE','AVAILABLE'),
(1,'D5',4,5,'NONE','MIDDLE','AVAILABLE'),(1,'D6',4,6,'TRACK','CORRIDOR','AVAILABLE'),
(1,'E1',5,1,'NONE','CORRIDOR','AVAILABLE'),(1,'E2',5,2,'FIXED','CORRIDOR','AVAILABLE'),
(1,'E3',5,3,'NONE','CORRIDOR','AVAILABLE'),(1,'E4',5,4,'TRACK','CORRIDOR','DISABLED'),
(1,'E5',5,5,'NONE','CORRIDOR','AVAILABLE'),(1,'E6',5,6,'FIXED','CORRIDOR','AVAILABLE');

-- Room 2（图书馆自习室B）4×5 = 20座
INSERT IGNORE INTO `t_seat` (`room_id`, `seat_number`, `row_num`, `col_num`, `socket_type`, `position`, `status`) VALUES
(2,'A1',1,1,'FIXED','WINDOW','AVAILABLE'),(2,'A2',1,2,'FIXED','WINDOW','AVAILABLE'),
(2,'A3',1,3,'NONE','WINDOW','AVAILABLE'),(2,'A4',1,4,'NONE','WINDOW','AVAILABLE'),
(2,'A5',1,5,'TRACK','WINDOW','AVAILABLE'),
(2,'B1',2,1,'NONE','CORRIDOR','AVAILABLE'),(2,'B2',2,2,'FIXED','MIDDLE','AVAILABLE'),
(2,'B3',2,3,'NONE','MIDDLE','AVAILABLE'),(2,'B4',2,4,'FIXED','MIDDLE','AVAILABLE'),
(2,'B5',2,5,'NONE','CORRIDOR','AVAILABLE'),
(2,'C1',3,1,'TRACK','CORRIDOR','AVAILABLE'),(2,'C2',3,2,'NONE','MIDDLE','AVAILABLE'),
(2,'C3',3,3,'FIXED','MIDDLE','DISABLED'),(2,'C4',3,4,'NONE','MIDDLE','AVAILABLE'),
(2,'C5',3,5,'NONE','CORRIDOR','AVAILABLE'),
(2,'D1',4,1,'NONE','CORRIDOR','AVAILABLE'),(2,'D2',4,2,'FIXED','CORRIDOR','AVAILABLE'),
(2,'D3',4,3,'FIXED','CORRIDOR','AVAILABLE'),(2,'D4',4,4,'NONE','CORRIDOR','AVAILABLE'),
(2,'D5',4,5,'TRACK','CORRIDOR','AVAILABLE');

-- Room 3（计算机学院机房101）3×6 = 18座
INSERT IGNORE INTO `t_seat` (`room_id`, `seat_number`, `row_num`, `col_num`, `socket_type`, `position`, `status`) VALUES
(3,'A1',1,1,'FIXED','WINDOW','AVAILABLE'),(3,'A2',1,2,'FIXED','MIDDLE','AVAILABLE'),
(3,'A3',1,3,'FIXED','MIDDLE','AVAILABLE'),(3,'A4',1,4,'FIXED','MIDDLE','AVAILABLE'),
(3,'A5',1,5,'FIXED','MIDDLE','AVAILABLE'),(3,'A6',1,6,'FIXED','CORRIDOR','AVAILABLE'),
(3,'B1',2,1,'FIXED','WINDOW','AVAILABLE'),(3,'B2',2,2,'FIXED','MIDDLE','AVAILABLE'),
(3,'B3',2,3,'FIXED','MIDDLE','AVAILABLE'),(3,'B4',2,4,'FIXED','MIDDLE','DISABLED'),
(3,'B5',2,5,'FIXED','MIDDLE','AVAILABLE'),(3,'B6',2,6,'FIXED','CORRIDOR','AVAILABLE'),
(3,'C1',3,1,'TRACK','WINDOW','AVAILABLE'),(3,'C2',3,2,'TRACK','MIDDLE','AVAILABLE'),
(3,'C3',3,3,'TRACK','MIDDLE','AVAILABLE'),(3,'C4',3,4,'TRACK','MIDDLE','AVAILABLE'),
(3,'C5',3,5,'TRACK','MIDDLE','AVAILABLE'),(3,'C6',3,6,'FIXED','CORRIDOR','AVAILABLE');

-- Room 4（电子工程实验室）3×5 = 15座
INSERT IGNORE INTO `t_seat` (`room_id`, `seat_number`, `row_num`, `col_num`, `socket_type`, `position`, `status`) VALUES
(4,'A1',1,1,'TRACK','WINDOW','AVAILABLE'),(4,'A2',1,2,'TRACK','WINDOW','AVAILABLE'),
(4,'A3',1,3,'FIXED','WINDOW','AVAILABLE'),(4,'A4',1,4,'NONE','WINDOW','AVAILABLE'),
(4,'A5',1,5,'NONE','WINDOW','AVAILABLE'),
(4,'B1',2,1,'NONE','CORRIDOR','AVAILABLE'),(4,'B2',2,2,'FIXED','MIDDLE','AVAILABLE'),
(4,'B3',2,3,'FIXED','MIDDLE','AVAILABLE'),(4,'B4',2,4,'NONE','MIDDLE','AVAILABLE'),
(4,'B5',2,5,'NONE','CORRIDOR','AVAILABLE'),
(4,'C1',3,1,'NONE','CORRIDOR','AVAILABLE'),(4,'C2',3,2,'FIXED','CORRIDOR','AVAILABLE'),
(4,'C3',3,3,'NONE','CORRIDOR','DISABLED'),(4,'C4',3,4,'FIXED','CORRIDOR','AVAILABLE'),
(4,'C5',3,5,'NONE','CORRIDOR','AVAILABLE');

-- Room 5（经管院研讨室）2×5 = 10座
INSERT IGNORE INTO `t_seat` (`room_id`, `seat_number`, `row_num`, `col_num`, `socket_type`, `position`, `status`) VALUES
(5,'A1',1,1,'FIXED','WINDOW','AVAILABLE'),(5,'A2',1,2,'FIXED','WINDOW','AVAILABLE'),
(5,'A3',1,3,'NONE','WINDOW','AVAILABLE'),(5,'A4',1,4,'FIXED','WINDOW','AVAILABLE'),
(5,'A5',1,5,'NONE','WINDOW','AVAILABLE'),
(5,'B1',2,1,'NONE','CORRIDOR','AVAILABLE'),(5,'B2',2,2,'FIXED','MIDDLE','AVAILABLE'),
(5,'B3',2,3,'FIXED','MIDDLE','AVAILABLE'),(5,'B4',2,4,'NONE','MIDDLE','AVAILABLE'),
(5,'B5',2,5,'NONE','CORRIDOR','AVAILABLE');

-- Room 6（综合楼通宵自习室）4×6 = 24座
INSERT IGNORE INTO `t_seat` (`room_id`, `seat_number`, `row_num`, `col_num`, `socket_type`, `position`, `status`) VALUES
(6,'A1',1,1,'FIXED','WINDOW','AVAILABLE'),(6,'A2',1,2,'TRACK','WINDOW','AVAILABLE'),
(6,'A3',1,3,'NONE','WINDOW','AVAILABLE'),(6,'A4',1,4,'NONE','WINDOW','AVAILABLE'),
(6,'A5',1,5,'FIXED','WINDOW','AVAILABLE'),(6,'A6',1,6,'TRACK','WINDOW','AVAILABLE'),
(6,'B1',2,1,'NONE','CORRIDOR','AVAILABLE'),(6,'B2',2,2,'FIXED','MIDDLE','AVAILABLE'),
(6,'B3',2,3,'TRACK','MIDDLE','AVAILABLE'),(6,'B4',2,4,'FIXED','MIDDLE','AVAILABLE'),
(6,'B5',2,5,'NONE','MIDDLE','AVAILABLE'),(6,'B6',2,6,'NONE','CORRIDOR','AVAILABLE'),
(6,'C1',3,1,'FIXED','CORRIDOR','AVAILABLE'),(6,'C2',3,2,'NONE','MIDDLE','AVAILABLE'),
(6,'C3',3,3,'FIXED','MIDDLE','AVAILABLE'),(6,'C4',3,4,'NONE','MIDDLE','AVAILABLE'),
(6,'C5',3,5,'TRACK','MIDDLE','AVAILABLE'),(6,'C6',3,6,'FIXED','CORRIDOR','AVAILABLE'),
(6,'D1',4,1,'NONE','CORRIDOR','AVAILABLE'),(6,'D2',4,2,'FIXED','CORRIDOR','AVAILABLE'),
(6,'D3',4,3,'TRACK','CORRIDOR','AVAILABLE'),(6,'D4',4,4,'FIXED','CORRIDOR','AVAILABLE'),
(6,'D5',4,5,'NONE','CORRIDOR','AVAILABLE'),(6,'D6',4,6,'FIXED','CORRIDOR','AVAILABLE');

-- ========== 10. 今日签到码 ==========
INSERT IGNORE INTO `t_check_in_code` (`room_id`, `code_date`, `code`) VALUES
(1, CURDATE(), 'A1B2C3'),
(2, CURDATE(), 'D4E5F6'),
(3, CURDATE(), 'G7H8I9'),
(4, CURDATE(), 'J0K1L2'),
(5, CURDATE(), 'M3N4O5'),
(6, CURDATE(), 'P6Q7R8');
