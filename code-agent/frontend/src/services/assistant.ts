import api from './api'

export interface ChatMessage {
  role: 'user' | 'assistant'
  content: string
  intent?: string
}

export interface ChatResponseData {
  reply: string
  sessionId: string
  intent: string
}

export const assistantApi = {
  chat: (message: string, sessionId?: string) =>
    api.post<{ code: number; data: ChatResponseData }>('/assistant/chat', { message, sessionId }),
}
