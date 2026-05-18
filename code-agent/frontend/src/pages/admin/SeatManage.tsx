import React, { useEffect, useState } from 'react'
import { Table, Button, Modal, Form, Input, InputNumber, Select, Tag, Space, message, Popconfirm, Card, Typography } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { seatApi, roomApi } from '../../services/room'
import type { Seat, Room } from '../../services/room'
import SeatMap from '../../components/SeatMap/SeatMap'

const { Title } = Typography

const SeatManage: React.FC = () => {
  const [rooms, setRooms] = useState<Room[]>([])
  const [selectedRoomId, setSelectedRoomId] = useState<number | null>(null)
  const [seats, setSeats] = useState<Seat[]>([])
  const [loading, setLoading] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editingSeat, setEditingSeat] = useState<Seat | null>(null)
  const [form] = Form.useForm()

  // 加载自习室列表
  useEffect(() => {
    const fetchRooms = async () => {
      try {
        const res = await roomApi.adminList(1, 100)
        if (res.data.code === 200) {
          const roomList = res.data.data.records
          setRooms(roomList)
          // 默认选中第一个
          if (roomList.length > 0 && !selectedRoomId) {
            setSelectedRoomId(roomList[0].id)
          }
        }
      } catch (e) {
        console.error('获取自习室列表失败', e)
      }
    }
    fetchRooms()
  }, [])

  // 加载座位
  const fetchSeats = async () => {
    if (!selectedRoomId) return
    setLoading(true)
    try {
      const res = await seatApi.listByRoom(selectedRoomId)
      if (res.data.code === 200) setSeats(res.data.data)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchSeats() }, [selectedRoomId])

  const rid = selectedRoomId || 0
  const maxRow = Math.max(...seats.map(s => s.rowNum), 0)
  const maxCol = Math.max(...seats.map(s => s.colNum), 0)

  const handleCreate = () => {
    if (!selectedRoomId) { message.warning('请先选择自习室'); return }
    setEditingSeat(null)
    form.resetFields()
    form.setFieldsValue({ socketType: 'NONE', position: 'MIDDLE' })
    setModalOpen(true)
  }

  const handleEdit = (seat: Seat) => {
    setEditingSeat(seat)
    form.setFieldsValue(seat)
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editingSeat) {
        await seatApi.adminUpdate(rid, editingSeat.id, values)
        message.success('更新成功')
      } else {
        await seatApi.adminCreate(rid, values)
        message.success('创建成功')
      }
      setModalOpen(false)
      fetchSeats()
    } catch (e: any) {
      message.error(e.response?.data?.message || '操作失败')
    }
  }

  const handleDelete = async (seatId: number) => {
    try {
      await seatApi.adminDelete(rid, seatId)
      message.success('删除成功')
      fetchSeats()
    } catch (e: any) {
      message.error(e.response?.data?.message || '删除失败')
    }
  }

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '编号', dataIndex: 'seatNumber', key: 'seatNumber', width: 80 },
    { title: '行', dataIndex: 'rowNum', key: 'rowNum', width: 60 },
    { title: '列', dataIndex: 'colNum', key: 'colNum', width: 60 },
    { title: '插座', dataIndex: 'socketType', key: 'socketType', width: 80, render: (v: string) => {
      const map: Record<string, string> = { NONE: '无', FIXED: '⚡ 固定', MOVABLE: '🔌 导轨', TRACK: '🔌 导轨' }
      return map[v] || v
    }},
    { title: '位置', dataIndex: 'position', key: 'position', width: 80, render: (v: string) => {
      const map: Record<string, string> = { WINDOW: '🪟 靠窗', CORRIDOR: '🚶 靠走廊', MIDDLE: '中间' }
      return map[v] || v
    }},
    { title: '状态', dataIndex: 'status', key: 'status', width: 80, render: (s: string) => <Tag color={s === 'AVAILABLE' ? 'green' : 'red'}>{s === 'AVAILABLE' ? '可用' : '停用'}</Tag> },
    { title: '操作', key: 'action', render: (_: any, r: Seat) => (
      <Space>
        <Button size="small" icon={<EditOutlined />} onClick={() => handleEdit(r)} />
        <Popconfirm title="确认删除？" onConfirm={() => handleDelete(r.id)}>
          <Button size="small" danger icon={<DeleteOutlined />} />
        </Popconfirm>
      </Space>
    )},
  ]

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <Space>
          <Title level={4} style={{ margin: 0 }}>座位管理</Title>
          <Select
            style={{ width: 200 }}
            placeholder="请选择自习室"
            value={selectedRoomId || undefined}
            onChange={(v) => setSelectedRoomId(v)}
            options={rooms.map(r => ({ value: r.id, label: r.name }))}
          />
        </Space>
        <Button type="primary" icon={<PlusOutlined />} onClick={handleCreate}>新增座位</Button>
      </div>

      {seats.length > 0 && (
        <Card title="座位图预览" style={{ marginBottom: 16 }}>
          <SeatMap seats={seats} maxRow={maxRow} maxCol={maxCol} />
        </Card>
      )}

      <Table
        dataSource={seats}
        columns={columns}
        rowKey="id"
        loading={loading}
        pagination={false}
        size="small"
        locale={{ emptyText: selectedRoomId ? '暂无座位' : '请先选择自习室' }}
      />

      <Modal
        title={editingSeat ? '编辑座位' : '新增座位'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        destroyOnClose
      >
        <Form form={form} layout="vertical">
          <Form.Item name="seatNumber" label="座位编号" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="rowNum" label="行号" rules={[{ required: true }]}>
            <InputNumber min={1} />
          </Form.Item>
          <Form.Item name="colNum" label="列号" rules={[{ required: true }]}>
            <InputNumber min={1} />
          </Form.Item>
          <Form.Item name="socketType" label="插座类型">
            <Select options={[
              { value: 'NONE', label: '无' },
              { value: 'FIXED', label: '⚡ 固定插座' },
              { value: 'MOVABLE', label: '🔌 移动导轨' },
            ]} />
          </Form.Item>
          <Form.Item name="position" label="位置标记">
            <Select options={[
              { value: 'MIDDLE', label: '中间' },
              { value: 'WINDOW', label: '🪟 靠窗' },
              { value: 'CORRIDOR', label: '🚶 靠走廊' },
            ]} />
          </Form.Item>
          {editingSeat && (
            <Form.Item name="status" label="状态">
              <Select options={[
                { value: 'AVAILABLE', label: '可用' },
                { value: 'DISABLED', label: '停用' },
              ]} />
            </Form.Item>
          )}
        </Form>
      </Modal>
    </div>
  )
}

export default SeatManage
