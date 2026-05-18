#!/bin/bash
# SeatFlow 全功能后端API测试 — 基于PRD v0.3
# 逐功能测试，输出详细结果

BASE="http://localhost:8080/api"
PASS=0; FAIL=0; ISSUES=""

# Helper: get token
get_token() {
  local user=$1 pw=$2
  curl -s $BASE/auth/login -X POST -H "Content-Type: application/json" -d "{\"username\":\"$user\",\"password\":\"$pw\"}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['token'] if d.get('code')==200 else '')" 2>/dev/null
}

AH="Authorization: Bearer $(get_token admin admin123)"
SH1="Authorization: Bearer $(get_token student1 student123)"
SH2="Authorization: Bearer $(get_token student2 student123)"

report() {
  local id=$1 status=$2 detail=$3
  if [ "$status" = "PASS" ]; then
    PASS=$((PASS+1)); echo "✅ [$id] $detail"
  else
    FAIL=$((FAIL+1)); echo "❌ [$id] $detail"
    ISSUES="$ISSUES\n- [$id] $detail"
  fi
}

TOMORROW=$(date -v+1d "+%Y-%m-%d" 2>/dev/null || date -d "+1 day" "+%Y-%m-%d" 2>/dev/null)

echo "=========================================="
echo "  SeatFlow 后端API全功能测试"
echo "=========================================="

# ===== 1. 认证模块 =====
echo -e "\n--- 1. 认证模块 (A-AUTH01/02) ---"

RES=$(curl -s $BASE/auth/login -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "AUTH01" "PASS" "管理员登录成功" || report "AUTH01" "FAIL" "管理员登录失败"

RES=$(curl -s $BASE/auth/login -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong"}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" != "200" ]] && report "AUTH02" "PASS" "错误密码被拒绝" || report "AUTH02" "FAIL" "错误密码不应成功"

RES=$(curl -s $BASE/auth/me -H "$AH")
UTYPE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('userType',''))" 2>/dev/null)
[[ "$UTYPE" = "ADMIN" ]] && report "AUTH03" "PASS" "管理员userType=ADMIN" || report "AUTH03" "FAIL" "userType=$UTYPE"

RES=$(curl -s $BASE/auth/me -H "$SH1")
UTYPE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('userType',''))" 2>/dev/null)
[[ "$UTYPE" = "STUDENT" ]] && report "AUTH04" "PASS" "学生userType=STUDENT" || report "AUTH04" "FAIL" "userType=$UTYPE"

# ===== 2. 自习室模块 =====
echo -e "\n--- 2. 自习室模块 (A-ROOM01~06) ---"

RES=$(curl -s "$BASE/rooms" -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "ROOM01" "PASS" "学生获取自习室列表" || report "ROOM01" "FAIL" "code=$CODE"

FIRST_ROOM_ID=$(echo $RES | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['data'][0]['id'] if d.get('data') and len(d['data'])>0 else '')" 2>/dev/null)

RES=$(curl -s "$BASE/rooms/$FIRST_ROOM_ID" -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "ROOM02" "PASS" "自习室详情" || report "ROOM02" "FAIL" "code=$CODE"

RES=$(curl -s "$BASE/admin/rooms" -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "ROOM03" "PASS" "管理员自习室列表" || report "ROOM03" "FAIL" "code=$CODE"

RES=$(curl -s "$BASE/admin/rooms" -X POST -H "Content-Type: application/json" -H "$AH" -d '{"name":"API测试自习室","location":"测试楼","openTime":"08:00","closeTime":"22:00"}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
NEW_ROOM_ID=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('id',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "ROOM04" "PASS" "创建自习室 id=$NEW_ROOM_ID" || report "ROOM04" "FAIL" "$RES"

RES=$(curl -s "$BASE/admin/rooms/$NEW_ROOM_ID" -X PUT -H "Content-Type: application/json" -H "$AH" -d '{"name":"API测试-已更新"}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "ROOM05" "PASS" "更新自习室" || report "ROOM05" "FAIL" "$RES"

RES=$(curl -s "$BASE/admin/rooms/$NEW_ROOM_ID" -X DELETE -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "ROOM06" "PASS" "删除自习室" || report "ROOM06" "FAIL" "$RES"

# 中文验证
ROOM_NAME=$(curl -s "$BASE/rooms/$FIRST_ROOM_ID" -H "$SH1" | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('name',''))" 2>/dev/null)
[[ "$ROOM_NAME" =~ [一-龥] ]] && report "ROOM07" "PASS" "自习室中文名正常: $ROOM_NAME" || report "ROOM07" "FAIL" "中文异常: $ROOM_NAME"

# ===== 3. 座位模块 =====
echo -e "\n--- 3. 座位模块 (A-SEAT01~05) ---"

RES=$(curl -s "$BASE/rooms/$FIRST_ROOM_ID/seats" -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
SEAT_COUNT=$(echo $RES | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d.get('data',[])))" 2>/dev/null)
[[ "$CODE" = "200" && "$SEAT_COUNT" -gt 0 ]] && report "SEAT01" "PASS" "座位列表($SEAT_COUNT个)" || report "SEAT01" "FAIL" "code=$CODE count=$SEAT_COUNT"

FIRST_SEAT_ID=$(echo $RES | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['data'][0]['id'] if d.get('data') and len(d['data'])>0 else '')" 2>/dev/null)

# 管理端座位CRUD (正确路径: /api/admin/rooms/{roomId}/seats)
RES=$(curl -s "$BASE/admin/rooms/$FIRST_ROOM_ID/seats" -X POST -H "Content-Type: application/json" -H "$AH" -d '{"seatNumber":"T-01","rowNum":9,"colNum":9,"socketType":"FIXED","position":"WINDOW"}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
NEW_SEAT_ID=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('id',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "SEAT02" "PASS" "创建座位 id=$NEW_SEAT_ID" || report "SEAT02" "FAIL" "$RES"

RES=$(curl -s "$BASE/admin/rooms/$FIRST_ROOM_ID/seats/$NEW_SEAT_ID" -X PUT -H "Content-Type: application/json" -H "$AH" -d '{"socketType":"MOVABLE","position":"CORRIDOR"}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "SEAT03" "PASS" "更新座位" || report "SEAT03" "FAIL" "$RES"

RES=$(curl -s "$BASE/admin/rooms/$FIRST_ROOM_ID/seats/$NEW_SEAT_ID" -X DELETE -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "SEAT04" "PASS" "删除座位" || report "SEAT04" "FAIL" "$RES"

# ===== 4. 预约模块 =====
echo -e "\n--- 4. 预约模块 (A-RES01~09) ---"

# 创建预约
RES=$(curl -s "$BASE/reservations" -X POST -H "Content-Type: application/json" -H "$SH1" -d "{\"seatId\":$FIRST_SEAT_ID,\"date\":\"$TOMORROW\",\"startTime\":\"09:00\",\"endTime\":\"11:00\"}")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
RES_ID=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('id',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RES01" "PASS" "创建预约 id=$RES_ID" || report "RES01" "FAIL" "$RES"

# 同座位同时段冲突
RES=$(curl -s "$BASE/reservations" -X POST -H "Content-Type: application/json" -H "$SH2" -d "{\"seatId\":$FIRST_SEAT_ID,\"date\":\"$TOMORROW\",\"startTime\":\"09:00\",\"endTime\":\"11:00\"}")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" != "200" ]] && report "RES02" "PASS" "同座位冲突被拒绝" || report "RES02" "FAIL" "同座位不应重复预约"

# 同用户同时段多座位
ANOTHER_SEAT=$(curl -s "$BASE/rooms/$FIRST_ROOM_ID/seats" -H "$SH1" | python3 -c "import sys,json;d=json.load(sys.stdin);seats=[s for s in d.get('data',[]) if s['id']!=$FIRST_SEAT_ID];print(seats[0]['id'] if seats else '')" 2>/dev/null)
if [ -n "$ANOTHER_SEAT" ]; then
  RES=$(curl -s "$BASE/reservations" -X POST -H "Content-Type: application/json" -H "$SH1" -d "{\"seatId\":$ANOTHER_SEAT,\"date\":\"$TOMORROW\",\"startTime\":\"09:00\",\"endTime\":\"11:00\"}")
  CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
  [[ "$CODE" != "200" ]] && report "RES03" "PASS" "同时段多座位被拒绝" || report "RES03" "FAIL" "同时段不应预约多座位"
fi

# 取消预约
RES=$(curl -s "$BASE/reservations/$RES_ID/cancel" -X PUT -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RES04" "PASS" "取消预约" || report "RES04" "FAIL" "$RES"

# 再次预约
RES=$(curl -s "$BASE/reservations" -X POST -H "Content-Type: application/json" -H "$SH1" -d "{\"seatId\":$FIRST_SEAT_ID,\"date\":\"$TOMORROW\",\"startTime\":\"14:00\",\"endTime\":\"16:00\"}")
RES_ID2=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('id',''))" 2>/dev/null)

# 当前预约列表
RES=$(curl -s "$BASE/reservations/current" -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RES05" "PASS" "当前预约列表" || report "RES05" "FAIL" "code=$CODE"

# 历史预约列表
RES=$(curl -s "$BASE/reservations/history" -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RES06" "PASS" "历史预约列表" || report "RES06" "FAIL" "code=$CODE"

# 再次预约
RES=$(curl -s "$BASE/reservations/$RES_ID2/rebook" -X POST -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RES07" "PASS" "再次预约" || report "RES07" "FAIL" "$RES"

# 管理员全部预约
RES=$(curl -s "$BASE/admin/reservations" -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RES08" "PASS" "管理员全部预约" || report "RES08" "FAIL" "code=$CODE"

# 管理员取消
RES=$(curl -s "$BASE/admin/reservations/$RES_ID2/cancel" -X PUT -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RES09" "PASS" "管理员取消预约" || report "RES09" "FAIL" "$RES"

# ===== 5. 搜索模块 =====
echo -e "\n--- 5. 搜索模块 (A-SCH01) ---"

RES=$(curl -s "$BASE/seats/search?date=$TOMORROW&startTime=09:00&endTime=11:00" -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "SCH01" "PASS" "搜索可用座位" || report "SCH01" "FAIL" "$RES"

RES=$(curl -s "$BASE/seats/search?date=$TOMORROW&startTime=09:00&endTime=11:00&socketType=FIXED&position=WINDOW" -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "SCH02" "PASS" "多条件搜索" || report "SCH02" "FAIL" "$RES"

# ===== 6. 签到模块 =====
echo -e "\n--- 6. 签到模块 (A-CODE01, 签到) ---"

RES=$(curl -s "$BASE/admin/check-in-codes/$FIRST_ROOM_ID" -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
CHECKIN_CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" && -n "$CHECKIN_CODE" ]] && report "CODE01" "PASS" "获取签到编码: $CHECKIN_CODE" || report "CODE01" "FAIL" "$RES"

# ===== 7. 违约模块 =====
echo -e "\n--- 7. 违约模块 (A-VIO01/02) ---"

RES=$(curl -s "$BASE/violations/my" -H "$SH1")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "VIO01" "PASS" "学生违约记录" || report "VIO01" "FAIL" "$RES"

RES=$(curl -s "$BASE/admin/violations" -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "VIO02" "PASS" "管理员违约记录" || report "VIO02" "FAIL" "$RES"

# ===== 8. RBAC模块 =====
echo -e "\n--- 8. RBAC模块 (A-RBAC01~06) ---"

RES=$(curl -s "$BASE/admin/roles" -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RBAC01" "PASS" "角色列表" || report "RBAC01" "FAIL" "code=$CODE"

RES=$(curl -s "$BASE/admin/roles" -X POST -H "Content-Type: application/json" -H "$AH" -d '{"name":"测试角色","code":"test_role2","description":"测试用"}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
NEW_ROLE_ID=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('id',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RBAC02" "PASS" "创建角色" || report "RBAC02" "FAIL" "$RES"

RES=$(curl -s "$BASE/admin/roles/$NEW_ROLE_ID" -X PUT -H "Content-Type: application/json" -H "$AH" -d '{"name":"测试角色-更新","permissionIds":[1,2]}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RBAC03" "PASS" "更新角色" || report "RBAC03" "FAIL" "$RES"

RES=$(curl -s "$BASE/admin/roles/$NEW_ROLE_ID" -X DELETE -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RBAC04" "PASS" "删除角色" || report "RBAC04" "FAIL" "$RES"

RES=$(curl -s "$BASE/admin/roles/permissions" -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RBAC05" "PASS" "权限列表" || report "RBAC05" "FAIL" "code=$CODE"

RES=$(curl -s "$BASE/admin/users" -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RBAC06" "PASS" "用户列表" || report "RBAC06" "FAIL" "code=$CODE"

RES=$(curl -s "$BASE/admin/users/2/roles" -X PUT -H "Content-Type: application/json" -H "$AH" -d '{"roleIds":[2]}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "RBAC07" "PASS" "分配用户角色" || report "RBAC07" "FAIL" "$RES"

# 角色中文验证
ROLE_NAME=$(curl -s "$BASE/admin/roles" -H "$AH" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['data'][0]['name'] if d.get('data') and len(d['data'])>0 else '')" 2>/dev/null)
[[ "$ROLE_NAME" =~ [一-龥] ]] && report "RBAC08" "PASS" "角色中文名正常: $ROLE_NAME" || report "RBAC08" "FAIL" "中文异常: $ROLE_NAME"

# ===== 9. 系统参数 =====
echo -e "\n--- 9. 系统参数 (A-CONF01/02) ---"

RES=$(curl -s "$BASE/admin/config" -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "CONF01" "PASS" "获取系统参数" || report "CONF01" "FAIL" "code=$CODE"

RES=$(curl -s "$BASE/admin/config" -X PUT -H "Content-Type: application/json" -H "$AH" -d '{"max_reservation_hours":"4","check_in_remind_before_min":"15","check_in_warn_after_min":"10","check_in_cancel_after_min":"15"}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "CONF02" "PASS" "更新系统参数" || report "CONF02" "FAIL" "$RES"

# ===== 10. 统计模块 =====
echo -e "\n--- 10. 统计模块 (A-STAT01) ---"

RES=$(curl -s "$BASE/admin/dashboard" -H "$AH")
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "STAT01" "PASS" "仪表盘数据" || report "STAT01" "FAIL" "$RES"

# ===== 11. 智能助手 =====
echo -e "\n--- 11. 智能助手 (A-AI01) ---"

RES=$(curl -s "$BASE/assistant/chat" -X POST -H "Content-Type: application/json" -H "$SH1" -d '{"message":"你好"}')
CODE=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
INTENT=$(echo $RES | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('intent',''))" 2>/dev/null)
[[ "$CODE" = "200" ]] && report "AI01" "PASS" "智能助手接口正常 intent=$INTENT" || report "AI01" "FAIL" "$RES"

# ===== 汇总 =====
echo -e "\n=========================================="
echo "  测试结果汇总"
echo "=========================================="
echo "✅ 通过: $PASS"
echo "❌ 失败: $FAIL"
echo "总计: $((PASS+FAIL))"
if [ $FAIL -gt 0 ]; then
  echo -e "\n失败用例:"
  echo -e "$ISSUES"
fi
