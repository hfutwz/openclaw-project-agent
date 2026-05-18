import React, { useEffect, useState } from 'react'
import { Card, Select, Typography, Button, Tag, message, Spin, Descriptions } from 'antd'
import { ReloadOutlined } from '@ant-design/icons'
import { roomApi } from '../../services/room'
import { checkInApi } from '../../services/checkin'
import type { Room } from '../../services/room'

const { Title } = Typography

const CheckInCodeManage: React.FC = () => {
  const [rooms, setRooms] = useState<Room[]>([])
  const [selectedRoom, setSelectedRoom] = useState<number | null>(null)
  const [code, setCode] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [refreshing, setRefreshing] = useState(false)

  useEffect(() => {
    const fetchRooms = async () => {
      try {
        const res = await roomApi.list()
        if (res.data.code === 200) {
          setRooms(res.data.data)
        }
      } catch (e) {
        console.error(e)
      }
    }
    fetchRooms()
  }, [])

  const fetchCode = async (roomId: number, showLoading = true) => {
    if (!roomId) return
    if (showLoading) setLoading(true)
    setRefreshing(true)
    try {
      const res = await checkInApi.adminGetCode(roomId)
      if (res.data.code === 200) {
        setCode(res.data.data.code)
      } else {
        message.error((res.data as any).message || '获取编码失败')
        setCode(null)
      }
    } catch (e) {
      console.error(e)
      message.error('获取编码失败')
      setCode(null)
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  const handleRoomChange = (roomId: number) => {
    setSelectedRoom(roomId)
    fetchCode(roomId)
  }

  return (
    <div>
      <Title level={3}>签到编码管理</Title>

      <Card>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', marginBottom: 24 }}>
          <span>选择自习室：</span>
          <Select
            placeholder="请选择自习室"
            style={{ width: 240 }}
            value={selectedRoom}
            onChange={handleRoomChange}
            options={rooms.map(r => ({ label: r.name, value: r.id }))}
          />
          {selectedRoom && (
            <Button
              icon={<ReloadOutlined />}
              loading={refreshing}
              onClick={() => fetchCode(selectedRoom)}
            >
              刷新编码
            </Button>
          )}
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: 60 }}><Spin size="large" /></div>
        ) : (
          selectedRoom && code && (
            <Descriptions bordered size="small">
              <Descriptions.Item label="自习室">{rooms.find(r => r.id === selectedRoom)?.name || selectedRoom}</Descriptions.Item>
              <Descriptions.Item label="今日签到编码">
                <Tag color="blue" style={{ fontSize: 24, padding: '4px 12px', fontFamily: 'monospace', fontWeight: 'bold' }}>
                  {code}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="说明">每日0点自动生成新的签到编码</Descriptions.Item>
            </Descriptions>
          )
        )}

        {!loading && selectedRoom && !code && (
          <div style={{ textAlign: 'center', padding: '40px 0', color: '#999' }}>
            该自习室今日未生成签到编码
          </div>
        )}

        {!selectedRoom && !loading && (
          <div style={{ textAlign: 'center', padding: '40px 0', color: '#999' }}>
            请选择自习室查看签到编码
          </div>
        )}
      </Card>
    </div>
  )
}

export default CheckInCodeManage