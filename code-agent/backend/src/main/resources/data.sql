-- SeatFlow 种子数据脚本
-- 版本：v3.0（丰富座位布局）
-- 日期：2026-06-19
-- 说明：合并组员B RBAC + 组员A丰富座位数据
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
INSERT IGNORE INTO `t_role_permission` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `t_role` r, `t_permission` p WHERE r.code = 'super_admin';

INSERT IGNORE INTO `t_role_permission` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `t_role` r, `t_permission` p
WHERE r.code = 'room_admin' AND p.code IN ('room:manage', 'seat:manage', 'reservation:view');

INSERT IGNORE INTO `t_role_permission` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `t_role` r, `t_permission` p
WHERE r.code = 'service_admin' AND p.code IN ('reservation:view', 'violation:view', 'reservation:manage');

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
-- admin123 -> $2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iK6roS6zM59ycVcFQ4eFZ8B5WQ1a
-- student123 -> $2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G
INSERT IGNORE INTO `t_user` (`id`, `username`, `password`, `real_name`, `email`, `department_id`, `user_type`) VALUES
(1, 'admin',    '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iK6roS6zM59ycVcFQ4eFZ8B5WQ1a', '系统管理员', 'admin@seatflow.com',    NULL, 'ADMIN'),
(2, 'student1', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '张三',     'zhangsan@seatflow.edu', 1,    'STUDENT'),
(3, 'student2', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '李四',     'lisi@seatflow.edu',     2,    'STUDENT'),
(4, 'student3', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '王五',     'wangwu@seatflow.edu',   3,    'STUDENT'),
(5, 'student4', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '赵六',     'zhaoliu@seatflow.edu',  4,    'STUDENT'),
(6, 'student5', '$2a$10$r6lwVY8aIlDsahPHO7CC6OlU0MjkRbpK3dRwYB42czS2tAVaDD21G', '钱七',     'qianqi@seatflow.edu',   5,    'STUDENT');

-- ========== 7. 用户-角色映射 ==========
INSERT IGNORE INTO `t_user_role` (`user_id`, `role_id`)
SELECT u.id, r.id FROM `t_user` u, `t_role` r WHERE u.username = 'admin' AND r.code = 'super_admin';

INSERT IGNORE INTO `t_user_role` (`user_id`, `role_id`)
SELECT u.id, r.id FROM `t_user` u, `t_role` r
WHERE u.username IN ('student1','student2','student3','student4','student5') AND r.code = 'student';

-- ========== 8. 自习室 ==========
INSERT IGNORE INTO `t_room` (`id`, `name`, `location`, `department_id`, `open_time`, `close_time`, `status`) VALUES
(1, '图书馆301',       '图书馆3楼东侧',   NULL, '07:00:00', '22:00:00', 'OPEN'),
(2, '图书馆302',       '图书馆3楼西侧',   NULL, '07:00:00', '22:00:00', 'OPEN'),
(3, '计算机学院机房',   '计算机楼B201',   1,    '08:00:00', '21:00:00', 'OPEN'),
(4, '电子工程实验室',   '电子楼C301',     2,    '08:00:00', '21:00:00', 'OPEN'),
(5, '经管院自习室',     '经管楼D102',     4,    '09:00:00', '20:00:00', 'OPEN'),
(6, '综合楼通宵自习室', '综合楼1楼大厅',  NULL, '00:00:00', '23:59:00', 'OPEN');

-- ========== 9. 座位数据 ==========

-- -------------------------------------------------------
-- Room 1：图书馆301（方形 6×10 = 60座）
-- 布局：靠窗第1行，靠走廊第1/10列，中间混插座
-- -------------------------------------------------------
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
-- 行A（靠窗）
(1,'A01',1,1,'FIXED','WINDOW','AVAILABLE'),(1,'A02',1,2,'FIXED','WINDOW','AVAILABLE'),
(1,'A03',1,3,'TRACK','WINDOW','AVAILABLE'),(1,'A04',1,4,'NONE','WINDOW','AVAILABLE'),
(1,'A05',1,5,'NONE','WINDOW','AVAILABLE'),(1,'A06',1,6,'NONE','WINDOW','AVAILABLE'),
(1,'A07',1,7,'NONE','WINDOW','AVAILABLE'),(1,'A08',1,8,'TRACK','WINDOW','AVAILABLE'),
(1,'A09',1,9,'FIXED','WINDOW','AVAILABLE'),(1,'A10',1,10,'FIXED','WINDOW','AVAILABLE'),
-- 行B
(1,'B01',2,1,'NONE','CORRIDOR','AVAILABLE'),(1,'B02',2,2,'FIXED','MIDDLE','AVAILABLE'),
(1,'B03',2,3,'NONE','MIDDLE','AVAILABLE'),(1,'B04',2,4,'TRACK','MIDDLE','AVAILABLE'),
(1,'B05',2,5,'NONE','MIDDLE','AVAILABLE'),(1,'B06',2,6,'NONE','MIDDLE','AVAILABLE'),
(1,'B07',2,7,'TRACK','MIDDLE','AVAILABLE'),(1,'B08',2,8,'NONE','MIDDLE','AVAILABLE'),
(1,'B09',2,9,'FIXED','MIDDLE','AVAILABLE'),(1,'B10',2,10,'NONE','CORRIDOR','AVAILABLE'),
-- 行C
(1,'C01',3,1,'NONE','CORRIDOR','AVAILABLE'),(1,'C02',3,2,'NONE','MIDDLE','AVAILABLE'),
(1,'C03',3,3,'FIXED','MIDDLE','AVAILABLE'),(1,'C04',3,4,'NONE','MIDDLE','AVAILABLE'),
(1,'C05',3,5,'TRACK','MIDDLE','AVAILABLE'),(1,'C06',3,6,'TRACK','MIDDLE','AVAILABLE'),
(1,'C07',3,7,'NONE','MIDDLE','AVAILABLE'),(1,'C08',3,8,'FIXED','MIDDLE','AVAILABLE'),
(1,'C09',3,9,'NONE','MIDDLE','AVAILABLE'),(1,'C10',3,10,'NONE','CORRIDOR','AVAILABLE'),
-- 行D
(1,'D01',4,1,'NONE','CORRIDOR','AVAILABLE'),(1,'D02',4,2,'TRACK','MIDDLE','AVAILABLE'),
(1,'D03',4,3,'NONE','MIDDLE','DISABLED'),(1,'D04',4,4,'NONE','MIDDLE','AVAILABLE'),
(1,'D05',4,5,'FIXED','MIDDLE','AVAILABLE'),(1,'D06',4,6,'FIXED','MIDDLE','AVAILABLE'),
(1,'D07',4,7,'NONE','MIDDLE','AVAILABLE'),(1,'D08',4,8,'NONE','MIDDLE','DISABLED'),
(1,'D09',4,9,'TRACK','MIDDLE','AVAILABLE'),(1,'D10',4,10,'NONE','CORRIDOR','AVAILABLE'),
-- 行E
(1,'E01',5,1,'FIXED','CORRIDOR','AVAILABLE'),(1,'E02',5,2,'NONE','MIDDLE','AVAILABLE'),
(1,'E03',5,3,'NONE','MIDDLE','AVAILABLE'),(1,'E04',5,4,'TRACK','MIDDLE','AVAILABLE'),
(1,'E05',5,5,'NONE','MIDDLE','AVAILABLE'),(1,'E06',5,6,'NONE','MIDDLE','AVAILABLE'),
(1,'E07',5,7,'TRACK','MIDDLE','AVAILABLE'),(1,'E08',5,8,'NONE','MIDDLE','AVAILABLE'),
(1,'E09',5,9,'NONE','MIDDLE','AVAILABLE'),(1,'E10',5,10,'FIXED','CORRIDOR','AVAILABLE'),
-- 行F
(1,'F01',6,1,'FIXED','CORRIDOR','AVAILABLE'),(1,'F02',6,2,'FIXED','CORRIDOR','AVAILABLE'),
(1,'F03',6,3,'TRACK','CORRIDOR','AVAILABLE'),(1,'F04',6,4,'NONE','CORRIDOR','AVAILABLE'),
(1,'F05',6,5,'NONE','CORRIDOR','AVAILABLE'),(1,'F06',6,6,'NONE','CORRIDOR','AVAILABLE'),
(1,'F07',6,7,'NONE','CORRIDOR','AVAILABLE'),(1,'F08',6,8,'TRACK','CORRIDOR','AVAILABLE'),
(1,'F09',6,9,'FIXED','CORRIDOR','AVAILABLE'),(1,'F10',6,10,'FIXED','CORRIDOR','AVAILABLE');

-- -------------------------------------------------------
-- Room 2：图书馆302（左区 8×9 + 右区 3×5，中间空3列）
-- 左区列1-9，右区列13-17（col_num直接用实际列号表示间距）
-- -------------------------------------------------------
-- 左区 8行×9列 = 72座（列1-9）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(2,'LA01',1,1,'FIXED','WINDOW','AVAILABLE'),(2,'LA02',1,2,'TRACK','WINDOW','AVAILABLE'),
(2,'LA03',1,3,'NONE','WINDOW','AVAILABLE'),(2,'LA04',1,4,'NONE','WINDOW','AVAILABLE'),
(2,'LA05',1,5,'NONE','WINDOW','AVAILABLE'),(2,'LA06',1,6,'NONE','WINDOW','AVAILABLE'),
(2,'LA07',1,7,'NONE','WINDOW','AVAILABLE'),(2,'LA08',1,8,'TRACK','WINDOW','AVAILABLE'),
(2,'LA09',1,9,'FIXED','WINDOW','AVAILABLE'),
(2,'LB01',2,1,'NONE','CORRIDOR','AVAILABLE'),(2,'LB02',2,2,'FIXED','MIDDLE','AVAILABLE'),
(2,'LB03',2,3,'NONE','MIDDLE','AVAILABLE'),(2,'LB04',2,4,'TRACK','MIDDLE','AVAILABLE'),
(2,'LB05',2,5,'NONE','MIDDLE','AVAILABLE'),(2,'LB06',2,6,'TRACK','MIDDLE','AVAILABLE'),
(2,'LB07',2,7,'NONE','MIDDLE','AVAILABLE'),(2,'LB08',2,8,'FIXED','MIDDLE','AVAILABLE'),
(2,'LB09',2,9,'NONE','CORRIDOR','AVAILABLE'),
(2,'LC01',3,1,'NONE','CORRIDOR','AVAILABLE'),(2,'LC02',3,2,'NONE','MIDDLE','AVAILABLE'),
(2,'LC03',3,3,'FIXED','MIDDLE','AVAILABLE'),(2,'LC04',3,4,'NONE','MIDDLE','AVAILABLE'),
(2,'LC05',3,5,'NONE','MIDDLE','DISABLED'),(2,'LC06',3,6,'NONE','MIDDLE','AVAILABLE'),
(2,'LC07',3,7,'FIXED','MIDDLE','AVAILABLE'),(2,'LC08',3,8,'NONE','MIDDLE','AVAILABLE'),
(2,'LC09',3,9,'NONE','CORRIDOR','AVAILABLE'),
(2,'LD01',4,1,'TRACK','CORRIDOR','AVAILABLE'),(2,'LD02',4,2,'NONE','MIDDLE','AVAILABLE'),
(2,'LD03',4,3,'NONE','MIDDLE','AVAILABLE'),(2,'LD04',4,4,'FIXED','MIDDLE','AVAILABLE'),
(2,'LD05',4,5,'NONE','MIDDLE','AVAILABLE'),(2,'LD06',4,6,'FIXED','MIDDLE','AVAILABLE'),
(2,'LD07',4,7,'NONE','MIDDLE','AVAILABLE'),(2,'LD08',4,8,'NONE','MIDDLE','AVAILABLE'),
(2,'LD09',4,9,'TRACK','CORRIDOR','AVAILABLE'),
(2,'LE01',5,1,'NONE','CORRIDOR','AVAILABLE'),(2,'LE02',5,2,'FIXED','MIDDLE','AVAILABLE'),
(2,'LE03',5,3,'TRACK','MIDDLE','AVAILABLE'),(2,'LE04',5,4,'NONE','MIDDLE','AVAILABLE'),
(2,'LE05',5,5,'NONE','MIDDLE','AVAILABLE'),(2,'LE06',5,6,'NONE','MIDDLE','AVAILABLE'),
(2,'LE07',5,7,'TRACK','MIDDLE','AVAILABLE'),(2,'LE08',5,8,'FIXED','MIDDLE','AVAILABLE'),
(2,'LE09',5,9,'NONE','CORRIDOR','AVAILABLE'),
(2,'LF01',6,1,'NONE','CORRIDOR','AVAILABLE'),(2,'LF02',6,2,'NONE','MIDDLE','AVAILABLE'),
(2,'LF03',6,3,'NONE','MIDDLE','AVAILABLE'),(2,'LF04',6,4,'TRACK','MIDDLE','AVAILABLE'),
(2,'LF05',6,5,'FIXED','MIDDLE','AVAILABLE'),(2,'LF06',6,6,'TRACK','MIDDLE','AVAILABLE'),
(2,'LF07',6,7,'NONE','MIDDLE','AVAILABLE'),(2,'LF08',6,8,'NONE','MIDDLE','AVAILABLE'),
(2,'LF09',6,9,'NONE','CORRIDOR','AVAILABLE'),
(2,'LG01',7,1,'FIXED','CORRIDOR','AVAILABLE'),(2,'LG02',7,2,'NONE','MIDDLE','AVAILABLE'),
(2,'LG03',7,3,'FIXED','MIDDLE','AVAILABLE'),(2,'LG04',7,4,'NONE','MIDDLE','DISABLED'),
(2,'LG05',7,5,'NONE','MIDDLE','AVAILABLE'),(2,'LG06',7,6,'NONE','MIDDLE','AVAILABLE'),
(2,'LG07',7,7,'FIXED','MIDDLE','AVAILABLE'),(2,'LG08',7,8,'NONE','MIDDLE','AVAILABLE'),
(2,'LG09',7,9,'FIXED','CORRIDOR','AVAILABLE'),
(2,'LH01',8,1,'FIXED','CORRIDOR','AVAILABLE'),(2,'LH02',8,2,'FIXED','CORRIDOR','AVAILABLE'),
(2,'LH03',8,3,'NONE','CORRIDOR','AVAILABLE'),(2,'LH04',8,4,'TRACK','CORRIDOR','AVAILABLE'),
(2,'LH05',8,5,'NONE','CORRIDOR','AVAILABLE'),(2,'LH06',8,6,'NONE','CORRIDOR','AVAILABLE'),
(2,'LH07',8,7,'TRACK','CORRIDOR','AVAILABLE'),(2,'LH08',8,8,'FIXED','CORRIDOR','AVAILABLE'),
(2,'LH09',8,9,'FIXED','CORRIDOR','AVAILABLE');

-- 右区 3行×5列 = 15座（列13-17，行1-3，靠窗朝右）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(2,'RA01',1,13,'FIXED','WINDOW','AVAILABLE'),(2,'RA02',1,14,'FIXED','WINDOW','AVAILABLE'),
(2,'RA03',1,15,'NONE','WINDOW','AVAILABLE'),(2,'RA04',1,16,'NONE','WINDOW','AVAILABLE'),
(2,'RA05',1,17,'FIXED','WINDOW','AVAILABLE'),
(2,'RB01',2,13,'NONE','CORRIDOR','AVAILABLE'),(2,'RB02',2,14,'FIXED','MIDDLE','AVAILABLE'),
(2,'RB03',2,15,'NONE','MIDDLE','AVAILABLE'),(2,'RB04',2,16,'FIXED','MIDDLE','AVAILABLE'),
(2,'RB05',2,17,'NONE','CORRIDOR','AVAILABLE'),
(2,'RC01',3,13,'FIXED','CORRIDOR','AVAILABLE'),(2,'RC02',3,14,'NONE','CORRIDOR','AVAILABLE'),
(2,'RC03',3,15,'TRACK','CORRIDOR','AVAILABLE'),(2,'RC04',3,16,'NONE','CORRIDOR','AVAILABLE'),
(2,'RC05',3,17,'FIXED','CORRIDOR','AVAILABLE');

-- -------------------------------------------------------
-- Room 3：计算机学院机房（三个独立区域）
-- 区域A：教师机区 1×8（第1行），区域B：学生机主区 4×10，区域C：角落研讨区 3×4
-- -------------------------------------------------------
-- 区域A：教师/演示区（第1行，全固定插座）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(3,'T01',1,1,'FIXED','WINDOW','AVAILABLE'),(3,'T02',1,2,'FIXED','WINDOW','AVAILABLE'),
(3,'T03',1,3,'FIXED','WINDOW','AVAILABLE'),(3,'T04',1,4,'FIXED','WINDOW','AVAILABLE'),
(3,'T05',1,5,'FIXED','WINDOW','AVAILABLE'),(3,'T06',1,6,'FIXED','WINDOW','AVAILABLE'),
(3,'T07',1,7,'FIXED','WINDOW','AVAILABLE'),(3,'T08',1,8,'FIXED','WINDOW','AVAILABLE');

-- 区域B：学生机主区（第3-6行，1-10列，全固定插座）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(3,'A01',3,1,'FIXED','CORRIDOR','AVAILABLE'),(3,'A02',3,2,'FIXED','MIDDLE','AVAILABLE'),
(3,'A03',3,3,'FIXED','MIDDLE','AVAILABLE'),(3,'A04',3,4,'FIXED','MIDDLE','AVAILABLE'),
(3,'A05',3,5,'FIXED','MIDDLE','AVAILABLE'),(3,'A06',3,6,'FIXED','MIDDLE','AVAILABLE'),
(3,'A07',3,7,'FIXED','MIDDLE','AVAILABLE'),(3,'A08',3,8,'FIXED','MIDDLE','AVAILABLE'),
(3,'A09',3,9,'FIXED','MIDDLE','AVAILABLE'),(3,'A10',3,10,'FIXED','CORRIDOR','AVAILABLE'),
(3,'B01',4,1,'FIXED','CORRIDOR','AVAILABLE'),(3,'B02',4,2,'FIXED','MIDDLE','AVAILABLE'),
(3,'B03',4,3,'FIXED','MIDDLE','AVAILABLE'),(3,'B04',4,4,'FIXED','MIDDLE','AVAILABLE'),
(3,'B05',4,5,'FIXED','MIDDLE','DISABLED'),(3,'B06',4,6,'FIXED','MIDDLE','AVAILABLE'),
(3,'B07',4,7,'FIXED','MIDDLE','AVAILABLE'),(3,'B08',4,8,'FIXED','MIDDLE','AVAILABLE'),
(3,'B09',4,9,'FIXED','MIDDLE','AVAILABLE'),(3,'B10',4,10,'FIXED','CORRIDOR','AVAILABLE'),
(3,'C01',5,1,'FIXED','CORRIDOR','AVAILABLE'),(3,'C02',5,2,'FIXED','MIDDLE','AVAILABLE'),
(3,'C03',5,3,'FIXED','MIDDLE','AVAILABLE'),(3,'C04',5,4,'FIXED','MIDDLE','AVAILABLE'),
(3,'C05',5,5,'FIXED','MIDDLE','AVAILABLE'),(3,'C06',5,6,'FIXED','MIDDLE','AVAILABLE'),
(3,'C07',5,7,'FIXED','MIDDLE','AVAILABLE'),(3,'C08',5,8,'FIXED','MIDDLE','AVAILABLE'),
(3,'C09',5,9,'FIXED','MIDDLE','DISABLED'),(3,'C10',5,10,'FIXED','CORRIDOR','AVAILABLE'),
(3,'D01',6,1,'FIXED','CORRIDOR','AVAILABLE'),(3,'D02',6,2,'FIXED','MIDDLE','AVAILABLE'),
(3,'D03',6,3,'FIXED','MIDDLE','AVAILABLE'),(3,'D04',6,4,'FIXED','MIDDLE','AVAILABLE'),
(3,'D05',6,5,'FIXED','MIDDLE','AVAILABLE'),(3,'D06',6,6,'FIXED','MIDDLE','AVAILABLE'),
(3,'D07',6,7,'FIXED','MIDDLE','AVAILABLE'),(3,'D08',6,8,'FIXED','MIDDLE','AVAILABLE'),
(3,'D09',6,9,'FIXED','MIDDLE','AVAILABLE'),(3,'D10',6,10,'FIXED','CORRIDOR','AVAILABLE');

-- 区域C：角落研讨/自由区（第3-5行，12-15列，导轨插座）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(3,'S01',3,12,'TRACK','WINDOW','AVAILABLE'),(3,'S02',3,13,'TRACK','WINDOW','AVAILABLE'),
(3,'S03',3,14,'TRACK','WINDOW','AVAILABLE'),(3,'S04',3,15,'TRACK','WINDOW','AVAILABLE'),
(3,'S05',4,12,'TRACK','CORRIDOR','AVAILABLE'),(3,'S06',4,13,'TRACK','MIDDLE','AVAILABLE'),
(3,'S07',4,14,'TRACK','MIDDLE','AVAILABLE'),(3,'S08',4,15,'TRACK','CORRIDOR','AVAILABLE'),
(3,'S09',5,12,'TRACK','CORRIDOR','AVAILABLE'),(3,'S10',5,13,'TRACK','CORRIDOR','AVAILABLE'),
(3,'S11',5,14,'TRACK','CORRIDOR','AVAILABLE'),(3,'S12',5,15,'TRACK','CORRIDOR','AVAILABLE');

-- -------------------------------------------------------
-- Room 4：电子工程实验室（五个独立区域）
-- 区域1：精密仪器区 2×6（靠窗，固定插座）
-- 区域2：焊接实训区 2×4
-- 区域3：电路调试区 3×5（导轨插座）
-- 区域4：数字系统区 2×6
-- 区域5：自由自习区 3×8（无插座为主）
-- -------------------------------------------------------
-- 区域1：精密仪器区（行1-2，列1-6）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(4,'P01',1,1,'FIXED','WINDOW','AVAILABLE'),(4,'P02',1,2,'FIXED','WINDOW','AVAILABLE'),
(4,'P03',1,3,'FIXED','WINDOW','AVAILABLE'),(4,'P04',1,4,'FIXED','WINDOW','AVAILABLE'),
(4,'P05',1,5,'FIXED','WINDOW','AVAILABLE'),(4,'P06',1,6,'FIXED','WINDOW','AVAILABLE'),
(4,'P07',2,1,'FIXED','CORRIDOR','AVAILABLE'),(4,'P08',2,2,'FIXED','MIDDLE','AVAILABLE'),
(4,'P09',2,3,'FIXED','MIDDLE','AVAILABLE'),(4,'P10',2,4,'FIXED','MIDDLE','AVAILABLE'),
(4,'P11',2,5,'FIXED','MIDDLE','AVAILABLE'),(4,'P12',2,6,'FIXED','CORRIDOR','AVAILABLE');

-- 区域2：焊接实训区（行1-2，列9-12）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(4,'W01',1,9,'FIXED','WINDOW','AVAILABLE'),(4,'W02',1,10,'FIXED','WINDOW','AVAILABLE'),
(4,'W03',1,11,'FIXED','WINDOW','AVAILABLE'),(4,'W04',1,12,'FIXED','WINDOW','AVAILABLE'),
(4,'W05',2,9,'FIXED','CORRIDOR','AVAILABLE'),(4,'W06',2,10,'FIXED','MIDDLE','AVAILABLE'),
(4,'W07',2,11,'FIXED','MIDDLE','AVAILABLE'),(4,'W08',2,12,'FIXED','CORRIDOR','AVAILABLE');

-- 区域3：电路调试区（行4-6，列1-5，导轨插座）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(4,'E01',4,1,'TRACK','CORRIDOR','AVAILABLE'),(4,'E02',4,2,'TRACK','MIDDLE','AVAILABLE'),
(4,'E03',4,3,'TRACK','MIDDLE','AVAILABLE'),(4,'E04',4,4,'TRACK','MIDDLE','AVAILABLE'),
(4,'E05',4,5,'TRACK','CORRIDOR','AVAILABLE'),
(4,'E06',5,1,'TRACK','CORRIDOR','AVAILABLE'),(4,'E07',5,2,'TRACK','MIDDLE','AVAILABLE'),
(4,'E08',5,3,'TRACK','MIDDLE','DISABLED'),(4,'E09',5,4,'TRACK','MIDDLE','AVAILABLE'),
(4,'E10',5,5,'TRACK','CORRIDOR','AVAILABLE'),
(4,'E11',6,1,'TRACK','CORRIDOR','AVAILABLE'),(4,'E12',6,2,'TRACK','MIDDLE','AVAILABLE'),
(4,'E13',6,3,'TRACK','MIDDLE','AVAILABLE'),(4,'E14',6,4,'TRACK','MIDDLE','AVAILABLE'),
(4,'E15',6,5,'TRACK','CORRIDOR','AVAILABLE');

-- 区域4：数字系统区（行4-5，列8-13）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(4,'D01',4,8,'FIXED','CORRIDOR','AVAILABLE'),(4,'D02',4,9,'FIXED','MIDDLE','AVAILABLE'),
(4,'D03',4,10,'FIXED','MIDDLE','AVAILABLE'),(4,'D04',4,11,'FIXED','MIDDLE','AVAILABLE'),
(4,'D05',4,12,'FIXED','MIDDLE','AVAILABLE'),(4,'D06',4,13,'FIXED','CORRIDOR','AVAILABLE'),
(4,'D07',5,8,'FIXED','CORRIDOR','AVAILABLE'),(4,'D08',5,9,'FIXED','MIDDLE','AVAILABLE'),
(4,'D09',5,10,'FIXED','MIDDLE','AVAILABLE'),(4,'D10',5,11,'FIXED','MIDDLE','AVAILABLE'),
(4,'D11',5,12,'FIXED','MIDDLE','AVAILABLE'),(4,'D12',5,13,'FIXED','CORRIDOR','AVAILABLE');

-- 区域5：自由自习区（行8-10，列1-8，无插座为主）
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(4,'F01',8,1,'NONE','CORRIDOR','AVAILABLE'),(4,'F02',8,2,'NONE','MIDDLE','AVAILABLE'),
(4,'F03',8,3,'NONE','MIDDLE','AVAILABLE'),(4,'F04',8,4,'TRACK','MIDDLE','AVAILABLE'),
(4,'F05',8,5,'TRACK','MIDDLE','AVAILABLE'),(4,'F06',8,6,'NONE','MIDDLE','AVAILABLE'),
(4,'F07',8,7,'NONE','MIDDLE','AVAILABLE'),(4,'F08',8,8,'NONE','CORRIDOR','AVAILABLE'),
(4,'F09',9,1,'NONE','CORRIDOR','AVAILABLE'),(4,'F10',9,2,'NONE','MIDDLE','AVAILABLE'),
(4,'F11',9,3,'NONE','MIDDLE','AVAILABLE'),(4,'F12',9,4,'NONE','MIDDLE','AVAILABLE'),
(4,'F13',9,5,'NONE','MIDDLE','AVAILABLE'),(4,'F14',9,6,'NONE','MIDDLE','AVAILABLE'),
(4,'F15',9,7,'NONE','MIDDLE','AVAILABLE'),(4,'F16',9,8,'NONE','CORRIDOR','AVAILABLE'),
(4,'F17',10,1,'FIXED','CORRIDOR','AVAILABLE'),(4,'F18',10,2,'NONE','CORRIDOR','AVAILABLE'),
(4,'F19',10,3,'NONE','CORRIDOR','AVAILABLE'),(4,'F20',10,4,'TRACK','CORRIDOR','AVAILABLE'),
(4,'F21',10,5,'TRACK','CORRIDOR','AVAILABLE'),(4,'F22',10,6,'NONE','CORRIDOR','AVAILABLE'),
(4,'F23',10,7,'NONE','CORRIDOR','AVAILABLE'),(4,'F24',10,8,'FIXED','CORRIDOR','AVAILABLE');

-- -------------------------------------------------------
-- Room 5：经管院自习室（方形 4×8 = 32座）
-- -------------------------------------------------------
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
(5,'A01',1,1,'FIXED','WINDOW','AVAILABLE'),(5,'A02',1,2,'FIXED','WINDOW','AVAILABLE'),
(5,'A03',1,3,'NONE','WINDOW','AVAILABLE'),(5,'A04',1,4,'NONE','WINDOW','AVAILABLE'),
(5,'A05',1,5,'NONE','WINDOW','AVAILABLE'),(5,'A06',1,6,'NONE','WINDOW','AVAILABLE'),
(5,'A07',1,7,'FIXED','WINDOW','AVAILABLE'),(5,'A08',1,8,'FIXED','WINDOW','AVAILABLE'),
(5,'B01',2,1,'NONE','CORRIDOR','AVAILABLE'),(5,'B02',2,2,'FIXED','MIDDLE','AVAILABLE'),
(5,'B03',2,3,'NONE','MIDDLE','AVAILABLE'),(5,'B04',2,4,'TRACK','MIDDLE','AVAILABLE'),
(5,'B05',2,5,'TRACK','MIDDLE','AVAILABLE'),(5,'B06',2,6,'NONE','MIDDLE','AVAILABLE'),
(5,'B07',2,7,'FIXED','MIDDLE','AVAILABLE'),(5,'B08',2,8,'NONE','CORRIDOR','AVAILABLE'),
(5,'C01',3,1,'NONE','CORRIDOR','AVAILABLE'),(5,'C02',3,2,'NONE','MIDDLE','AVAILABLE'),
(5,'C03',3,3,'FIXED','MIDDLE','AVAILABLE'),(5,'C04',3,4,'NONE','MIDDLE','AVAILABLE'),
(5,'C05',3,5,'NONE','MIDDLE','AVAILABLE'),(5,'C06',3,6,'FIXED','MIDDLE','AVAILABLE'),
(5,'C07',3,7,'NONE','MIDDLE','AVAILABLE'),(5,'C08',3,8,'NONE','CORRIDOR','AVAILABLE'),
(5,'D01',4,1,'FIXED','CORRIDOR','AVAILABLE'),(5,'D02',4,2,'FIXED','CORRIDOR','AVAILABLE'),
(5,'D03',4,3,'NONE','CORRIDOR','AVAILABLE'),(5,'D04',4,4,'TRACK','CORRIDOR','AVAILABLE'),
(5,'D05',4,5,'TRACK','CORRIDOR','AVAILABLE'),(5,'D06',4,6,'NONE','CORRIDOR','AVAILABLE'),
(5,'D07',4,7,'FIXED','CORRIDOR','AVAILABLE'),(5,'D08',4,8,'FIXED','CORRIDOR','AVAILABLE');

-- -------------------------------------------------------
-- Room 6：综合楼通宵自习室（5×12 = 60座，全天开放）
-- -------------------------------------------------------
INSERT IGNORE INTO `t_seat` (`room_id`,`seat_number`,`row_num`,`col_num`,`socket_type`,`position`,`status`) VALUES
-- 行A（靠窗）
(6,'A01',1,1,'FIXED','WINDOW','AVAILABLE'),(6,'A02',1,2,'TRACK','WINDOW','AVAILABLE'),
(6,'A03',1,3,'NONE','WINDOW','AVAILABLE'),(6,'A04',1,4,'NONE','WINDOW','AVAILABLE'),
(6,'A05',1,5,'NONE','WINDOW','AVAILABLE'),(6,'A06',1,6,'FIXED','WINDOW','AVAILABLE'),
(6,'A07',1,7,'FIXED','WINDOW','AVAILABLE'),(6,'A08',1,8,'NONE','WINDOW','AVAILABLE'),
(6,'A09',1,9,'NONE','WINDOW','AVAILABLE'),(6,'A10',1,10,'NONE','WINDOW','AVAILABLE'),
(6,'A11',1,11,'TRACK','WINDOW','AVAILABLE'),(6,'A12',1,12,'FIXED','WINDOW','AVAILABLE'),
-- 行B
(6,'B01',2,1,'NONE','CORRIDOR','AVAILABLE'),(6,'B02',2,2,'FIXED','MIDDLE','AVAILABLE'),
(6,'B03',2,3,'TRACK','MIDDLE','AVAILABLE'),(6,'B04',2,4,'NONE','MIDDLE','AVAILABLE'),
(6,'B05',2,5,'NONE','MIDDLE','AVAILABLE'),(6,'B06',2,6,'FIXED','MIDDLE','AVAILABLE'),
(6,'B07',2,7,'FIXED','MIDDLE','AVAILABLE'),(6,'B08',2,8,'NONE','MIDDLE','AVAILABLE'),
(6,'B09',2,9,'NONE','MIDDLE','AVAILABLE'),(6,'B10',2,10,'TRACK','MIDDLE','AVAILABLE'),
(6,'B11',2,11,'FIXED','MIDDLE','AVAILABLE'),(6,'B12',2,12,'NONE','CORRIDOR','AVAILABLE'),
-- 行C
(6,'C01',3,1,'FIXED','CORRIDOR','AVAILABLE'),(6,'C02',3,2,'NONE','MIDDLE','AVAILABLE'),
(6,'C03',3,3,'NONE','MIDDLE','AVAILABLE'),(6,'C04',3,4,'TRACK','MIDDLE','AVAILABLE'),
(6,'C05',3,5,'FIXED','MIDDLE','AVAILABLE'),(6,'C06',3,6,'NONE','MIDDLE','DISABLED'),
(6,'C07',3,7,'NONE','MIDDLE','AVAILABLE'),(6,'C08',3,8,'FIXED','MIDDLE','AVAILABLE'),
(6,'C09',3,9,'TRACK','MIDDLE','AVAILABLE'),(6,'C10',3,10,'NONE','MIDDLE','AVAILABLE'),
(6,'C11',3,11,'NONE','MIDDLE','AVAILABLE'),(6,'C12',3,12,'FIXED','CORRIDOR','AVAILABLE'),
-- 行D
(6,'D01',4,1,'NONE','CORRIDOR','AVAILABLE'),(6,'D02',4,2,'FIXED','MIDDLE','AVAILABLE'),
(6,'D03',4,3,'NONE','MIDDLE','AVAILABLE'),(6,'D04',4,4,'NONE','MIDDLE','AVAILABLE'),
(6,'D05',4,5,'TRACK','MIDDLE','AVAILABLE'),(6,'D06',4,6,'FIXED','MIDDLE','AVAILABLE'),
(6,'D07',4,7,'FIXED','MIDDLE','AVAILABLE'),(6,'D08',4,8,'TRACK','MIDDLE','AVAILABLE'),
(6,'D09',4,9,'NONE','MIDDLE','AVAILABLE'),(6,'D10',4,10,'NONE','MIDDLE','AVAILABLE'),
(6,'D11',4,11,'FIXED','MIDDLE','DISABLED'),(6,'D12',4,12,'NONE','CORRIDOR','AVAILABLE'),
-- 行E（靠走廊）
(6,'E01',5,1,'FIXED','CORRIDOR','AVAILABLE'),(6,'E02',5,2,'FIXED','CORRIDOR','AVAILABLE'),
(6,'E03',5,3,'NONE','CORRIDOR','AVAILABLE'),(6,'E04',5,4,'TRACK','CORRIDOR','AVAILABLE'),
(6,'E05',5,5,'NONE','CORRIDOR','AVAILABLE'),(6,'E06',5,6,'FIXED','CORRIDOR','AVAILABLE'),
(6,'E07',5,7,'FIXED','CORRIDOR','AVAILABLE'),(6,'E08',5,8,'NONE','CORRIDOR','AVAILABLE'),
(6,'E09',5,9,'TRACK','CORRIDOR','AVAILABLE'),(6,'E10',5,10,'NONE','CORRIDOR','AVAILABLE'),
(6,'E11',5,11,'FIXED','CORRIDOR','AVAILABLE'),(6,'E12',5,12,'FIXED','CORRIDOR','AVAILABLE');

-- ========== 10. 今日签到码 ==========
INSERT IGNORE INTO `t_check_in_code` (`room_id`, `code_date`, `code`) VALUES
(1, CURDATE(), 'A1B2C3'),
(2, CURDATE(), 'D4E5F6'),
(3, CURDATE(), 'G7H8I9'),
(4, CURDATE(), 'J0K1L2'),
(5, CURDATE(), 'M3N4O5'),
(6, CURDATE(), 'P6Q7R8');
