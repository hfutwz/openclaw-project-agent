import React, { useEffect, useState } from 'react'
import { Table, Button, Modal, Form, Input, TimePicker, Select, Tag, Space, message, Popconfirm } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { roomApi } from '../../services/room'
import type { Room } from '../../services/room'
import dayjs from 'dayjs'

const DEPARTMENTS = [
  { value: 1, label: '计算机学院' },
  { value: 2, label: '外国语学院' },
]

const RoomManage: React.FC = () => {
  const [rooms, setRooms] = useState<Room[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editingRoom, setEditingRoom] = useState<Room | null>(null)
  const [form] = Form.useForm()

  const fetchRooms = async (p = page) => {
    setLoading(true)
    try {
      const res = await roomApi.adminList(p, 20)
      if (res.data.code === 200) {
        setRooms(res.data.data.records)
        setTotal(res.data.data.total)
      }
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchRooms() }, [])

  const handleCreate = () => {
    setEditingRoom(null)
    form.resetFields()
    form.setFieldsValue({ openTime: dayjs('07:00', 'HH:mm'), closeTime: dayjs('22:00', 'HH:mm'), departmentId: null })
    setModalOpen(true)
  }

  const handleEdit = (room: Room) => {
    setEditingRoom(room)
    form.setFieldsValue({
      name: room.name,
      location: room.location,
      departmentId: room.departmentId,
      openTime: room.openTime ? dayjs(room.openTime, 'HH:mm') : null,
      closeTime: room.closeTime ? dayjs(room.closeTime, 'HH:mm') : null,
      status: room.status,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    const data = {
      ...values,
      openTime: values.openTime?.format('HH:mm'),
      closeTime: values.closeTime?.format('HH:mm'),
    }
    try {
      if (editingRoom) {
        await roomApi.adminUpdate(editingRoom.id, data)
        message.success('更新成功')
      } else {
        await roomApi.adminCreate(data)
        message.success('创建成功')
      }
      setModalOpen(false)
      fetchRooms()
    } catch (e: any) {
      message.error(e.response?.data?.message || '操作失败')
    }
  }

  const handleDelete = async (id: number) => {
    try {
      await roomApi.adminDelete(id)
      message.success('删除成功')
      fetchRooms()
    } catch (e: any) {
      message.error(e.response?.data?.message || '删除失败')
    }
  }

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '位置', dataIndex: 'location', key: 'location' },
    { title: '院系', dataIndex: 'departmentName', key: 'departmentName', render: (v: string) => v || '全校共享' },
    { title: '开放时间', key: 'time', render: (_: any, r: Room) => `${r.openTime?.slice(0,5)}-${r.closeTime?.slice(0,5)}` },
    { title: '状态', dataIndex: 'status', key: 'status', render: (s: string) => <Tag color={s === 'OPEN' ? 'green' : 'red'}>{s === 'OPEN' ? '开放' : '关闭'}</Tag> },
    { title: '座位', key: 'seats', render: (_: any, r: Room) => `${r.availableSeats}/${r.totalSeats}` },
    { title: '操作', key: 'action', render: (_: any, r: Room) => (
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
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <h2>自习室管理</h2>
        <Button type="primary" icon={<PlusOutlined />} onClick={handleCreate}>新增自习室</Button>
      </div>

      <Table
        dataSource={rooms}
        columns={columns}
        rowKey="id"
        loading={loading}
        pagination={{ current: page, total, pageSize: 20, onChange: (p) => { setPage(p); fetchRooms(p) } }}
      />

      <Modal
        title={editingRoom ? '编辑自习室' : '新增自习室'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        destroyOnClose
      >
        <Form form={form} layout="vertical">
          <Form.Item name="name" label="名称" rules={[{ required: true, message: '请输入名称' }]}>
            <Input />
          </Form.Item>
          <Form.Item name="location" label="位置">
            <Input />
          </Form.Item>
          <Form.Item name="departmentId" label="所属院系">
            <Select
              allowClear
              placeholder="全校共享"
              options={[...DEPARTMENTS, { value: null, label: '全校共享' }]}
            />
          </Form.Item>
          <Form.Item name="openTime" label="开放开始时间">
            <TimePicker format="HH:mm" />
          </Form.Item>
          <Form.Item name="closeTime" label="开放结束时间">
            <TimePicker format="HH:mm" />
          </Form.Item>
          {editingRoom && (
            <Form.Item name="status" label="状态">
              <Select options={[{ value: 'OPEN', label: '开放' }, { value: 'CLOSED', label: '关闭' }]} />
            </Form.Item>
          )}
        </Form>
      </Modal>
    </div>
  )
}

export default RoomManage
