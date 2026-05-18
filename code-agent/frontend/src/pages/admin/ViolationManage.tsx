import React, { useEffect, useState } from 'react'
import { Table, Tag, Select, Button, Space, Card, InputNumber, message } from 'antd'
import { violationApi } from '../../services/violation'
import { checkInApi } from '../../services/checkin'
import type { ViolationRecord } from '../../services/violation'

const typeMap: Record<string, { color: string; label: string }> = {
  CHECK_IN_TIMEOUT: { color: 'red', label: '超时未签到' },
}

const ViolationManage: React.FC = () => {
  const [violations, setViolations] = useState<ViolationRecord[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(false)
  const [typeFilter, setTypeFilter] = useState<string | undefined>()
  const [userIdFilter, setUserIdFilter] = useState<number | undefined>()

  // 签到编码
  const [codeRoomId, setCodeRoomId] = useState<number | null>(null)
  const [code, setCode] = useState('')

  const fetchViolations = async (p = page) => {
    setLoading(true)
    try {
      const res = await violationApi.adminList({ page: p, size: 20, type: typeFilter, userId: userIdFilter })
      if (res.data.code === 200) {
        setViolations(res.data.data.records)
        setTotal(res.data.data.total)
      }
    } finally { setLoading(false) }
  }

  useEffect(() => { fetchViolations() }, [])

  const handleGetCode = async () => {
    if (!codeRoomId) { message.warning('请输入自习室ID'); return }
    try {
      const res = await checkInApi.adminGetCode(codeRoomId)
      if (res.data.code === 200) setCode(res.data.data.code)
    } catch (e: any) { message.error(e.response?.data?.message || '获取失败') }
  }

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '用户ID', dataIndex: 'userId', key: 'userId', width: 80 },
    { title: '预约ID', dataIndex: 'reservationId', key: 'reservationId', width: 80 },
    { title: '类型', dataIndex: 'type', key: 'type', width: 120, render: (t: string) => <Tag color={typeMap[t]?.color}>{typeMap[t]?.label || t}</Tag> },
    { title: '时间', dataIndex: 'createdAt', key: 'createdAt' },
  ]

  return (
    <div>
      <h2>违约管理</h2>
      <Space style={{ marginBottom: 16 }}>
        <Select placeholder="类型筛选" allowClear style={{ width: 140 }} value={typeFilter}
          onChange={(v) => { setTypeFilter(v); setPage(1) }}
          options={Object.entries(typeMap).map(([k, v]) => ({ value: k, label: v.label }))} />
        <InputNumber placeholder="用户ID" value={userIdFilter}
          onChange={(v) => { setUserIdFilter(v ?? undefined); setPage(1) }} />
        <Button onClick={() => fetchViolations()}>查询</Button>
      </Space>

      <Table dataSource={violations} columns={columns} rowKey="id" loading={loading}
        pagination={{ current: page, total, pageSize: 20, onChange: (p) => { setPage(p); fetchViolations(p) } }} />

      <Card title="今日签到编码" style={{ marginTop: 24 }}>
        <Space>
          <InputNumber placeholder="自习室ID" value={codeRoomId} onChange={(v) => setCodeRoomId(v)} />
          <Button type="primary" onClick={handleGetCode}>获取编码</Button>
          {code && <span style={{ fontSize: 24, fontWeight: 'bold', letterSpacing: 4, color: '#1890ff' }}>{code}</span>}
        </Space>
      </Card>
    </div>
  )
}

export default ViolationManage
