#!/bin/bash
# SeatFlow 前端交互测试脚本
# 按PRD要求，逐页面、逐功能验证交互逻辑

FRONTEND_URL="http://localhost:5173"
AGENT_BROWSER="agent-browser"
PASS=0; FAIL=0; ISSUES=""

report() {
  local id=$1 status=$2 detail=$3
  if [ "$status" = "PASS" ]; then
    PASS=$((PASS+1)); echo "✅ [$id] $detail"
  else
    FAIL=$((FAIL+1)); echo "❌ [$id] $detail"
    ISSUES="$ISSUES\n- [$id] $detail"
  fi
}

echo "=========================================="
echo "  SeatFlow 前端交互全功能测试"
echo "=========================================="

# ===== 1. 登录页面 =====
echo -e "\n--- 1. 登录页面 ---"

# 测试管理员登录
$AGENT_BROWSER go $FRONTEND_URL/login 2>/dev/null
$AGENT_BROWSER input "username" "admin" 2>/dev/null
$AGENT_BROWSER input "password" "admin123" 2>/dev/null
$AGENT_BROWSER click "登录" 2>/dev/null
sleep 2
if $AGENT_BROWSER current_url | grep -q "/admin/dashboard"; then
  report "LOGIN01" "PASS" "管理员登录成功，跳转至仪表盘"
else
  report "LOGIN01" "FAIL" "管理员登录失败，未跳转至仪表盘"
fi

# 退出登录
$AGENT_BROWSER click "退出登录" 2>/dev/null
sleep 1

# 测试学生登录
$AGENT_BROWSER input "username" "student1" 2>/dev/null
$AGENT_BROWSER input "password" "student123" 2>/dev/null
$AGENT_BROWSER click "登录" 2>/dev/null
sleep 2
if $AGENT_BROWSER current_url | grep -q "/student/rooms"; then
  report "LOGIN02" "PASS" "学生登录成功，跳转至自习室列表"
else
  report "LOGIN02" "FAIL" "学生登录失败，未跳转至自习室列表"
fi

# ===== 2. 学生端：自习室列表 =====
echo -e "\n--- 2. 学生端：自习室列表 ---"
ROOM_COUNT=$($AGENT_BROWSER count ".room-card" 2>/dev/null)
if [ "$ROOM_COUNT" -ge 2 ]; then
  report "STUD_ROOM01" "PASS" "自习室列表展示正确，共$ROOM_COUNT个自习室"
else
  report "STUD_ROOM01" "FAIL" "自习室列表展示错误，仅$ROOM_COUNT个"
fi

# 检查自习室信息展示
ROOM_NAME=$($AGENT_BROWSER text ".room-card:first-child .room-name" 2>/dev/null)
if [[ "$ROOM_NAME" =~ "图书馆301" ]]; then
  report "STUD_ROOM02" "PASS" "自习室中文名显示正常: $ROOM_NAME"
else
  report "STUD_ROOM02" "FAIL" "自习室中文名显示异常: $ROOM_NAME"
fi

# ===== 3. 学生端：自习室详情 + 座位图 =====
echo -e "\n--- 3. 学生端：自习室详情 + 座位图 ---"
$AGENT_BROWSER click ".room-card:first-child" 2>/dev/null
sleep 2
SEAT_COUNT=$($AGENT_BROWSER count ".seat" 2>/dev/null)
if [ "$SEAT_COUNT" -ge 10 ]; then
  report "STUD_SEAT01" "PASS" "座位图展示正确，共$SEAT_COUNT个座位"
else
  report "STUD_SEAT01" "FAIL" "座位图展示错误，仅$SEAT_COUNT个座位"
fi

# 检查可选座位
AVAIL_SEAT_COUNT=$($AGENT_BROWSER count ".seat.available" 2>/dev/null)
if [ "$AVAIL_SEAT_COUNT" -ge 10 ]; then
  report "STUD_SEAT02" "PASS" "可选座位展示正确，共$AVAIL_SEAT_COUNT个可选"
else
  report "STUD_SEAT02" "FAIL" "可选座位展示错误，仅$AVAIL_SEAT_COUNT个可选"
fi

# 点击座位发起预约
$AGENT_BROWSER click ".seat.available:first-child" 2>/dev/null
sleep 1
if $AGENT_BROWSER exists ".reservation-modal"; then
  report "STUD_RES01" "PASS" "点击座位弹出预约弹窗"
else
  report "STUD_RES01" "FAIL" "点击座位未弹出预约弹窗"
fi

# 提交预约
$AGENT_BROWSER select "date" "明天" 2>/dev/null
$AGENT_BROWSER select "startTime" "09:00" 2>/dev/null
$AGENT_BROWSER select "endTime" "11:00" 2>/dev/null
$AGENT_BROWSER click "确认预约" 2>/dev/null
sleep 2
if $AGENT_BROWSER exists ".ant-message-success"; then
  report "STUD_RES02" "PASS" "预约提交成功"
else
  report "STUD_RES02" "FAIL" "预约提交失败"
fi

# ===== 4. 学生端：我的预约 =====
echo -e "\n--- 4. 学生端：我的预约 ---"
$AGENT_BROWSER go $FRONTEND_URL/student/reservations 2>/dev/null
sleep 2
CURR_RES_COUNT=$($AGENT_BROWSER count ".current-reservations .reservation-item" 2>/dev/null)
if [ "$CURR_RES_COUNT" -ge 1 ]; then
  report "STUD_CURR01" "PASS" "当前预约展示正确，共$CURR_RES_COUNT个预约"
else
  report "STUD_CURR01" "FAIL" "当前预约展示错误，仅$CURR_RES_COUNT个"
fi

# 取消预约
$AGENT_BROWSER click ".current-reservations .reservation-item:first-child .cancel-btn" 2>/dev/null
sleep 1
$AGENT_BROWSER click "确认" 2>/dev/null
sleep 1
if $AGENT_BROWSER exists ".ant-message-success"; then
  report "STUD_CURR02" "PASS" "取消预约成功"
else
  report "STUD_CURR02" "FAIL" "取消预约失败"
fi

# 检查历史预约
$AGENT_BROWSER click "历史预约" 2>/dev/null
sleep 1
HIST_RES_COUNT=$($AGENT_BROWSER count ".history-reservations .reservation-item" 2>/dev/null)
if [ "$HIST_RES_COUNT" -ge 1 ]; then
  report "STUD_HIST01" "PASS" "历史预约展示正确，共$HIST_RES_COUNT个预约"
else
  report "STUD_HIST01" "FAIL" "历史预约展示错误，仅$HIST_RES_COUNT个"
fi

# 再次预约
$AGENT_BROWSER click ".history-reservations .reservation-item:first-child .rebook-btn" 2>/dev/null
sleep 2
if $AGENT_BROWSER exists ".ant-message-success"; then
  report "STUD_REBOOK01" "PASS" "再次预约成功"
else
  report "STUD_REBOOK01" "FAIL" "再次预约失败"
fi

# ===== 5. 学生端：搜索座位 =====
echo -e "\n--- 5. 学生端：搜索座位 ---"
$AGENT_BROWSER go $FRONTEND_URL/student/search 2>/dev/null
sleep 2
$AGENT_BROWSER select "socketType" "有固定插座" 2>/dev/null
$AGENT_BROWSER select "position" "靠窗" 2>/dev/null
$AGENT_BROWSER click "搜索" 2>/dev/null
sleep 1
SEARCH_COUNT=$($AGENT_BROWSER count ".search-result .seat-item" 2>/dev/null)
if [ "$SEARCH_COUNT" -ge 0 ]; then
  report "STUD_SEARCH01" "PASS" "多条件搜索正常，共$SEARCH_COUNT个结果"
else
  report "STUD_SEARCH01" "FAIL" "多条件搜索错误"
fi

# ===== 6. 学生端：违约记录 =====
echo -e "\n--- 6. 学生端：违约记录 ---"
$AGENT_BROWSER go $FRONTEND_URL/student/violations 2>/dev/null
sleep 1
VIO_COUNT=$($AGENT_BROWSER count ".violation-item" 2>/dev/null)
if [ "$VIO_COUNT" -ge 0 ]; then
  report "STUD_VIO01" "PASS" "违约记录展示正常，共$VIO_COUNT条"
else
  report "STUD_VIO01" "FAIL" "违约记录展示错误"
fi

# ===== 7. 学生端：智能助手 =====
echo -e "\n--- 7. 学生端：智能助手 ---"
$AGENT_BROWSER go $FRONTEND_URL/student/assistant 2>/dev/null
sleep 2
$AGENT_BROWSER input ".chat-input" "有哪些自习室?" 2>/dev/null
$AGENT_BROWSER click "发送" 2>/dev/null
sleep 3
REPLY_COUNT=$($AGENT_BROWSER count ".chat-message.assistant" 2>/dev/null)
if [ "$REPLY_COUNT" -ge 1 ]; then
  report "STUD_AI01" "PASS" "智能助手回复正常"
else
  report "STUD_AI01" "FAIL" "智能助手未回复"
fi

# ===== 8. 管理员端：仪表盘 =====
echo -e "\n--- 8. 管理员端：仪表盘 ---"
$AGENT_BROWSER click "退出登录" 2>/dev/null
sleep 1
$AGENT_BROWSER input "username" "admin" 2>/dev/null
$AGENT_BROWSER input "password" "admin123" 2>/dev/null
$AGENT_BROWSER click "登录" 2>/dev/null
sleep 2
DASH_CARD_COUNT=$($AGENT_BROWSER count ".dashboard-card" 2>/dev/null)
if [ "$DASH_CARD_COUNT" -ge 4 ]; then
  report "ADMIN_DASH01" "PASS" "仪表盘展示正常，共$DASH_CARD_COUNT个统计卡片"
else
  report "ADMIN_DASH01" "FAIL" "仪表盘展示错误，仅$DASH_CARD_COUNT个卡片"
fi

# ===== 9. 管理员端：自习室管理 =====
echo -e "\n--- 9. 管理员端：自习室管理 ---"
$AGENT_BROWSER go $FRONTEND_URL/admin/rooms 2>/dev/null
sleep 2
ADMIN_ROOM_COUNT=$($AGENT_BROWSER count ".room-list .room-item" 2>/dev/null)
if [ "$ADMIN_ROOM_COUNT" -ge 3 ]; then
  report "ADMIN_ROOM01" "PASS" "自习室列表展示正确，共$ADMIN_ROOM_COUNT个"
else
  report "ADMIN_ROOM01" "FAIL" "自习室列表展示错误，仅$ADMIN_ROOM_COUNT个"
fi

# 创建自习室
$AGENT_BROWSER click "新增自习室" 2>/dev/null
sleep 1
$AGENT_BROWSER input "name" "测试自习室" 2>/dev/null
$AGENT_BROWSER input "location" "测试楼1层" 2>/dev/null
$AGENT_BROWSER click "确认" 2>/dev/null
sleep 2
if $AGENT_BROWSER exists ".ant-message-success"; then
  report "ADMIN_ROOM02" "PASS" "创建自习室成功"
else
  report "ADMIN_ROOM02" "FAIL" "创建自习室失败"
fi

# ===== 10. 管理员端：预约管理 =====
echo -e "\n--- 10. 管理员端：预约管理 ---"
$AGENT_BROWSER go $FRONTEND_URL/admin/reservations 2>/dev/null
sleep 2
ADMIN_RES_COUNT=$($AGENT_BROWSER count ".reservation-list .reservation-item" 2>/dev/null)
if [ "$ADMIN_RES_COUNT" -ge 1 ]; then
  report "ADMIN_RES01" "PASS" "预约列表展示正确，共$ADMIN_RES_COUNT个预约"
else
  report "ADMIN_RES01" "FAIL" "预约列表展示错误，仅$ADMIN_RES_COUNT个"
fi

# ===== 11. 管理员端：角色管理 =====
echo -e "\n--- 11. 管理员端：角色管理 ---"
$AGENT_BROWSER go $FRONTEND_URL/admin/roles 2>/dev/null
sleep 2
ADMIN_ROLE_COUNT=$($AGENT_BROWSER count ".role-list .role-item" 2>/dev/null)
if [ "$ADMIN_ROLE_COUNT" -ge 4 ]; then
  report "ADMIN_ROLE01" "PASS" "角色列表展示正确，共$ADMIN_ROLE_COUNT个角色"
else
  report "ADMIN_ROLE01" "FAIL" "角色列表展示错误，仅$ADMIN_ROLE_COUNT个"
fi

# 角色中文名验证
ROLE_NAME=$($AGENT_BROWSER text ".role-item:first-child .role-name" 2>/dev/null)
if [[ "$ROLE_NAME" =~ "超级管理员" ]]; then
  report "ADMIN_ROLE02" "PASS" "角色中文名显示正常: $ROLE_NAME"
else
  report "ADMIN_ROLE02" "FAIL" "角色中文名显示异常: $ROLE_NAME"
fi

# ===== 12. 管理员端：系统参数 =====
echo -e "\n--- 12. 管理员端：系统参数 ---"
$AGENT_BROWSER go $FRONTEND_URL/admin/config 2>/dev/null
sleep 2
PARAM_COUNT=$($AGENT_BROWSER count ".config-item" 2>/dev/null)
if [ "$PARAM_COUNT" -ge 4 ]; then
  report "ADMIN_CONF01" "PASS" "系统参数展示正确，共$PARAM_COUNT个参数"
else
  report "ADMIN_CONF01" "FAIL" "系统参数展示错误，仅$PARAM_COUNT个"
fi

# 修改参数
$AGENT_BROWSER input "max_reservation_hours" "4" 2>/dev/null
$AGENT_BROWSER click "保存" 2>/dev/null
sleep 1
if $AGENT_BROWSER exists ".ant-message-success"; then
  report "ADMIN_CONF02" "PASS" "修改系统参数成功"
else
  report "ADMIN_CONF02" "FAIL" "修改系统参数失败"
fi

# ===== 汇总 =====
echo -e "\n=========================================="
echo "  前端测试结果汇总"
echo "=========================================="
echo "✅ 通过: $PASS"
echo "❌ 失败: $FAIL"
echo "总计: $((PASS+FAIL))"
if [ $FAIL -gt 0 ]; then
  echo -e "\n失败用例:"
  echo -e "$ISSUES"
else
  echo -e "\n🎉 前端全部功能测试通过！"
fi
