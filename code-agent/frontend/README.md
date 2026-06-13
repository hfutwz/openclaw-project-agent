# SeatFlow 前端

> 自习座位预约系统 — React 前端应用

## 技术栈

| 技术 | 版本 | 说明 |
|---|---|---|
| React | 19.1 | UI 框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 6.3 | 构建工具 |
| Ant Design | 5.25 | UI 组件库 |
| React Router | 6.x | 路由管理 |
| Axios | — | HTTP 请求 + 拦截器 |

## 项目结构

```
src/
├── App.tsx                    # 路由配置 + 路由守卫（未登录跳登录/权限不足跳403）
├── main.tsx                   # 应用入口
│
├── layouts/
│   ├── StudentLayout.tsx      # 学生端布局（顶栏 + 内容区）
│   └── AdminLayout.tsx        # 管理端布局（顶栏 + 权限侧边栏 + 内容区）
│
├── pages/
│   ├── Login.tsx              # 登录页（按 userType 跳转：admin → 管理端，student → 学生端）
│   ├── Forbidden.tsx          # 403 权限不足页
│   ├── NotFound.tsx           # 404 页
│   │
│   ├── student/               # 学生端页面
│   │   ├── RoomList.tsx           # US-S01：自习室列表（卡片展示）
│   │   ├── RoomDetailPage.tsx     # US-S02：自习室详情 + 座位图
│   │   ├── MyReservations.tsx     # US-S03/S07/S09：我的预约（当前/历史/取消）
│   │   ├── CheckInPage.tsx        # US-S04：签到（输入编码）
│   │   ├── Search.tsx             # US-S08：多条件搜索座位
│   │   ├── MyViolations.tsx       # US-S10：我的违约记录
│   │   └── Assistant.tsx          # US-S11：智能助手聊天框
│   │
│   └── admin/                 # 管理端页面
│       ├── Dashboard.tsx          # US-A03：统计仪表盘（图表）
│       ├── RoomManage.tsx         # US-A01：自习室管理（CRUD）
│       ├── SeatManage.tsx         # US-A02：座位管理（CRUD + 状态）
│       ├── ReservationManage.tsx  # US-A04：预约管理（列表 + 代约/取消）
│       ├── CheckInCodeManage.tsx  # 签到码查看（按教室/当日）
│       ├── ViolationManage.tsx    # 违约管理（全局列表）
│       ├── UserManage.tsx         # US-A05：用户管理（角色分配）
│       ├── RoleManage.tsx         # US-A05：角色管理（权限勾选）
│       └── SystemConfigPage.tsx   # US-A06：系统参数配置
│
├── components/
│   └── SeatMap/
│       └── SeatMap.tsx        # 座位图组件（网格布局/状态颜色/属性标记/点击选座）
│
├── hooks/
│   ├── useAuth.ts             # 当前用户信息（从 localStorage 读取）
│   └── usePermissions.ts      # 权限判断（hasPermission / isAdmin）
│
└── services/                  # API 封装层（Axios）
    ├── api.ts                 # Axios 实例 + 拦截器（自动附 JWT / 401 跳登录）
    ├── auth.ts                # 登录 / 获取当前用户
    ├── room.ts                # 自习室相关接口
    ├── reservation.ts         # 预约相关接口
    ├── checkin.ts             # 签到接口
    ├── search.ts              # 搜索接口
    ├── violation.ts           # 违约接口
    ├── assistant.ts           # 智能助手接口
    └── admin.ts               # 管理端所有接口
```

## 核心功能

### 路由与权限守卫
- 未登录 → 自动跳转 `/login`
- 学生账号无法访问 `/admin/*` 路由（跳转 403）
- 管理端侧边栏按当前用户权限动态渲染（无该权限的菜单项隐藏）

### 学生端（US-S01 ~ US-S11）
| 用户故事 | 页面 | 核心交互 |
|---|---|---|
| US-S01 | 自习室列表 | 卡片展示：名称/位置/开放时间/空座数 |
| US-S02 | 自习室详情 + 座位图 | 网格座位图，可用(绿)/已占(灰)/停用(红)，点击选座 |
| US-S03 | 预约时间选择弹窗 | 整点选择，≤4h 限制，冲突实时提示 |
| US-S04 | 签到页 | 输入6位编码，成功/失败即时反馈 |
| US-S07 | 我的预约 - 当前 | 取消按钮（已超时自动取消不显示） |
| US-S08 | 搜索页 | 多条件表单（日期/时段/插座/位置），结果列表可预约 |
| US-S09 | 我的预约 - 历史 | 一键再次预约（自动检测时段是否可用） |
| US-S10 | 违约记录 | 列表展示时间/座位/原因 |
| US-S11 | 智能助手 | 聊天气泡，自然语言查询/预约/取消 |

### 管理端（US-A01 ~ US-A06）
| 用户故事 | 页面 | 核心交互 |
|---|---|---|
| US-A01 | 自习室管理 | 表格 + 新增/编辑弹窗 + 启停/删除 |
| US-A02 | 座位管理 | 座位列表 + 新增/编辑/停用 |
| US-A03 | 仪表盘 | 预约率/签到率/违约率/自习室利用率图表 |
| US-A04 | 预约管理 | 全局列表 + 代客预约弹窗 + 取消操作 |
| US-A05 | 用户管理 + 角色管理 | 角色 CRUD + 权限勾选 + 用户角色绑定 |
| US-A06 | 系统参数 | KV 参数列表，修改即时生效 |

### 座位图组件（SeatMap）
- 网格布局按行列渲染座位
- 状态颜色：🟢 可选 / ⬜ 已占 / 🔴 停用 / 🔵 我的预约
- 属性标记：⚡ 有插座 / 🪟 靠窗 / 🚶 靠走廊
- Hover tooltip 显示座位详情
- 点击可选状态座位触发预约流程

## 快速启动

```bash
# 安装依赖（仅用 pnpm）
pnpm install

# 开发模式启动
pnpm dev
# 访问：http://localhost:5173

# 生产构建
pnpm build

# 构建产物在 dist/ 目录
```

> **注意：** 开发时后端需在 `http://localhost:8081` 运行，Vite 已配置代理。

## 默认账号

| 账号 | 密码 | 角色 | 登录后跳转 |
|---|---|---|---|
| admin | admin123 | 管理员 | `/admin/dashboard` |
| student1 | student123 | 学生 | `/student/rooms` |
| student2 | student123 | 学生 | `/student/rooms` |
