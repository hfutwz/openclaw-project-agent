import React, { useState } from 'react'
import { Form, Input, Button, Card, Typography, message } from 'antd'
import { UserOutlined, LockOutlined } from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

const LoginPage: React.FC = () => {
  const { login } = useAuth()
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const [form] = Form.useForm()

  const onFinish = async (values: { username: string; password: string }) => {
    setLoading(true)
    // [SECURITY-DISABLED] 清除旧的认证缓存
    localStorage.removeItem('token')
    localStorage.removeItem('userInfo')
    localStorage.removeItem('loginUsername')

    try {
      const result = await login(values.username, values.password)
      if (result.success) {
        message.success('登录成功')
        // 根据用户类型跳转到对应首页
        const savedInfo = localStorage.getItem('userInfo')
        const info = savedInfo ? JSON.parse(savedInfo) : null
        if (info?.userType === 'ADMIN') {
          navigate('/admin/dashboard')
        } else {
          navigate('/student/rooms')
        }
      } else {
        message.error(result.message || '登录失败')
        form.setFieldsValue({ password: '' })
      }
    } catch {
      message.error('登录失败，请稍后再试')
      form.setFieldsValue({ password: '' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
    }}>
      <Card style={{ width: 400, borderRadius: 12, boxShadow: '0 8px 24px rgba(0,0,0,0.15)' }}>
        <Typography.Title level={3} style={{ textAlign: 'center', marginBottom: 32 }}>
          🪑 SeatFlow
        </Typography.Title>
        <Typography.Text type="secondary" style={{ display: 'block', textAlign: 'center', marginBottom: 24 }}>
          自习座位预约系统
        </Typography.Text>
        <Form form={form} onFinish={onFinish} size="large">
          <Form.Item name="username" rules={[{ required: true, message: '请输入用户名' }]}>
            <Input prefix={<UserOutlined />} placeholder="用户名" />
          </Form.Item>
          <Form.Item name="password" rules={[{ required: true, message: '请输入密码' }]}>
            <Input.Password prefix={<LockOutlined />} placeholder="密码" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} block>
              登录
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default LoginPage
