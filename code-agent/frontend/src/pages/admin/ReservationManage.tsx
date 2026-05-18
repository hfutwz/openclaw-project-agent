import React, { useEffect, useState } from 'react'
import { Table, Tag, Button, Select, DatePicker, Space, message, Popconfirm } from 'antd'
import { CloseCircleOutlined } from '@ant-design/icons'
import { reservationApi } from '../../services/reservation'
import type { Reservation } from '../../services/reservation'

const statusMap: Record<string, { color: string; label: string }> = {
  PENDING: { color: 'orange', label: '待签到' },
  CHECKED_IN: { color: 'blue', label: '已签到' },
  COMPLETED: { color: 'green', label: '已完成' },
  CANCELLED: { color: 'default', label: '已取消' },
}

const ReservationManage: React.FC = () => {
  const [reservations, setReservations] = useState<Reservation[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(false)
  const [statusFilter, setStatusFilter] = useState<string | undefined>()
  const [dateFilter, setDateFilter] = useState<string | undefined>()

  const fetchReservations = async (p = page) => {
    setLoading(true)
    try {
      const res = await reservationApi.adminList({
        page: p, size: 20, status: statusFilter, date: dateFilter,
      })
      if (res.data.code === 200) {
        setReservations(res.data.data.records)
        setTotal(res.data.data.total)
      }
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchReservations() }, [])

  const handleCancel = async (id: number) => {
    try {
      const res = await reservationApi.adminCancel(id)
      if (res.data.code === 200) {
        message.success('取消成功')
        fetchReservations()
      }
    } catch (e: any) {
      message.error(e.response?.data?.message || '取消失败')
    }
  }

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '自习室', dataIndex: 'roomName', key: 'roomName' },
    { title: '座位', dataIndex: 'seatNumber', key: 'seatNumber', width: 80 },
    { title: '日期', dataIndex: 'date', key: 'date', width: 110 },
    { title: '时段', key: 'time', width: 120, render: (_: any, r: Reservation) => `${r.startTime?.slice(0,5)}-${r.endTime?.slice(0,5)}` },
    { title: '状态', dataIndex: 'status', key: 'status', width: 90, render: (s: string) => <Tag color={statusMap[s]?.color}>{statusMap[s]?.label || s}</Tag> },
    { title: '取消方', dataIndex: 'cancelledBy', key: 'cancelledBy', width: 80 },
    { title: '操作', key: 'action', width: 80, render: (_: any, r: Reservation) => (
      (r.status === 'PENDING' || r.status === 'CHECKED_IN') ? (
        <Popconfirm title="确认取消此预约？" onConfirm={() => handleCancel(r.id)}>
          <Button size="small" danger icon={<CloseCircleOutlined />}>取消</Button>
        </Popconfirm>
      ) : null
    )},
  ]

  return (
    <div>
      <h2>预约管理</h2>
      <Space style={{ marginBottom: 16 }}>
        <Select
          placeholder="状态筛选"
          allowClear
          style={{ width: 120 }}
          value={statusFilter}
          onChange={(v) => { setStatusFilter(v); setPage(1) }}
          options={Object.entries(statusMap).map(([k, v]) => ({ value: k, label: v.label }))}
        />
        <DatePicker
          placeholder="日期筛选"
          onChange={(_, ds) => { setDateFilter(ds as string || undefined); setPage(1) }}
        />
        <Button onClick={() => fetchReservations()}>查询</Button>
      </Space>

      <Table
        dataSource={reservations}
        columns={columns}
        rowKey="id"
        loading={loading}
        pagination={{ current: page, total, pageSize: 20, onChange: (p) => { setPage(p); fetchReservations(p) } }}
      />
    </div>
  )
}

export default ReservationManage
