import React, { useEffect, useState } from 'react'
import { Card, Form, InputNumber, Button, message, Spin, Typography } from 'antd'
import { configApi } from '../../services/admin'
import type { SystemConfigItem } from '../../services/admin'

const { Title } = Typography

const SystemConfigPage: React.FC = () => {
  const [configs, setConfigs] = useState<SystemConfigItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [form] = Form.useForm()

  const fetchConfigs = async () => {
    try {
      const res = await configApi.list()
      if (res.data.code === 200) {
        setConfigs(res.data.data)
        const formValues: Record<string, number> = {}
        res.data.data.forEach((c: SystemConfigItem) => { formValues[c.configKey] = Number(c.configValue) })
        form.setFieldsValue(formValues)
      }
    } finally { setLoading(false) }
  }

  useEffect(() => { fetchConfigs() }, [])

  const handleSave = async () => {
    const values = await form.validateFields()
    setSaving(true)
    try {
      const updateData: Record<string, string> = {}
      Object.entries(values).forEach(([k, v]) => { updateData[k] = String(v) })
      await configApi.batchUpdate(updateData)
      message.success('保存成功')
    } catch (e: any) { message.error(e.response?.data?.message || '保存失败') }
    finally { setSaving(false) }
  }

  if (loading) return <div style={{ textAlign: 'center', padding: 100 }}><Spin size="large" /></div>

  const labelMap: Record<string, string> = {
    max_reservation_hours: '单次最大预约小时数',
    check_in_remind_before_min: '签到提前提醒（分钟）',
    check_in_warn_after_min: '签到逾期警告（分钟）',
    check_in_cancel_after_min: '签到逾期取消（分钟）',
  }

  return (
    <div>
      <Title level={3}>系统参数</Title>
      <Card>
        <Form form={form} layout="vertical" style={{ maxWidth: 400 }}>
          {configs.map(c => (
            <Form.Item key={c.configKey} name={c.configKey} label={labelMap[c.configKey] || c.description || c.configKey}>
              <InputNumber min={1} max={999} style={{ width: '100%' }} />
            </Form.Item>
          ))}
          <Form.Item>
            <Button type="primary" onClick={handleSave} loading={saving}>保存</Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default SystemConfigPage
