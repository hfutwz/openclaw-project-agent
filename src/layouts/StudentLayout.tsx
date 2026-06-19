import React from 'react'
import { Layout, Menu, Button, Typography, Space } from 'antd'
import { Outlet, useNavigate, useLocation } from 'react-router-dom'
import {
  HomeOutlined,
  SearchOutlined,
  CalendarOutlined,
  CheckCircleOutlined,
  WarningOutlined,
  RobotOutlined,
  LogoutOutlined,
  UserOutlined
} from '@ant-design/icons'
import { useAuth } from '../hooks/useAuth'

const { Header, Content } = Layout

const StudentLayout: React.FC = () => {
  const { userInfo, logout } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const menuItems = [
    { key: '/student/rooms', icon: <HomeOutlined />, label: '自习室' },
    { key: '/student/search', icon: <SearchOutlined />, label: '搜索座位' },
    { key: '/student/reservations', icon: <CalendarOutlined />, label: '我的预约' },
    { key: '/student/check-in', icon: <CheckCircleOutlined />, label: '签到' },
    { key: '/student/violations', icon: <WarningOutlined />, label: '违约记录' },
    { key: '/student/assistant', icon: <RobotOutlined />, label: '智能助手' },
  ]

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 24px' }}>
        <Typography.Title level={4} style={{ color: '#fff', margin: 0 }}>
          🪑 SeatFlow
        </Typography.Title>
        <Menu
          theme="dark"
          mode="horizontal"
          selectedKeys={[location.pathname]}
          items={menuItems}
          onClick={({ key }) => navigate(key)}
          style={{ flex: 1, marginLeft: 24 }}
        />
        <Space>
          <span style={{ color: '#fff' }}>
            <UserOutlined /> {userInfo?.realName || userInfo?.username}
          </span>
          <Button type="text" icon={<LogoutOutlined />} onClick={logout} style={{ color: '#fff' }}>
            退出
          </Button>
        </Space>
      </Header>
      <Content style={{ padding: '24px' }}>
        <Outlet />
      </Content>
    </Layout>
  )
}

export default StudentLayout
