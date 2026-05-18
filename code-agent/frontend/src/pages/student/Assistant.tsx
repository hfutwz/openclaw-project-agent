import React, { useEffect, useRef, useState } from 'react'
import { Card, Input, Button, Typography, Space, Avatar, Spin } from 'antd'
import { SendOutlined, RobotOutlined, UserOutlined } from '@ant-design/icons'
import { assistantApi } from '../../services/assistant'
import type { ChatMessage } from '../../services/assistant'

const { Title } = Typography

const Assistant: React.FC = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([
    { role: 'assistant', content: '你好！我是 SeatFlow 智能助手 🤖\n\n我可以帮你：\n• 查看自习室和空座位\n• 预约/取消预约\n• 查看你的预约和违约记录\n• 签到指引\n\n请问有什么可以帮你的？' }
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [sessionId, setSessionId] = useState<string | undefined>()
  const messagesEndRef = useRef<HTMLDivElement>(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => { scrollToBottom() }, [messages])

  const sendMessage = async () => {
    if (!input.trim() || loading) return

    const userMsg: ChatMessage = { role: 'user', content: input.trim() }
    setMessages(prev => [...prev, userMsg])
    setInput('')
    setLoading(true)

    try {
      const res = await assistantApi.chat(userMsg.content, sessionId)
      if (res.data.code === 200) {
        const data = res.data.data
        setSessionId(data.sessionId)
        setMessages(prev => [...prev, { role: 'assistant', content: data.reply, intent: data.intent }])
      }
    } catch (e: any) {
      setMessages(prev => [...prev, { role: 'assistant', content: '抱歉，出了点问题，请稍后再试 😢' }])
    } finally {
      setLoading(false)
    }
  }

  const quickActions = [
    { label: '📚 查看自习室', message: '有哪些自习室？' },
    { label: '🔍 找座位', message: '有空座位吗？' },
    { label: '📋 我的预约', message: '查看我的预约' },
    { label: '❓ 帮助', message: '帮助' },
  ]

  return (
    <div style={{ maxWidth: 800, margin: '0 auto' }}>
      <Title level={3}>智能助手 🤖</Title>

      <Card
        style={{ height: 'calc(100vh - 220px)', display: 'flex', flexDirection: 'column' }}
        bodyStyle={{ flex: 1, overflow: 'auto', padding: 16 }}
      >
        {/* 消息列表 */}
        <div style={{ flex: 1, overflowY: 'auto', marginBottom: 16 }}>
          {messages.map((msg, idx) => (
            <div key={idx} style={{
              display: 'flex',
              justifyContent: msg.role === 'user' ? 'flex-end' : 'flex-start',
              marginBottom: 12,
            }}>
              {msg.role === 'assistant' && (
                <Avatar icon={<RobotOutlined />} style={{ backgroundColor: '#1890ff', marginRight: 8, flexShrink: 0 }} />
              )}
              <div style={{
                maxWidth: '70%',
                padding: '10px 14px',
                borderRadius: 12,
                background: msg.role === 'user' ? '#1890ff' : '#f5f5f5',
                color: msg.role === 'user' ? '#fff' : '#333',
                whiteSpace: 'pre-wrap',
                fontSize: 14,
                lineHeight: 1.6,
              }}>
                {msg.content}
              </div>
              {msg.role === 'user' && (
                <Avatar icon={<UserOutlined />} style={{ backgroundColor: '#87d068', marginLeft: 8, flexShrink: 0 }} />
              )}
            </div>
          ))}
          {loading && (
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: 12 }}>
              <Avatar icon={<RobotOutlined />} style={{ backgroundColor: '#1890ff', marginRight: 8 }} />
              <div style={{ padding: '10px 14px', borderRadius: 12, background: '#f5f5f5' }}>
                <Spin size="small" /> 思考中...
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* 快捷操作 */}
        <div style={{ marginBottom: 12 }}>
          <Space wrap>
            {quickActions.map((action, idx) => (
              <Button key={idx} size="small" onClick={() => { setInput(action.message) }}
                style={{ borderRadius: 16 }}>
                {action.label}
              </Button>
            ))}
          </Space>
        </div>

        {/* 输入框 */}
        <div style={{ display: 'flex', gap: 8 }}>
          <Input
            size="large"
            placeholder="输入消息，如：有空座位吗？"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onPressEnter={sendMessage}
            disabled={loading}
          />
          <Button type="primary" size="large" icon={<SendOutlined />}
            onClick={sendMessage} loading={loading} />
        </div>
      </Card>
    </div>
  )
}

export default Assistant
