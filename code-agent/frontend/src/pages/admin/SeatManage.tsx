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

  // 批量生成座位（左上角+右下角坐标方式）
  const handleBatchGenerate = async () => {
    const values = await batchForm.validateFields()
    const { startRow, startCol, endRow, endCol, socketType, windowRow, corridorCol } = values

    if (endRow < startRow || endCol < startCol) {
      message.error('右下角坐标必须大于等于左上角坐标')
      return
    }

    const totalRows = endRow - startRow + 1
    const totalCols = endCol - startCol + 1
    const rowLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    const requests: object[] = []

    for (let r = startRow; r <= endRow; r++) {
      for (let c = startCol; c <= endCol; c++) {
        // 编号：行用字母（从A开始按实际行号），列用数字
        const rowLetter = rowLetters[r - 1] || `R${r}`
        const seatNumber = `${rowLetter}${c}`
        let position = 'MIDDLE'
        if (windowRow && r === windowRow) position = 'WINDOW'
        else if (corridorCol && (c === corridorCol || c === endCol + startCol - corridorCol)) position = 'CORRIDOR'
        requests.push({ seatNumber, rowNum: r, colNum: c, socketType, position, status: 'AVAILABLE' })
      }
    }

    setBatchLoading(true)
    try {
      await seatApi.adminBatchCreate(rid, requests)
      message.success(`成功生成 ${requests.length} 个座位（${totalRows}行 × ${totalCols}列）`)
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
              batchForm.setFieldsValue({ startRow: 1, startCol: 1, endRow: 5, endCol: 7, socketType: 'NONE', windowRow: 1, corridorCol: 1 })
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
        width={500}
      >
        <Alert
          message="输入左上角和右下角坐标，系统自动生成矩形区域内所有座位"
          type="info"
          showIcon
          style={{ marginBottom: 16 }}
        />
        <Form form={batchForm} layout="vertical">
          <Divider plain style={{ margin: '4px 0 12px' }}>📍 区域坐标</Divider>
          <div style={{ display: 'flex', gap: 24 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 500, marginBottom: 8, color: '#52c41a' }}>↖ 左上角</div>
              <Space>
                <Form.Item name="startRow" label="行" rules={[{ required: true }]} style={{ marginBottom: 8 }}>
                  <InputNumber min={1} max={26} style={{ width: 70 }} placeholder="1" />
                </Form.Item>
                <Form.Item name="startCol" label="列" rules={[{ required: true }]} style={{ marginBottom: 8 }}>
                  <InputNumber min={1} max={50} style={{ width: 70 }} placeholder="1" />
                </Form.Item>
              </Space>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 500, marginBottom: 8, color: '#ff4d4f' }}>↘ 右下角</div>
              <Space>
                <Form.Item name="endRow" label="行" rules={[{ required: true }]} style={{ marginBottom: 8 }}>
                  <InputNumber min={1} max={26} style={{ width: 70 }} placeholder="5" />
                </Form.Item>
                <Form.Item name="endCol" label="列" rules={[{ required: true }]} style={{ marginBottom: 8 }}>
                  <InputNumber min={1} max={50} style={{ width: 70 }} placeholder="7" />
                </Form.Item>
              </Space>
            </div>
          </div>
          <Form.Item
            noStyle
            shouldUpdate={(prev, cur) =>
              prev.startRow !== cur.startRow || prev.startCol !== cur.startCol ||
              prev.endRow !== cur.endRow || prev.endCol !== cur.endCol
            }
          >
            {({ getFieldValue }) => {
              const sr = getFieldValue('startRow') || 0
              const sc = getFieldValue('startCol') || 0
              const er = getFieldValue('endRow') || 0
              const ec = getFieldValue('endCol') || 0
              const count = er >= sr && ec >= sc ? (er - sr + 1) * (ec - sc + 1) : 0
              return count > 0 ? (
                <div style={{ textAlign: 'center', marginBottom: 12, color: '#1890ff', fontWeight: 500 }}>
                  将生成 {er - sr + 1} 行 × {ec - sc + 1} 列 = <span style={{ fontSize: 16 }}>{count}</span> 个座位
                </div>
              ) : null
            }}
          </Form.Item>
          <Divider plain style={{ margin: '4px 0 12px' }}>⚙️ 属性设置</Divider>
          <Form.Item name="socketType" label="默认插座类型" rules={[{ required: true }]}>
            <Select options={[
              { value: 'NONE', label: '无插座' },
              { value: 'FIXED', label: '⚡ 固定插座' },
              { value: 'TRACK', label: '🔌 移动导轨插座' },
            ]} />
          </Form.Item>
          <Divider plain style={{ margin: '4px 0 12px' }}>🏷️ 位置自动标记（可选）</Divider>
          <Space style={{ width: '100%' }} size={16}>
            <Form.Item
              name="windowRow"
              label="靠窗行号"
              extra="留空不标记"
              style={{ flex: 1 }}
            >
              <InputNumber min={1} max={26} style={{ width: '100%' }} placeholder="如 1" />
            </Form.Item>
            <Form.Item
              name="corridorCol"
              label="靠走廊列号"
              extra="对称列自动标记"
              style={{ flex: 1 }}
            >
              <InputNumber min={1} max={50} style={{ width: '100%' }} placeholder="如 1" />
            </Form.Item>
          </Space>
        </Form>
      </Modal>
    </div>
  )
}

export default SeatManage
