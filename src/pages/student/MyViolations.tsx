import React, { useEffect, useState } from 'react'
import { List, Tag, Empty, Spin, Typography, Card } from 'antd'
import { violationApi } from '../../services/violation'
import type { ViolationRecord } from '../../services/violation'

const { Title, Text } = Typography

const typeMap: Record<string, { color: string; label: string }> = {
  CHECK_IN_TIMEOUT: { color: 'red', label: '超时未签到' },
}

const MyViolations: React.FC = () => {
  const [violations, setViolations] = useState<ViolationRecord[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetch = async () => {
      try {
        const res = await violationApi.listMy()
        if (res.data.code === 200) setViolations(res.data.data)
      } catch (e) { console.error(e) }
      finally { setLoading(false) }
    }
    fetch()
  }, [])

  if (loading) return <div style={{ textAlign: 'center', padding: 100 }}><Spin size="large" /></div>

  return (
    <div>
      <Title level={3}>违约记录</Title>
      <Card>
        <Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
          超时未签到将自动记录违约，多次违约可能影响预约权限。
        </Text>
      </Card>
      {violations.length === 0 ? (
        <Empty description="暂无违约记录" style={{ marginTop: 24 }} />
      ) : (
        <List
          dataSource={violations}
          style={{ marginTop: 16 }}
          renderItem={(item) => (
            <List.Item>
              <List.Item.Meta
                title={
                  <span>
                    <Tag color={typeMap[item.type]?.color || 'default'}>
                      {typeMap[item.type]?.label || item.type}
                    </Tag>
                    预约 #{item.reservationId}
                  </span>
                }
                description={`时间: ${item.createdAt}`}
              />
            </List.Item>
          )}
        />
      )}
    </div>
  )
}

export default MyViolations
