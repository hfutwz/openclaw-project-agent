import React from 'react'
import { Layout, Menu, Button, Typography, Space } from 'antd'
import { Outlet, useNavigate, useLocation } from 'react-router-dom'
import {
  DashboardOutlined,
  HomeOutlined,
  CalendarOutlined,
  WarningOutlined,
  TeamOutlined,
  SafetyOutlined,
  SettingOutlined,
  KeyOutlined,
  LogoutOutlined,
  UserOutlined
} from '@ant-design/icons'
import { useAuth } from '../hooks/useAuth'
import { usePermissions } from '../hooks/usePermissions'

const { Header, Sider, Content } = Layout

const AdminLayout: React.FC = () => {
  const { userInfo, logout } = useAuth()
  const { hasPermission } = usePermissions()
  const navigate = useNavigate()
  const location = useLocation()

  const allMenuItems = [
    { key: '/admin/dashboard', icon: <DashboardOutlined />, label: '仪表盘', permission: 'reservation:view' },
    { key: '/admin/rooms', icon: <HomeOutlined />, label: '自习室管理', permission: 'room:manage' },
    { key: '/admin/seats', icon: <HomeOutlined />, label: '座位管理', permission: 'seat:manage' },
    { key: '/admin/reservations', icon: <CalendarOutlined />, label: '预约管理', permission: 'reservation:view' },
    { key: '/admin/violations', icon: <WarningOutlined />, label: '违约管理', permission: 'violation:view' },
    { key: '/admin/users', icon: <TeamOutlined />, label: '用户管理', permission: 'user:manage' },
    { key: '/admin/roles', icon: <SafetyOutlined />, label: '角色管理', permission: 'role:manage' },
    { key: '/admin/config', icon: <SettingOutlined />, label: '系统参数', permission: 'system:config' },
    { key: '/admin/check-in-codes', icon: <KeyOutlined />, label: '签到编码', permission: 'room:manage' },
  ]

  // 按权限过滤菜单
  const menuItems = allMenuItems.filter(item => hasPermission(item.permission))

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 24px' }}>
        <Typography.Title level={4} style={{ color: '#fff', margin: 0 }}>
          🪑 SeatFlow 管理端
        </Typography.Title>
        <Space>
          <span style={{ color: '#fff' }}>
            <UserOutlined /> {userInfo?.realName || userInfo?.username}
          </span>
          <Button type="text" icon={<LogoutOutlined />} onClick={logout} style={{ color: '#fff' }}>
            退出
          </Button>
        </Space>
      </Header>
      <Layout>
        <Sider width={200} theme="light">
          <Menu
            mode="inline"
            selectedKeys={[location.pathname]}
            items={menuItems}
            onClick={({ key }) => navigate(key)}
            style={{ height: '100%', borderRight: 0 }}
          />
        </Sider>
        <Content style={{ padding: '24px', margin: 0, minHeight: 280 }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  )
}

export default AdminLayout
