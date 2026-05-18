import React, { useEffect, useState } from 'react'
import { Card, Row, Col, Tag, Spin, Empty, Typography } from 'antd'
import { EnvironmentOutlined, ClockCircleOutlined } from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import { roomApi } from '../../services/room'
import type { Room } from '../../services/room'

const { Title, Text } = Typography

const RoomList: React.FC = () => {
  const [rooms, setRooms] = useState<Room[]>([])
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  useEffect(() => {
    const fetchRooms = async () => {
      try {
        const res = await roomApi.list()
        if (res.data.code === 200) {
          setRooms(res.data.data)
        }
      } catch (error) {
        console.error('获取自习室列表失败', error)
      } finally {
        setLoading(false)
      }
    }
    fetchRooms()
  }, [])

  if (loading) return <div style={{ textAlign: 'center', padding: 100 }}><Spin size="large" /></div>
  if (rooms.length === 0) return <Empty description="暂无可用自习室" />

  return (
    <div>
      <Title level={3}>自习室</Title>
      <Row gutter={[16, 16]}>
        {rooms.map(room => (
          <Col xs={24} sm={12} md={8} lg={6} key={room.id}>
            <Card
              hoverable
              onClick={() => navigate(`/student/rooms/${room.id}`)}
              style={{ borderRadius: 8 }}
            >
              <Title level={5} style={{ marginBottom: 8 }}>{room.name}</Title>
              <div style={{ marginBottom: 4 }}>
                <EnvironmentOutlined style={{ marginRight: 4, color: '#999' }} />
                <Text type="secondary">{room.location || '未设置'}</Text>
              </div>
              <div style={{ marginBottom: 8 }}>
                <ClockCircleOutlined style={{ marginRight: 4, color: '#999' }} />
                <Text type="secondary">{room.openTime?.slice(0, 5)} - {room.closeTime?.slice(0, 5)}</Text>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Tag color={room.availableSeats > 0 ? 'green' : 'red'}>
                  空座 {room.availableSeats}/{room.totalSeats}
                </Tag>
                {room.departmentName !== '全校共享' && (
                  <Tag color="blue">{room.departmentName}</Tag>
                )}
              </div>
            </Card>
          </Col>
        ))}
      </Row>
    </div>
  )
}

export default RoomList
