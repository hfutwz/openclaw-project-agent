import React, { useEffect, useState } from 'react'
import { List, Tag, Button, message, Empty, Spin, Typography } from 'antd'
import { ClockCircleOutlined, CloseCircleOutlined, RedoOutlined } from '@ant-design/icons'
import { reservationApi } from '../../services/reservation'
import type { Reservation } from '../../services/reservation'

const { Title, Text } = Typography

const statusMap: Record<string, { color: string; label: string }> = {
  PENDING: { color: 'orange', label: '待签到' },
  CHECKED_IN: { color: 'blue', label: '已签到' },
  COMPLETED: { color: 'green', label: '已完成' },
  CANCELLED: { color: 'default', label: '已取消' },
}

const MyReservations: React.FC = () => {
  const [currentList, setCurrentList] = useState<Reservation[]>([])
  const [historyList, setHistoryList] = useState<Reservation[]>([])
  const [historyTotal, setHistoryTotal] = useState(0)
  const [historyPage, setHistoryPage] = useState(1)
  const [loading, setLoading] = useState(true)

  const fetchCurrent = async () => {
    try {
      const res = await reservationApi.listCurrent()
      if (res.data.code === 200) setCurrentList(res.data.data)
    } catch (e) { console.error(e) }
  }

  const fetchHistory = async (p = historyPage) => {
    try {
      const res = await reservationApi.listHistory(p, 20)
      if (res.data.code === 200) {
        setHistoryList(res.data.data.records)
        setHistoryTotal(res.data.data.total)
      }
    } catch (e) { console.error(e) }
  }

  useEffect(() => {
    const load = async () => {
      setLoading(true)
      await Promise.all([fetchCurrent(), fetchHistory()])
      setLoading(false)
    }
    load()
  }, [])

  const handleCancel = async (id: number) => {
    try {
      const res = await reservationApi.cancel(id)
      if (res.data.code === 200) {
        message.success('取消成功')
        fetchCurrent()
        fetchHistory()
      }
    } catch (e: any) {
      message.error(e.response?.data?.message || '取消失败')
    }
  }

  const handleRebook = async (id: number) => {
    try {
      const res = await reservationApi.rebook(id)
      if (res.data.code === 200) {
        message.success('再次预约成功')
        fetchCurrent()
        fetchHistory()
      }
    } catch (e: any) {
      message.error(e.response?.data?.message || '再次预约失败')
    }
  }

  if (loading) return <div style={{ textAlign: 'center', padding: 100 }}><Spin size="large" /></div>

  return (
    <div>
      <Title level={3}>我的预约</Title>

      {/* 当前预约 */}
      <Title level={5}>当前预约</Title>
      {currentList.length === 0 ? (
        <Empty description="暂无当前预约" />
      ) : (
        <List
          dataSource={currentList}
          renderItem={(item) => (
            <List.Item
              actions={[
                item.status === 'PENDING' && (
                  <Button key="cancel" danger size="small" icon={<CloseCircleOutlined />}
                    onClick={() => handleCancel(item.id)}>取消</Button>
                ),
              ].filter(Boolean)}
            >
              <List.Item.Meta
                title={
                  <span>
                    {item.roomName} - 座位 {item.seatNumber}
                    <Tag color={statusMap[item.status]?.color || 'default'} style={{ marginLeft: 8 }}>
                      {statusMap[item.status]?.label || item.status}
                    </Tag>
                  </span>
                }
                description={
                  <span>
                    <ClockCircleOutlined /> {item.date} {item.startTime?.slice(0,5)}-{item.endTime?.slice(0,5)}
                  </span>
                }
              />
            </List.Item>
          )}
        />
      )}

      {/* 历史预约 */}
      <Title level={5} style={{ marginTop: 24 }}>历史预约</Title>
      {historyList.length === 0 ? (
        <Empty description="暂无历史预约" />
      ) : (
        <List
          dataSource={historyList}
          pagination={{
            current: historyPage,
            total: historyTotal,
            pageSize: 20,
            onChange: (p) => { setHistoryPage(p); fetchHistory(p) },
          }}
          renderItem={(item) => (
            <List.Item
              actions={[
                item.status === 'COMPLETED' || item.status === 'CANCELLED' ? (
                  <Button key="rebook" size="small" icon={<RedoOutlined />}
                    onClick={() => handleRebook(item.id)}>再次预约</Button>
                ) : null,
              ].filter(Boolean)}
            >
              <List.Item.Meta
                title={
                  <span>
                    {item.roomName} - 座位 {item.seatNumber}
                    <Tag color={statusMap[item.status]?.color || 'default'} style={{ marginLeft: 8 }}>
                      {statusMap[item.status]?.label || item.status}
                    </Tag>
                  </span>
                }
                description={
                  <span>
                    <ClockCircleOutlined /> {item.date} {item.startTime?.slice(0,5)}-{item.endTime?.slice(0,5)}
                    {item.cancelledBy && <Text type="secondary"> (由{item.cancelledBy === 'STUDENT' ? '本人' : item.cancelledBy}取消)</Text>}
                  </span>
                }
              />
            </List.Item>
          )}
        />
      )}
    </div>
  )
}

export default MyReservations
