import React, { useEffect, useState } from 'react'
import { Table, Button, Modal, Form, Input, InputNumber, Select, Tag, Space, message, Popconfirm, Card, Typography, Divider, Alert } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, ThunderboltOutlined } from '@ant-design/icons'
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
  // 批量生成
  const [batchModalOpen, setBatchModalOpen] = useState(false)
  const [batchLoading, setBatchLoading] = useState(false)
  const [batchForm] = Form.useForm()

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

  // 批量生成座位
  const handleBatchGenerate = async () => {
    const values = await batchForm.validateFields()
    const { rows, cols, socketType, windowRows, corridorCols } = values
    const winRows: number[] = (windowRows || '')
      .split(',')
      .map((s: string) => parseInt(s.trim()))
      .filter((n: number) => !isNaN(n))
    const rawCorrCols: number[] = (corridorCols || '')
      .split(',')
      .map((s: string) => parseInt(s.trim()))
      .filter((n: number) => !isNaN(n))

    const rowLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    const requests: object[] = []

    for (let r = 1; r <= rows; r++) {
      for (let c = 1; c <= cols; c++) {
        const seatNumber = `${rowLetters[r - 1]}${c}`
        // 将负数列号转为实際列号（-1 => cols）
        const resolvedCorrCols = rawCorrCols.map((n: number) => n < 0 ? cols + n + 1 : n)
        let position = 'MIDDLE'
        if (winRows.includes(r)) position = 'WINDOW'
        else if (resolvedCorrCols.includes(c)) position = 'CORRIDOR'
        requests.push({ seatNumber, rowNum: r, colNum: c, socketType, position, status: 'AVAILABLE' })
      }
    }

    setBatchLoading(true)
    try {
      await seatApi.adminBatchCreate(rid, requests)
      message.success(`成功生成 ${requests.length} 个座位`)
      setBatchModalOpen(false)
      batchForm.resetFields()
      fetchSeats()
    } catch (e: any) {
      message.error(e.response?.data?.message || '批量生成失败')
    } finally {
      setBatchLoading(false)
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
        <Space>
          <Button
            icon={<ThunderboltOutlined />}
            onClick={() => {
              if (!selectedRoomId) { message.warning('请先选择自习室'); return }
              batchForm.resetFields()
              batchForm.setFieldsValue({ rows: 4, cols: 6, socketType: 'NONE', windowRows: '1', corridorCols: '1,-1' })
              setBatchModalOpen(true)
            }}
          >批量生成座位</Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={handleCreate}>新增座位</Button>
        </Space>
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
              { value: 'TRACK', label: '🔌 移动导轨' },
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
      {/* 批量生成 Modal */}
      <Modal
        title="批量生成座位"
        open={batchModalOpen}
        onOk={handleBatchGenerate}
        confirmLoading={batchLoading}
        onCancel={() => setBatchModalOpen(false)}
        destroyOnClose
        width={480}
      >
        <Alert
          message="系统按行列矩阵自动生成座位，编号格式 A1、A2…B1、B2…"
          type="info"
          showIcon
          style={{ marginBottom: 16 }}
        />
        <Form form={batchForm} layout="vertical">
          <Space style={{ width: '100%' }} size={16}>
            <Form.Item name="rows" label="行数" rules={[{ required: true }]} style={{ flex: 1, marginBottom: 8 }}>
              <InputNumber min={1} max={26} style={{ width: '100%' }} placeholder="如 4" />
            </Form.Item>
            <Form.Item name="cols" label="列数" rules={[{ required: true }]} style={{ flex: 1, marginBottom: 8 }}>
              <InputNumber min={1} max={30} style={{ width: '100%' }} placeholder="如 6" />
            </Form.Item>
          </Space>
          <Form.Item name="socketType" label="默认插座类型" rules={[{ required: true }]}>
            <Select options={[
              { value: 'NONE', label: '无插座' },
              { value: 'FIXED', label: '⚡ 固定插座' },
              { value: 'TRACK', label: '🔌 移动导轨插座' },
            ]} />
          </Form.Item>
          <Divider plain style={{ margin: '8px 0' }}>位置自动标记规则</Divider>
          <Form.Item
            name="windowRows"
            label="靠窗行（逗号分隔行号）"
            extra="如输入 1 则第1行为靠窗座位，留空则不标记靠窗"
          >
            <Input placeholder="1" />
          </Form.Item>
          <Form.Item
            name="corridorCols"
            label="靠走廊列（逗号分隔，-1 表示最后一列）"
            extra="如输入 1,-1 则第1列和最后一列为靠走廊座位"
          >
            <Input placeholder="1,-1" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}

export default SeatManage
