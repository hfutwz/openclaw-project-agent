import React, { useEffect, useState } from 'react'
import { Form, Select, DatePicker, TimePicker, Button, Card, Row, Col, Tag, Empty, Spin, Typography, message } from 'antd'
import { SearchOutlined, EnvironmentOutlined, ThunderboltOutlined } from '@ant-design/icons'
import dayjs from 'dayjs'
import { searchApi, type SeatSearchResult, type SearchParams } from '../../services/search'
import { roomApi, type Room } from '../../services/room'
import { reservationApi } from '../../services/reservation'
import { useNavigate } from 'react-router-dom'

const { Title, Text } = Typography

const SOCKET_TYPE_OPTIONS = [
  { label: '不限', value: '' },
  { label: '无插座', value: 'NONE' },
  { label: '固定插座 ⚡', value: 'FIXED' },
  { label: '移动导轨 🔌', value: 'MOVABLE' },
  { label: '有插座', value: 'HAS_SOCKET' },
]

const POSITION_OPTIONS = [
  { label: '不限', value: '' },
  { label: '靠窗 🪟', value: 'WINDOW' },
  { label: '靠走廊 🚶', value: 'CORRIDOR' },
  { label: '中间', value: 'MIDDLE' },
]

const SOCKET_LABELS: Record<string, string> = {
  NONE: '无插座',
  FIXED: '固定插座 ⚡',
  MOVABLE: '移动导轨 🔌',
  TRACK: '移动导轨 🔌',
}

const POSITION_LABELS: Record<string, string> = {
  WINDOW: '靠窗 🪟',
  CORRIDOR: '靠走廊 🚶',
  MIDDLE: '中间',
}

const Search: React.FC = () => {
  const [form] = Form.useForm()
  const navigate = useNavigate()
  const [rooms, setRooms] = useState<Room[]>([])
  const [results, setResults] = useState<SeatSearchResult[]>([])
  const [loading, setLoading] = useState(false)
  const [searched, setSearched] = useState(false)

  useEffect(() => {
    const fetchRooms = async () => {
      try {
        const res = await roomApi.list()
        if (res.data.code === 200) {
          setRooms(res.data.data)
        }
      } catch (e) {
        console.error('获取自习室列表失败', e)
      }
    }
    fetchRooms()
  }, [])

  const handleSearch = async (values: any) => {
    setLoading(true)
    setSearched(true)
    try {
      const params: SearchParams = {
        date: values.date?.format('YYYY-MM-DD') || dayjs().format('YYYY-MM-DD'),
        startTime: values.startTime?.format('HH:mm') || '08:00',
        endTime: values.endTime?.format('HH:mm') || '22:00',
      }
      if (values.roomId) params.roomId = values.roomId
      if (values.socketType) params.socketType = values.socketType
      if (values.position) params.position = values.position

      const res = await searchApi.search(params)
      if (res.data.code === 200) {
        setResults(res.data.data)
        if (res.data.data.length === 0) {
          message.info('未找到符合条件的可用座位')
        }
      }
    } catch (e: any) {
      message.error(e.response?.data?.message || '搜索失败')
    } finally {
      setLoading(false)
    }
  }

  const handleReserve = async (seat: SeatSearchResult) => {
    const values = form.getFieldsValue()
    const date = values.date?.format('YYYY-MM-DD') || dayjs().format('YYYY-MM-DD')
    const startTime = values.startTime?.format('HH:mm') || '08:00'
    const endTime = values.endTime?.format('HH:mm') || '22:00'

    try {
      const res = await reservationApi.create({
        seatId: seat.id,
        date,
        startTime,
        endTime,
      })
      if (res.data.code === 200) {
        message.success(`座位 ${seat.seatNumber} 预约成功！`)
        // 重新搜索以刷新状态
        handleSearch(form.getFieldsValue())
      }
    } catch (e: any) {
      message.error(e.response?.data?.message || '预约失败')
    }
  }

  const getRoomName = (roomId: number) => {
    return rooms.find(r => r.id === roomId)?.name || `自习室#${roomId}`
  }

  return (
    <div>
      <Title level={3}>
        <SearchOutlined style={{ marginRight: 8 }} />
        搜索座位
      </Title>

      <Card style={{ marginBottom: 24 }}>
        <Form
          form={form}
          layout="inline"
          onFinish={handleSearch}
          initialValues={{
            date: dayjs(),
            startTime: dayjs().startOf('hour'),
            endTime: dayjs().startOf('hour').add(2, 'hour'),
          }}
          style={{ flexWrap: 'wrap', gap: 12 }}
        >
          <Form.Item name="date" label="日期">
            <DatePicker format="YYYY-MM-DD" />
          </Form.Item>
          <Form.Item name="startTime" label="开始时间">
            <TimePicker format="HH:mm" minuteStep={60 as any} />
          </Form.Item>
          <Form.Item name="endTime" label="结束时间">
            <TimePicker format="HH:mm" minuteStep={60 as any} />
          </Form.Item>
          <Form.Item name="roomId" label="自习室">
            <Select
              allowClear
              placeholder="不限"
              style={{ width: 160 }}
              options={[
                { label: '不限', value: undefined },
                ...rooms.map(r => ({ label: r.name, value: r.id })),
              ]}
            />
          </Form.Item>
          <Form.Item name="socketType" label="插座类型">
            <Select
              allowClear
              placeholder="不限"
              style={{ width: 140 }}
              options={SOCKET_TYPE_OPTIONS}
            />
          </Form.Item>
          <Form.Item name="position" label="位置">
            <Select
              allowClear
              placeholder="不限"
              style={{ width: 140 }}
              options={POSITION_OPTIONS}
            />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" icon={<SearchOutlined />} loading={loading}>
              搜索
            </Button>
          </Form.Item>
        </Form>
      </Card>

      {loading && (
        <div style={{ textAlign: 'center', padding: 60 }}>
          <Spin size="large" />
        </div>
      )}

      {!loading && searched && results.length === 0 && (
        <Empty description="未找到符合条件的可用座位" />
      )}

      {!loading && results.length > 0 && (
        <div>
          <Text type="secondary" style={{ marginBottom: 16, display: 'block' }}>
            找到 {results.length} 个可用座位
          </Text>
          <Row gutter={[16, 16]}>
            {results.map(seat => (
              <Col xs={24} sm={12} md={8} lg={6} key={seat.id}>
                <Card
                  hoverable
                  size="small"
                  style={{ borderRadius: 8 }}
                  actions={[
                    <Button
                      key="reserve"
                      type="link"
                      size="small"
                      onClick={() => handleReserve(seat)}
                    >
                      预约
                    </Button>,
                    <Button
                      key="detail"
                      type="link"
                      size="small"
                      onClick={() => navigate(`/student/rooms/${seat.roomId}`)}
                    >
                      查看座位图
                    </Button>,
                  ]}
                >
                  <Card.Meta
                    title={
                      <span>
                        {seat.seatNumber}
                        {seat.socketType && seat.socketType !== 'NONE' && (
                          <Tag color="blue" style={{ marginLeft: 8, fontSize: 11 }}>
                            <ThunderboltOutlined /> {SOCKET_LABELS[seat.socketType] || seat.socketType}
                          </Tag>
                        )}
                      </span>
                    }
                    description={
                      <div>
                        <div style={{ marginBottom: 4 }}>
                          <EnvironmentOutlined style={{ marginRight: 4, color: '#999' }} />
                          <Text type="secondary">{getRoomName(seat.roomId)}</Text>
                        </div>
                        <div>
                          <Tag>{POSITION_LABELS[seat.position] || seat.position}</Tag>
                          <Tag color="green">可用</Tag>
                        </div>
                      </div>
                    }
                  />
                </Card>
              </Col>
            ))}
          </Row>
        </div>
      )}
    </div>
  )
}

export default Search
