import React, { useEffect, useState } from 'react'
import { Card, Col, Row, Statistic, Spin } from 'antd'
import { HomeOutlined, TeamOutlined, CalendarOutlined, WarningOutlined, CheckCircleOutlined } from '@ant-design/icons'
import { dashboardApi, DashboardData } from '../../services/admin'

const Dashboard: React.FC = () => {
  const [data, setData] = useState<DashboardData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetch = async () => {
      try {
        const res = await dashboardApi.getStats()
        if (res.data.code === 200) setData(res.data.data)
      } catch (e) { console.error(e) }
      finally { setLoading(false) }
    }
    fetch()
  }, [])

  if (loading) return <div style={{ textAlign: 'center', padding: 100 }}><Spin size="large" /></div>
  if (!data) return <div>加载失败</div>

  return (
    <div>
      <h2>仪表盘</h2>
      <Row gutter={[16, 16]}>
        <Col xs={12} sm={6}>
          <Card><Statistic title="自习室" value={data.totalRooms} prefix={<HomeOutlined />} /></Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card><Statistic title="总座位/可用" value={`${data.totalSeats}/${data.availableSeats}`} prefix={<HomeOutlined />} /></Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card><Statistic title="今日预约" value={data.todayReservations} prefix={<CalendarOutlined />} /></Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card><Statistic title="待签到" value={data.pendingReservations} valueStyle={{ color: '#faad14' }} prefix={<CalendarOutlined />} /></Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card><Statistic title="今日签到" value={data.todayCheckIns} valueStyle={{ color: '#52c41a' }} prefix={<CheckCircleOutlined />} /></Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card><Statistic title="今日违约" value={data.todayViolations} valueStyle={{ color: '#ff4d4f' }} prefix={<WarningOutlined />} /></Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card><Statistic title="总用户" value={data.totalUsers} prefix={<TeamOutlined />} /></Card>
        </Col>
      </Row>
    </div>
  )
}

export default Dashboard
