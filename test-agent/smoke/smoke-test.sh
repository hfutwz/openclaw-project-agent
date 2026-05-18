#!/bin/bash
# SeatFlow M1 冒烟测试脚本
# 验证核心服务启动和关键API可达性

set -e

BACKEND_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:5173"

echo "=========================================="
echo "  SeatFlow M1 冒烟测试"
echo "=========================================="
echo ""

PASS=0
FAIL=0

check() {
    local desc="$1"
    local cmd="$2"
    echo -n "  Testing: $desc ... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo "✅ PASS"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL"
        FAIL=$((FAIL + 1))
    fi
}

echo "--- 后端服务检查 ---"
check "后端服务启动" "curl -s -o /dev/null -w '%{http_code}' $BACKEND_URL/api/auth/me | grep -qE '401|403'"

echo ""
echo "--- 登录接口检查 ---"
check "登录接口可达" "curl -s -X POST $BACKEND_URL/api/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"admin123\"}' | grep -q token"

echo ""
echo "--- 受保护接口检查 ---"
check "未认证访问返回401/403" "curl -s -o /dev/null -w '%{http_code}' $BACKEND_URL/api/auth/me | grep -qE '401|403'"

echo ""
echo "--- 前端服务检查 ---"
check "前端服务启动" "curl -s -o /dev/null -w '%{http_code}' $FRONTEND_URL | grep -q 200"

echo ""
echo "=========================================="
echo "  结果: $PASS 通过, $FAIL 失败"
echo "=========================================="

if [ $FAIL -gt 0 ]; then
    exit 1
fi
