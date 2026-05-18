import React, { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Typography, Spin, Tag, Button, Descriptions, Modal, TimePicker, message, DatePicker } from 'antd'
import { ArrowLeftOutlined } from '@ant-design/icons'
import dayjs from 'dayjs'
import { roomApi } from '../../services/room'
import type { RoomDetail, Seat } from '../../services/room'
import { reservationApi } from '../../services/reservation'
import SeatMap from '../../components/SeatMap/SeatMap'

const { Title, Text } = Typography

const RoomDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [room, setRoom] = useState<RoomDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [reserveModal, setReserveModal] = useState(false)
  const [selectedSeat, setSelectedSeat] = useState<Seat | null>(null)
  const [reserveDate, setReserveDate] = useState(dayjs())
  const [reserveStart, setReserveStart] = useState(dayjs().startOf('hour'))
  const [reserveEnd, setReserveEnd] = useState(dayjs().startOf('hour').add(2, 'hour'))
  const [reserving, setReserving] = useState(false)

  useEffect(() => {
    if (!id) return
    const fetchDetail = async () => {
      try {
        const res = await roomApi.getDetail(Number(id))
        if (res.data.code === 200) {
          setRoom(res.data.data)
        }
      } catch (error) {
        console.error('获取自习室详情失败', error)
      } finally {
        setLoading(false)
      }
    }
    fetchDetail()
  }, [id])

  const handleSeatClick = (seat: Seat) => {
    setSelectedSeat(seat)
    setReserveModal(true)
  }

  const handleReserve = async () => {
    if (!selectedSeat) return
    setReserving(true)
    try {
      const res = await reservationApi.create({
        seatId: selectedSeat.id,
        date: reserveDate.format('YYYY-MM-DD'),
        startTime: reserveStart.format('HH:mm'),
        endTime: reserveEnd.format('HH:mm'),
      })
      if (res.data.code === 200) {
        message.success(`座位 ${selectedSeat.seatNumber} 预约成功！`)
        setReserveModal(false)
        // 刷新座位图
        const detailRes = await roomApi.getDetail(Number(id))
        if (detailRes.data.code === 200) setRoom(detailRes.data.data)
      }
    } catch (e: any) {
      message.error(e.response?.data?.message || '预约失败')
    } finally {
      setReserving(false)
    }
  }

  if (loading) return <div style={{ textAlign: 'center', padding: 100 }}><Spin size="large" /></div>
  if (!room) return <div>自习室不存在</div>

  return (
    <div>
      <Button icon={<ArrowLeftOutlined />} onClick={() => navigate('/student/rooms')} style={{ marginBottom: 16 }}>
        返回列表
      </Button>

      <Title level={3}>{room.name}</Title>

      <Descriptions bordered size="small" style={{ marginBottom: 24 }}>
        <Descriptions.Item label="位置">{room.location || '未设置'}</Descriptions.Item>
        <Descriptions.Item label="开放时间">{room.openTime?.slice(0,5)} - {room.closeTime?.slice(0,5)}</Descriptions.Item>
        <Descriptions.Item label="状态">
          <Tag color={room.status === 'OPEN' ? 'green' : 'red'}>
            {room.status === 'OPEN' ? '开放' : '关闭'}
          </Tag>
        </Descriptions.Item>
        <Descriptions.Item label="空座">
          <Text type={room.availableSeats > 0 ? 'success' : 'danger'}>
            {room.availableSeats}/{room.totalSeats}
          </Text>
        </Descriptions.Item>
        <Descriptions.Item label="院系">{room.departmentName}</Descriptions.Item>
      </Descriptions>

      <Title level={5}>座位图（点击可选座预约）</Title>
      <div style={{ 
        background: '#fafafa', 
        padding: 24, 
        borderRadius: 8,
        overflow: 'auto'
      }}>
        <SeatMap 
          seats={room.seats} 
          maxRow={room.maxRow} 
          maxCol={room.maxCol}
          onSeatClick={handleSeatClick}
        />
      </div>

      <Modal
        title={`预约座位 ${selectedSeat?.seatNumber || ''}`}
        open={reserveModal}
        onOk={handleReserve}
        onCancel={() => setReserveModal(false)}
        confirmLoading={reserving}
        okText="确认预约"
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <span>日期：</span>
            <DatePicker value={reserveDate} onChange={v => v && setReserveDate(v)} format="YYYY-MM-DD" />
          </div>
          <div>
            <span>开始时间：</span>
            <TimePicker value={reserveStart} onChange={v => v && setReserveStart(v)} format="HH:mm" minuteStep={60 as any} />
          </div>
          <div>
            <span>结束时间：</span>
            <TimePicker value={reserveEnd} onChange={v => v && setReserveEnd(v)} format="HH:mm" minuteStep={60 as any} />
          </div>
        </div>
      </Modal>
    </div>
  )
}

export default RoomDetail
