import React, { useEffect, useState } from 'react'
import { Card, Input, Button, List, Tag, message, Empty, Spin, Typography } from 'antd'
import { CheckCircleOutlined } from '@ant-design/icons'
import { reservationApi } from '../../services/reservation'
import { checkInApi } from '../../services/checkin'
import type { Reservation } from '../../services/reservation'

const { Title } = Typography

const CheckInPage: React.FC = () => {
  const [currentReservations, setCurrentReservations] = useState<Reservation[]>([])
  const [loading, setLoading] = useState(true)
  const [checkInCode, setCheckInCode] = useState('')

  useEffect(() => {
    const fetch = async () => {
      try {
        const res = await reservationApi.listCurrent()
        if (res.data.code === 200) setCurrentReservations(res.data.data)
      } catch (e) { console.error(e) }
      finally { setLoading(false) }
    }
    fetch()
  }, [])

  const handleCheckIn = async (reservationId: number) => {
    if (!checkInCode) {
      message.warning('请输入签到编码')
      return
    }
    try {
      const res = await checkInApi.checkIn(reservationId, checkInCode)
      if (res.data.code === 200) {
        message.success('签到成功！')
        // Refresh list
        const listRes = await reservationApi.listCurrent()
        if (listRes.data.code === 200) setCurrentReservations(listRes.data.data)
      }
    } catch (e: any) {
      message.error(e.response?.data?.message || '签到失败')
    }
  }

  if (loading) return <div style={{ textAlign: 'center', padding: 100 }}><Spin size="large" /></div>

  return (
    <div>
      <Title level={3}>签到</Title>

      <Card style={{ marginBottom: 24 }}>
        <Title level={5}>输入签到编码</Title>
        <Input.Search
          placeholder="请输入6位签到编码"
          enterButton="签到"
          size="large"
          maxLength={6}
          value={checkInCode}
          onChange={(e) => setCheckInCode(e.target.value)}
          onSearch={() => {
            if (currentReservations.length > 0) {
              handleCheckIn(currentReservations[0].id)
            } else {
              message.warning('暂无待签到的预约')
            }
          }}
        />
      </Card>

      <Title level={5}>待签到预约</Title>
      {currentReservations.filter(r => r.status === 'PENDING').length === 0 ? (
        <Empty description="暂无待签到预约" />
      ) : (
        <List
          dataSource={currentReservations.filter(r => r.status === 'PENDING')}
          renderItem={(item) => (
            <List.Item
              actions={[
                <Button key="ci" type="primary" icon={<CheckCircleOutlined />}
                  onClick={() => handleCheckIn(item.id)}>签到</Button>
              ]}
            >
              <List.Item.Meta
                title={`${item.roomName} - 座位 ${item.seatNumber}`}
                description={`${item.date} ${item.startTime?.slice(0,5)}-${item.endTime?.slice(0,5)}`}
              />
            </List.Item>
          )}
        />
      )}

      {currentReservations.some(r => r.status === 'CHECKED_IN') && (
        <>
          <Title level={5} style={{ marginTop: 24 }}>已签到</Title>
          <List
            dataSource={currentReservations.filter(r => r.status === 'CHECKED_IN')}
            renderItem={(item) => (
              <List.Item>
                <List.Item.Meta
                  title={<span>{item.roomName} - 座位 {item.seatNumber} <Tag color="blue">已签到</Tag></span>}
                  description={`${item.date} ${item.startTime?.slice(0,5)}-${item.endTime?.slice(0,5)}`}
                />
              </List.Item>
            )}
          />
        </>
      )}
    </div>
  )
}

export default CheckInPage
