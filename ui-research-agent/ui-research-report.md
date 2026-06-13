# UI Research Report — SeatFlow 前端 UI/UX 调研报告

## 执行摘要

SeatFlow 前端当前处于"功能可用但体感粗糙"的 MVP 阶段。核心问题集中在四个方面：①座位图为固定尺寸 div 网格，无移动端适配、无走廊通道概念、emoji 图标缺乏现代感；②管理端侧边栏不可折叠、无面包屑导航，仪表盘和表格页缺少数据密度优化；③学生端无底部导航栏、无移动端优先设计、预约流程缺乏步骤引导；④AI 助手无打字机动画、无结构化结果卡片、无历史记录。本报告基于电影院选座/飞机选座行业标杆、Ant Design Pro 最佳实践、主流 AI Chat UI 开源方案进行调研，输出可落地的分级改进方案（P0/P1/P2），供 Code Agent 直接参考实施。

---

## 一、座位图设计（SeatMap）

### 1.1 现状分析

**SeatMap.tsx 当前实现：**
- 纯 div 网格布局（64×48px 固定尺寸），使用绝对定位或 CSS grid
- 状态颜色：AVAILABLE(绿) / OCCUPIED(灰) / DISABLED(红)，纯靠背景色区分
- 座位属性标记使用 emoji（⚡🔌🪟🚶），视觉不统一
- hover 效果：`scale(1.05)` + `boxShadow`，较基础
- 使用 Ant Design Tooltip 显示详情
- 无移动端适配，无通道/分组概念，无缩放/拖拽能力
- 图例用内联 `<span>`，样式简陋

**核心问题：**
1. 固定像素尺寸在移动端无法使用
2. 色盲用户无法仅凭颜色区分座位状态（WCAG 不合规）
3. emoji 图标在不同平台上渲染不一致
4. 无走廊/通道区域，用户无法理解自习室真实空间布局
5. 缩放能力缺失，大型自习室（80+座位）难以浏览

### 1.2 行业标杆调研

**电影院选座（猫眼/淘票票/AMC）：**
- 采用 SVG/Canvas 渲染座位图，支持手势缩放（pinch-to-zoom）
- 座位形状为带圆角的梯形/弧形，模拟真实座椅朝向
- 走廊区域用留白 + 虚线分隔，屏幕/讲台用弧形标识
- 颜色 + 形状双重编码：可用(实心圆+绿)、已选(实心圆+蓝)、已售(叉号+灰)、障碍座(轮椅图标)
- 底部固定操作栏显示已选座位和总价

**飞机选座（SeatGuru/航司 App）：**
- 按区域分组（经济舱/商务舱），可折叠展开
- 走廊用灰色空白行表示，紧急出口用特殊标记
- 座位属性用 SVG icon 替代 emoji，hover 时放大展示详情
- 支持列表视图和座位图视图双模式切换

**SVG vs Div 渲染对比（seatmap.pro 调研）：**
| 方案 | 性能(100座) | 缩放质量 | 交互能力 | 推荐度 |
|---|---|---|---|---|
| HTML div | 快 | 模糊(像素) | 有限 | ★★ |
| SVG | 快 | 无损(矢量) | 丰富 | ★★★★★ |
| Canvas | 最快 | 无损 | 强但复杂 | ★★★★ |

**结论：** SeatFlow 的座位数通常 ≤80，SVG 是性价比最高的方案，保持 DOM 可访问性的同时支持高质量缩放。

### 1.3 落地改进方案

#### P0（必改）

**① SVG 替换 div 网格渲染**
- **文件：** `SeatMap.tsx`
- **改动：** 将 div grid 替换为 SVG `<svg>` 渲染，每个座位用 `<rect>` 或自定义 `<path>` 表示
- **具体实现：**
  ```tsx
  // SVG 座位元素示例
  <g transform={`translate(${x * seatWidth}, ${y * seatHeight})`}>
    <rect
      width={seatWidth - gap}
      height={seatHeight - gap}
      rx={6} ry={6}  // 圆角
      fill={statusColor}
      stroke={isSelected ? '#1677ff' : 'none'}
      strokeWidth={isSelected ? 2 : 0}
      className={`seat-seat ${status} ${hovered ? 'hovered' : ''}`}
    />
    {/* 属性图标用 SVG icon，不用 emoji */}
  </g>
  ```
- **优先级：** P0
- **改动量：** 中

**② 色盲友好的状态编码（颜色 + 形状/图标双重编码）**
- **文件：** `SeatMap.tsx` + CSS
- **改动：**
  - AVAILABLE：实心圆 + 绿色 `#52c41a` + 无边框
  - OCCUPIED：`×` 图标 + 灰色 `#d9d9d9`
  - DISABLED：`/` 斜线 + 红色 `#ff4d4f`
  - SELECTED：蓝色描边 `#1677ff` + 高亮填充 `#e6f4ff`
  - 图例用 `Ant Design Tag` 组件替代内联 span
- **WCAG 合规：** 颜色对比度 ≥ 4.5:1
- **优先级：** P0
- **改动量：** 小

**③ SVG icon 替代 emoji**
- **文件：** `SeatMap.tsx`
- **改动：** 使用 `@ant-design/icons` 或自定义 SVG：
  - ⚡ 电源 → `<ThunderboltOutlined />`（或自定义闪电 SVG）
  - 🔌 插座 → `<ThunderboltCircleOutlined />`
  - 🪟 靠窗 → `<WindowOutlined />`
  - 🚶 靠走道 → `<ApartmentOutlined />`
  - 图标尺寸 12×12px，放置在座位右上角
- **优先级：** P0
- **改动量：** 小

**④ 走廊/通道视觉划分**
- **文件：** `SeatMap.tsx`
- **改动：** 在数据模型中增加 `isAisle: boolean` 字段，渲染时在对应位置画一条灰色虚线 `<line stroke-dasharray="4,4" />`，或留出 2 倍 seatWidth 的空白间隙
- **具体方案：** 在座位网格中插入 aisle 行/列，render 为浅灰色背景 + 文字"走廊"标签（字号 10px，颜色 `#bfbfbf`）
- **优先级：** P0
- **改动量：** 中

#### P1（建议）

**⑤ 缩放和平移（pinch-to-zoom + drag pan）**
- **文件：** `SeatMap.tsx`
- **改动：** 引入 `react-zoom-pan-pinch`（npm 包）或自实现 SVG `<g transform="translate() scale()">` 方案
- **交互：** 桌面端支持鼠标滚轮缩放 + 拖拽平移；移动端支持双指缩放
- **缩放范围：** 0.5x ~ 3x
- **优先级：** P1
- **改动量：** 中

**⑥ 座位分组/区域标签**
- **文件：** `SeatMap.tsx`
- **改动：** 在 SVG 顶部渲染区域标签（如"A区 靠窗"、"B区 安静区"），使用 `<text>` 元素，字号 14px，加粗
- **背景：** 不同区域用极浅色背景区分（`#fafafa` / `#f0f5ff`）
- **优先级：** P1
- **改动量：** 小

**⑦ 讲台/屏幕标识**
- **文件：** `SeatMap.tsx`
- **改动：** 在座位图顶部渲染一个弧形 `<path>` 表示讲台/屏幕，标注"讲台"或"屏幕"文字，帮助理解朝向
- **CSS：** 弧度渐变背景，文字居中
- **优先级：** P1
- **改动量：** 小

#### P2（加分）

**⑧ 列表视图切换**
- **文件：** 新增 `SeatList.tsx`
- **改动：** 添加 `Segmented` 组件切换"座位图/列表"两种视图模式，列表视图用 Ant Design Table 展示座位信息，适合无障碍场景
- **优先级：** P2
- **改动量：** 大

**⑨ 已选座位底部操作栏**
- **文件：** 新增 `SelectedSeatBar.tsx`
- **改动：** 底部固定 `Affix` 组件，显示已选座位标签 + "确认预约"按钮，类似电影院选座体验
- **优先级：** P2
- **改动量：** 中

---

## 二、管理端 UI/UX

### 2.1 现状分析

**AdminLayout.tsx 当前实现：**
- Ant Design Layout：Header + Sider(200px 固定) + Content
- Header：深色背景，左侧 Logo，右侧用户名+退出按钮
- Sider：白色主题，Menu 列表，按权限过滤菜单项（已实现）
- **缺失：** 无折叠功能、无面包屑、无仪表盘统计卡片、表格操作列无统一规范

### 2.2 调研发现

**Ant Design Pro 最佳实践（ant.design + pro.ant.design）：**
- 侧边栏：支持 `collapsible` 属性，collapsedWidth 默认 80px，可设置 0 完全隐藏
- 面包屑：使用 `<Breadcrumb>` + React Router 自动匹配，或 `<ProLayout>` 自带面包屑
- 仪表盘：Ant Design ProComponents 提供 `<StatisticCard>` 组件，支持指标数字 + 趋势图表
- 表格：`<ProTable>` 提供搜索、筛选、批量操作、行内编辑等开箱即用功能

**主流 Admin 模板对比（Muse Ant Design Dashboard / AntD Multi-Purpose Dashboard）：**
- 统计卡片采用 4 列 Grid 布局，每张卡片包含：图标 + 数值 + 标签 + 趋势箭头
- 表格操作列使用 `Dropdown` + `Popconfirm` 组合，减少按钮数量
- 暗色模式支持通过 Ant Design ConfigProvider 的 `theme` 属性实现

### 2.3 落地改进方案

#### 2.3.1 侧边栏优化

**① 侧边栏折叠/展开**
- **文件：** `AdminLayout.tsx`
- **改动：**
  ```tsx
  const [collapsed, setCollapsed] = useState(false);
  <Layout.Sider
    collapsible
    collapsed={collapsed}
    onCollapse={setCollapsed}
    collapsedWidth={80}
    theme="light"
  >
    <Menu ... />
  </Layout.Sider>
  ```
  - 折叠时仅显示图标（需为每个 Menu.Item 配置 icon 属性）
  - 使用 Ant Design 内置 `MenuUnfoldOutlined` / `MenuFoldOutlined` 作为折叠触发按钮
  - 折叠状态存入 localStorage，刷新后保持
- **优先级：** P0
- **改动量：** 小

**② 面包屑导航**
- **文件：** 新建 `BreadcrumbNav.tsx`，嵌入 `AdminLayout.tsx` 的 Content 顶部
- **改动：**
  ```tsx
  import { Breadcrumb } from 'antd';
  import { useLocation } from 'react-router-dom';

  const breadcrumbNameMap: Record<string, string> = {
    '/admin/dashboard': '仪表盘',
    '/admin/rooms': '自习室管理',
    '/admin/users': '用户管理',
    '/admin/bookings': '预约管理',
    '/admin/settings': '系统设置',
  };

  const BreadcrumbNav = () => {
    const location = useLocation();
    const pathSnippets = location.pathname.split('/').filter(Boolean);
    const items = pathSnippets.map((_, index) => {
      const url = `/${pathSnippets.slice(0, index + 1).join('/')}`;
      return { title: breadcrumbNameMap[url] || '未知' };
    });
    return <Breadcrumb items={[{ title: '首页' }, ...items]} />;
  };
  ```
- **优先级：** P0
- **改动量：** 小

#### 2.3.2 仪表盘优化

**③ 统计卡片布局**
- **文件：** 新建 `AdminDashboard.tsx`（或改造现有 Dashboard）
- **改动：** 使用 Ant Design `<Row>` + `<Col>` 4 列布局，每张卡片用 `<Card>` 包裹：
  ```tsx
  <Row gutter={[16, 16]}>
    <Col span={6}>
      <Card hoverable>
        <Statistic
          title="今日预约"
          value={todayBookings}
          prefix={<CalendarOutlined />}
          valueStyle={{ color: '#1677ff' }}
        />
      </Card>
    </Col>
    {/* 重复 4 个指标卡片 */}
  </Row>
  ```
  - 建议指标：今日预约数、在线人数、空闲座位率、本月累计预约
  - 卡片 hover 时有轻微阴影提升
  - 卡片下方可接 ECharts/Ant Design Charts 的折线图（7日预约趋势）
- **优先级：** P0
- **改动量：** 中

**④ 图表区域**
- **文件：** `AdminDashboard.tsx`
- **改动：** 添加 `@ant-design/charts` 折线图 + 饼图：
  - 上方：7日预约趋势折线图（24px 高度）
  - 下方：各自习室预约占比饼图 + 时段分布柱状图（左右各占 Col span={12}）
- **优先级：** P1
- **改动量：** 中

#### 2.3.3 表格页面优化

**⑤ 表格操作列统一规范**
- **文件：** 所有管理端表格页面（UsersTable / BookingsTable / RoomsTable）
- **改动：**
  - 操作列宽度固定 120px
  - 使用 `<Space>` 包裹操作按钮，间距 8px
  - 删除操作用 `<Popconfirm>` 二次确认
  - 多于 2 个操作时，第二个及以后的操作收入 `<Dropdown>`
  ```tsx
  const actions = (record: any) => (
    <Space>
      <Button type="link" size="small" onClick={() => handleEdit(record)}>编辑</Button>
      <Popconfirm title="确认删除？" onConfirm={() => handleDelete(record.id)}>
        <Button type="link" size="small" danger>删除</Button>
      </Popconfirm>
    </Space>
  );
  ```
- **优先级：** P0
- **改动量：** 小

**⑥ 表格搜索/筛选栏**
- **文件：** 所有管理端表格页面
- **改动：** 在 Table 上方添加 `<Input.Search>` + `<Select>` 筛选栏，用 `<Flex gap="middle">` 包裹，与表格间距 16px
- **优先级：** P1
- **改动量：** 小

---

## 三、学生端 UI/UX

### 3.1 现状分析

**StudentLayout.tsx 当前实现：**
- Header 横向导航（Menu horizontal + dark 主题）
- 内容区 padding 24px
- **缺失：** 无底部导航栏、无移动端适配、无步骤引导、空状态/加载状态不友好

### 3.2 调研发现

**Material Design 底部导航规范（m2.material.io）：**
- 底部导航栏适用于 3-5 个顶级目标
- 桌面端隐藏，移动端（<768px）显示
- 激活态：图标 + 文字 + 主题色指示条
- 非激活态：灰色图标 + 文字

**Ant Design Mobile 方案：**
- Ant Design Mobile 提供 `<TabBar>` 组件，与桌面端 Ant Design 风格统一
- 也可使用 Ant Design 桌面端 + CSS media query 实现响应式切换

**预约流程步骤化（NN/g 研究）：**
- 多步骤流程应使用 `<Steps>` 组件提供进度反馈
- 每个步骤应有明确的标题和描述
- 当前步骤高亮，已完成步骤显示 ✓

### 3.3 落地改进方案

#### 3.3.1 布局与导航

**① 响应式底部 Tab Bar（移动端）**
- **文件：** `StudentLayout.tsx`
- **改动：**
  ```tsx
  import { Layout, Menu } from 'antd';
  import { useMediaQuery } from 'react-responsive'; // 或使用 CSS media query

  const isMobile = window.innerWidth <= 768;

  // 桌面端：保持顶部横向 Menu
  // 移动端：隐藏 Header Menu，底部显示 TabBar
  {isMobile ? (
    <TabBar
      items={[
        { key: 'home', icon: <HomeOutlined />, label: '首页' },
        { key: 'booking', icon: <CalendarOutlined />, label: '预约' },
        { key: 'my', icon: <UserOutlined />, label: '我的' },
      ]}
    />
  ) : (
    <Menu mode="horizontal" theme="dark" ... />
  )}
  ```
  - 使用 CSS `@media (max-width: 768px)` 替代 JS 判断更佳（避免 hydration mismatch）
  - TabBar 高度 56px，固定底部（position: fixed）
  - 激活态图标颜色：`#1677ff`，非激活态：`#8c8c8c`
- **优先级：** P0
- **改动量：** 中

**② 自习室卡片信息密度优化**
- **文件：** 自习室列表页面组件（如 `RoomList.tsx`）
- **改动：**
  - 使用 `<Card.Grid>` 或 Masonry 布局展示自习室卡片
  - 每张卡片包含：封面图 + 名称 + 地址 + 空闲座位数（Tag 形式） + 评分
  - 桌面端 3 列，平板 2 列，移动端 1 列
  - hover 时卡片轻微上浮（translateY(-4px)）+ 阴影加深
  ```tsx
  <Card
    hoverable
    cover={<img alt={room.name} src={room.coverUrl} />}
  >
    <Card.Meta
      title={room.name}
      description={
        <Space direction="vertical" size={4}>
          <Text type="secondary"><EnvironmentOutlined /> {room.location}</Text>
          <Tag color={available > 0 ? 'green' : 'red'}>
            {available > 0 ? `空闲 ${available} 座` : '已满'}
          </Tag>
        </Space>
      }
    />
  </Card>
  ```
- **优先级：** P0
- **改动量：** 中

#### 3.3.2 预约流程

**③ 预约步骤引导（Steps）**
- **文件：** 预约流程页面组件（或新建 `BookingWizard.tsx`）
- **改动：** 使用 Ant Design `<Steps>` 组件，3 步流程：
  1. 选择自习室 → 2. 选择座位和时间 → 3. 确认预约
  - Steps 放在页面顶部，当前步骤高亮蓝色
  - 每步之间用 `<Divider />` 或留白分隔
  - 支持"上一步"按钮回退
  - 完成后展示 `<Result status="success">` 页面
- **优先级：** P0
- **改动量：** 中

**④ 空状态/加载状态优化**
- **文件：** 各列表/内容页面
- **改动：**
  - 加载态：使用 Ant Design `<Skeleton>` 替代纯 Spin，展示卡片骨架屏
  - 空状态：使用 `<Empty description="暂无数据" image={Empty.PRESENTED_IMAGE_SIMPLE} />`，附带操作按钮（如"去预约"）
  ```tsx
  if (loading) return <Skeleton active paragraph={{ rows: 4 }} />;
  if (rooms.length === 0) return (
    <Empty
      description="暂无可预约的自习室"
      image={Empty.PRESENTED_IMAGE_SIMPLE}
    >
      <Button type="primary" onClick={() => navigate('/home')}>返回首页</Button>
    </Empty>
  );
  ```
- **优先级：** P0
- **改动量：** 小

#### 3.3.3 移动端适配

**⑤ 全局响应式布局**
- **文件：** `StudentLayout.tsx` + 全局 CSS
- **改动：**
  - 内容区 padding：桌面端 24px → 移动端 12px
  - 表格：移动端隐藏次要列（如 ID、创建时间），仅保留核心信息
  - 表单：移动端 `<Form>` 改为纵向排列（`layout="vertical"`）
  - Modal/Drawer：移动端用 `<Drawer>` 替代 `<Modal>`，从底部滑出
  - 文字大小：移动端最小 14px，按钮最小高度 44px（iOS 触控标准）
- **优先级：** P1
- **改动量：** 中

**⑥ 自习室地图全屏模式（移动端）**
- **文件：** `SeatMap.tsx`
- **改动：** 移动端检测到小屏幕时，座位图自动进入全屏模式（隐藏 Header 和 TabBar），使用 `react-zoom-pan-pinch` 支持手势操作
- **优先级：** P2
- **改动量：** 中

---

## 四、AI 助手界面

### 4.1 现状分析

**Assistant.tsx 当前实现：**
- Card 容器，高度 `calc(100vh - 220px)`
- 消息气泡：用户蓝色右对齐，AI 灰色左对齐，Avatar + 气泡布局
- 4个快捷操作 Button（圆角16px chip 样式）
- loading 状态：Spin 图标 + "思考中..."
- **缺失：** 无打字机动画、无结构化结果卡片、无历史记录、无清空对话、无错误兜底

### 4.2 调研发现（主流方案对比）

**ChatGPT / Claude / Kimi 界面模式：**
| 方案 | 布局 | 适用场景 | 复杂度 |
|---|---|---|---|
| 全屏聊天（ChatGPT） | 占满视区，左侧会话列表 | 独立 AI 页面 | 中 |
| 侧边抽屉（Notion AI） | 右侧滑出，占屏 40-50% | 辅助工具 | 小 |
| 悬浮球（Intercom） | 右下角浮动按钮，点击展开 | 客服支持 | 小 |
| 内嵌页面（SeatFlow 当前） | 页面内 Card 容器 | 集成到现有页面 | 小 |

**结论：** 对于 SeatFlow 的学生端场景，**内嵌页面 + 全屏模式切换** 是最佳选择。管理端适合**侧边抽屉**方案（不脱离管理上下文）。

**打字机动效实现（React）：**
- 方案 A：`useEffect` + `setTimeout` 逐字渲染（最轻量，无依赖）
- 方案 B：`react-typed` / `react-typewriter-effect` npm 包（功能丰富）
- 方案 C：SSE 流式响应直接渲染（最真实，需后端支持 SSE）
- 推荐方案 A（纯前端实现，无需后端改造）

**结构化结果渲染：**
- ChatGPT 使用 code block / table / card 等结构化渲染
- prompt-kit 开源方案提供 `<ChatMessage>` 组件，支持 Markdown 渲染
- 推荐：`react-markdown` + `remark-gfm` 解析 Markdown 格式响应

### 4.3 落地改进方案

#### P0（必改）

**① 打字机动效（Typewriter Effect）**
- **文件：** `Assistant.tsx`
- **改动：** 创建 `TypewriterText` 组件：
  ```tsx
  const TypewriterText = ({ text, speed = 15 }: { text: string; speed?: number }) => {
    const [visibleLength, setVisibleLength] = useState(0);
    useEffect(() => {
      if (visibleLength < text.length) {
        const timer = setTimeout(() => setVisibleLength(prev => prev + 1), speed);
        return () => clearTimeout(timer);
      }
    }, [visibleLength, text.length, speed]);
    return <>{text.substring(0, visibleLength)}{visibleLength < text.length && <span className="cursor-blink" />}</>;
  };
  ```
  - CSS：`.cursor-blink { display: inline-block; width: 2px; height: 1em; background: currentColor; animation: blink 1s step-end infinite; }`
  - AI 消息使用 `<TypewriterText text={message.content} />`
  - 用户消息不带动画（直接显示）
- **优先级：** P0
- **改动量：** 小

**② Markdown 结构化渲染**
- **文件：** `Assistant.tsx`
- **改动：** 引入 `react-markdown` + `remark-gfm`
  ```tsx
  import ReactMarkdown from 'react-markdown';
  import remarkGfm from 'remark-gfm';

  // AI 消息渲染
  <div className="ai-message">
    <Avatar icon={<RobotOutlined />} />
    <div className="message-bubble ai-bubble">
      <ReactMarkdown remarkPlugins={[remarkGfm]}>
        {message.content}
      </ReactMarkdown>
    </div>
  </div>
  ```
  - 表格、列表、代码块自动渲染
  - 针对 SeatFlow 场景：AI 返回的座位推荐列表渲染为 `<Card>` 或 `<List>` 组件（需在 markdown 中约定特殊语法或用自定义 renderer）
- **优先级：** P0
- **改动量：** 小

**③ 错误/无结果友好兜底**
- **文件：** `Assistant.tsx`
- **改动：**
  - API 错误时显示 `<Alert type="error" message="AI 服务暂时不可用，请稍后重试" />`，底部保留快捷按钮
  - 无匹配结果时：`<Empty description="抱歉，没有找到符合条件的座位" image={Empty.PRESENTED_IMAGE_SIMPLE}>`，附带"换个条件试试"按钮
  - 网络超时：显示 `<Result status="warning" title="请求超时" subTitle="请检查网络连接后重试" />`
- **优先级：** P0
- **改动量：** 小

**④ 快捷 Chip 问题优化**
- **文件：** `Assistant.tsx`
- **改动：**
  - 将 4 个 Button 改为 `<Tag.CheckableTag>` 或自定义 chip 样式
  - Chip 样式：`border-radius: 20px`，`padding: 6px 16px`，`font-size: 13px`，`border: 1px solid #d9d9d9`
  - hover 时：背景色 `#f0f0f0`，无边框
  - 点击后 chip 变为 loading 态（`<Spin size="small" />`），直到 AI 响应返回
  - 问题文案优化（示例）：
    - "帮我找个靠窗的座位"
    - "明天上午有空位吗？"
    - "哪个自习室人最少？"
    - "我之前的预约"
- **优先级：** P0
- **改动量：** 小

#### P1（建议）

**⑤ 对话历史记录**
- **文件：** `Assistant.tsx` 或新建 `ChatHistory.tsx`
- **改动：**
  - 使用 localStorage 存储最近 20 条对话
  - 页面顶部添加 `<Select>` 下拉选择历史会话
  - 每条历史记录显示：时间 + 首条问题摘要（截断 30 字）
  - 添加"清空对话"按钮（带 Popconfirm）
- **优先级：** P1
- **改动量：** 中

**⑥ 思考中加载动画优化**
- **文件：** `Assistant.tsx`
- **改动：** 将 `Spin` + "思考中..." 替换为三点跳动动画：
  ```tsx
  const ThinkingDots = () => (
    <span className="thinking-dots">
      <span className="dot" />
      <span className="dot" />
      <span className="dot" />
    </span>
  );
  ```
  - CSS：三个圆点依次放大缩小动画，间隔 200ms
  - AI 消息气泡内显示，左侧 Avatar 保持
- **优先级：** P1
- **改动量：** 小

#### P2（加分）

**⑦ 结构化座位推荐卡片**
- **文件：** `Assistant.tsx`
- **改动：** 当 AI 返回座位推荐时（通过约定 JSON 格式或 Markdown table），渲染为 Ant Design `<Card>` 卡片列表：
  ```tsx
  // 自定义 markdown renderer
  const components = {
    table: ({ children }) => <Table dataSource={parseTable(children)} columns={seatColumns} pagination={false} size="small" />,
  };
  <ReactMarkdown components={components}>{message.content}</ReactMarkdown>
  ```
  - 每张座位卡片包含：座位号、区域、属性标签（电源/靠窗/靠走道）、预约按钮
- **优先级：** P2
- **改动量：** 大

**⑧ 悬浮球入口（学生端首页）**
- **文件：** `StudentLayout.tsx` 或新建 `AIFloatButton.tsx`
- **改动：** 在首页右下角添加 Ant Design `<FloatButton>`，点击后弹出 Drawer（从右侧滑出，宽度 400px，移动端 100% 宽度），内嵌 Assistant 组件
- **优先级：** P2
- **改动量：** 中

---

## 五、综合优先级汇总

| 改进点 | 方向 | 优先级 | 改动量 | 预期效果 |
|---|---|---|---|---|
| SVG 替换 div 网格渲染 | 座位图 | P0 | 中 | 支持缩放、高质量渲染、可访问性 |
| 色盲友好状态编码 | 座位图 | P0 | 小 | WCAG 合规，状态识别更可靠 |
| SVG icon 替代 emoji | 座位图 | P0 | 小 | 视觉统一，跨平台一致 |
| 走廊/通道视觉划分 | 座位图 | P0 | 中 | 空间布局理解更直观 |
| 侧边栏折叠/展开 | 管理端 | P0 | 小 | 节省屏幕空间，操作效率提升 |
| 面包屑导航 | 管理端 | P0 | 小 | 层级定位清晰，减少迷失 |
| 统计卡片仪表盘 | 管理端 | P0 | 中 | 数据概览一目了然 |
| 表格操作列规范 | 管理端 | P0 | 小 | 操作一致性，减少误操作 |
| 预约步骤引导（Steps） | 学生端 | P0 | 中 | 降低预约操作门槛 |
| 空状态/加载状态优化 | 学生端 | P0 | 小 | 提升等待和空数据体验 |
| 自习室卡片信息密度 | 学生端 | P0 | 中 | 信息展示更高效 |
| 打字机动效 | AI助手 | P0 | 小 | AI 体感提升，等待焦虑降低 |
| Markdown 结构化渲染 | AI助手 | P0 | 小 | 结果可读性大幅提升 |
| 错误兜底 | AI助手 | P0 | 小 | 异常情况不再白屏 |
| 快捷 chip 优化 | AI助手 | P0 | 小 | 交互更轻量自然 |
| 缩放/平移 | 座位图 | P1 | 中 | 大屏/小屏都好用 |
| 座位分组/区域标签 | 座位图 | P1 | 小 | 大自习室导航更高效 |
| 讲台/屏幕标识 | 座位图 | P1 | 小 | 朝向理解更直观 |
| 仪表盘图表 | 管理端 | P1 | 中 | 趋势分析可视化 |
| 表格搜索/筛选栏 | 管理端 | P1 | 小 | 数据查找效率提升 |
| 移动端底部 Tab Bar | 学生端 | P0 | 中 | 移动端导航体验 |
| 全局响应式布局 | 学生端 | P1 | 中 | 移动端可用 |
| 对话历史记录 | AI助手 | P1 | 中 | 上下文连续性 |
| 思考中加载动画 | AI助手 | P1 | 小 | 等待体感更流畅 |
| 列表视图切换 | 座位图 | P2 | 大 | 无障碍 + 不同偏好支持 |
| 已选座位底部栏 | 座位图 | P2 | 中 | 选座流程更清晰 |
| 结构化座位推荐卡片 | AI助手 | P2 | 大 | 结果可操作性提升 |
| 悬浮球 AI 入口 | AI助手 | P2 | 中 | 随时可唤起的 AI 助手 |

---

## 六、参考资源清单

### 座位图设计
1. **Seatmap.pro — Seating Plan Rendering: SVG vs Canvas vs WebGL** — https://seatmap.pro/blog/seating-plan-rendering/
2. **Creating an accessible seat map for public transportation (Medium)** — https://medium.com/@manuelsuricastro/creating-an-accessible-seat-map-for-public-transportation-using-data-grid-142884cb8115
3. **UX StackExchange — Color-coded seat map for colorblind users** — https://ux.stackexchange.com/questions/114438/
4. **react-seat-select (npm)** — https://classic.yarnpkg.com/en/package/react-seat-select
5. **React Seat Toolkit** — https://madewithreactjs.com/react-seat-toolkit
6. **How to Build a Movie Theater Seat Booking UI (Stackademic)** — https://blog.stackademic.com/how-to-build-a-movie-theater-seat-booking-ui-with-react-and-tailwind-css-c1b81692ae3b
7. **WCAG Color Contrast — WebAIM** — https://webaim.org/articles/contrast/
8. **react-zoom-pan-pinch (npm)** — https://www.npmjs.com/package/react-zoom-pan-pinch

### 管理端 UI/UX
9. **Ant Design Layout 组件文档** — https://ant.design/components/layout/
10. **Ant Design Breadcrumb 组件文档** — https://ant.design/components/breadcrumb/
11. **Ant Design ProComponents StatisticCard** — https://procomponents.ant.design/en-US/components/statistic-card/
12. **Muse Ant Design Dashboard (GitHub)** — https://github.com/creativetimofficial/muse-ant-design-dashboard
13. **Ant Design Visualization Page Spec** — https://ant.design/docs/spec/visualization-page/
14. **Refine — Ant Design Breadcrumb Best Practices** — https://refine.dev/core/docs/ui-integrations/ant-design/components/breadcrumb/

### 学生端 UI/UX
15. **Material Design Bottom Navigation** — https://m2.material.io/components/bottom-navigation
16. **Bottom Tab Bar Design Best Practices (Nick Babich)** — https://babich.biz/blog/bottom-tab-bar-design/
17. **UX Planet — Bottom Tab Bar Navigation Design Best Practices** — https://uxplanet.org/bottom-tab-bar-navigation-design-best-practices-48d46a3b0c36
18. **Ant Design Steps 组件文档** — https://ant.design/components/steps/
19. **Ant Design Empty 组件文档** — https://ant.design/components/empty/
20. **Ant Design Skeleton 组件文档** — https://ant.design/components/skeleton/

### AI 助手界面
21. **Eleken — 32 Chatbot UI Examples** — https://www.eleken.co/blog-posts/chatbot-ui-examples
22. **Prompt-Kit — Chat UI Components for React AI Apps** — https://prompt-kit.com/chat-ui
23. **assistant-ui (GitHub)** — https://github.com/assistant-ui/assistant-ui
24. **Typewriter Effect like ChatGPT with React (DEV.to)** — https://dev.to/duoc95/type-writer-effect-like-chatgpt-with-react-5ae1
25. **shadcn.io — Typing Text** — https://www.shadcn.io/text/typing-text
26. **react-markdown (npm)** — https://www.npmjs.com/package/react-markdown
27. **remark-gfm (npm)** — https://www.npmjs.com/package/remark-gfm

### 技术栈参考
28. **Ant Design v5 组件全览** — https://ant.design/components/overview
29. **Ant Design ConfigProvider 主题定制** — https://ant.design/docs/react/customize-theme

---

> **调研完成时间：** 2026-06-13 20:00 (Asia/Shanghai)
>
> **调研 Agent：** OpenClaw UI Research Agent
>
> **报告版本：** v1.0
