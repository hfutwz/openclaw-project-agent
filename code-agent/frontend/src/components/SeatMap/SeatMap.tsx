import React from 'react'
import { Tooltip } from 'antd'
import type { Seat } from '../../services/room'

interface SeatMapProps {
  seats: Seat[]
  maxRow: number
  maxCol: number
  onSeatClick?: (seat: Seat) => void
}

const SOCKET_ICONS: Record<string, string> = {
  NONE: '',
  FIXED: '⚡',
  TRACK: '🔌',
}

const POSITION_ICONS: Record<string, string> = {
  WINDOW: '🪟',
  CORRIDOR: '🚶',
  MIDDLE: '',
}

const STATUS_COLORS: Record<string, { bg: string; border: string; text: string }> = {
  AVAILABLE: { bg: '#f6ffed', border: '#b7eb8f', text: '#52c41a' },
  DISABLED: { bg: '#fff1f0', border: '#ffa39e', text: '#ff4d4f' },
  OCCUPIED: { bg: '#f5f5f5', border: '#d9d9d9', text: '#999' },
}

const SeatMap: React.FC<SeatMapProps> = ({ seats, maxRow, maxCol, onSeatClick }) => {
  // Build a 2D grid
  const grid: (Seat | null)[][] = Array.from({ length: maxRow }, () =>
    Array.from({ length: maxCol }, () => null)
  )
  seats.forEach(seat => {
    if (seat.rowNum >= 1 && seat.rowNum <= maxRow && seat.colNum >= 1 && seat.colNum <= maxCol) {
      grid[seat.rowNum - 1][seat.colNum - 1] = seat
    }
  })

  const getSeatStatus = (seat: Seat): string => {
    if (seat.status === 'DISABLED') return 'DISABLED'
    if (!seat.isAvailable) return 'OCCUPIED'
    return 'AVAILABLE'
  }

  return (
    <div>
      {/* Legend */}
      <div style={{ display: 'flex', gap: 16, marginBottom: 16, fontSize: 13, color: '#666' }}>
        <span>
          <span style={{ display: 'inline-block', width: 14, height: 14, background: '#f6ffed', border: '1px solid #b7eb8f', borderRadius: 2, verticalAlign: 'middle', marginRight: 4 }} />
          可选
        </span>
        <span>
          <span style={{ display: 'inline-block', width: 14, height: 14, background: '#f5f5f5', border: '1px solid #d9d9d9', borderRadius: 2, verticalAlign: 'middle', marginRight: 4 }} />
          已占
        </span>
        <span>
          <span style={{ display: 'inline-block', width: 14, height: 14, background: '#fff1f0', border: '1px solid #ffa39e', borderRadius: 2, verticalAlign: 'middle', marginRight: 4 }} />
          停用
        </span>
        <span>⚡ 固定插座</span>
        <span>🔌 移动导轨</span>
        <span>🪟 靠窗</span>
        <span>🚶 靠走廊</span>
      </div>

      {/* Grid */}
      <div style={{ display: 'inline-block' }}>
        {grid.map((row, ri) => (
          <div key={ri} style={{ display: 'flex', gap: 6, marginBottom: 6 }}>
            {row.map((seat, ci) => {
              if (!seat) {
                return <div key={ci} style={{ width: 64, height: 48 }} />
              }
              const status = getSeatStatus(seat)
              const colors = STATUS_COLORS[status]
              const isClickable = status === 'AVAILABLE' && onSeatClick

              return (
                <Tooltip
                  key={ci}
                  title={
                    <div>
                      <div>座位: {seat.seatNumber}</div>
                      <div>位置: {POSITION_ICONS[seat.position] || ''} {seat.position}</div>
                      <div>插座: {SOCKET_ICONS[seat.socketType] || '无'}</div>
                      <div>状态: {status === 'AVAILABLE' ? '可选' : status === 'OCCUPIED' ? '已占' : '停用'}</div>
                    </div>
                  }
                >
                  <div
                    onClick={() => isClickable && onSeatClick(seat)}
                    style={{
                      width: 64,
                      height: 48,
                      background: colors.bg,
                      border: `1px solid ${colors.border}`,
                      borderRadius: 4,
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: isClickable ? 'pointer' : 'default',
                      fontSize: 11,
                      color: colors.text,
                      transition: 'all 0.2s',
                      userSelect: 'none',
                    }}
                    onMouseEnter={e => {
                      if (isClickable) {
                        (e.currentTarget as HTMLDivElement).style.transform = 'scale(1.05)'
                        ;(e.currentTarget as HTMLDivElement).style.boxShadow = '0 2px 8px rgba(0,0,0,0.15)'
                      }
                    }}
                    onMouseLeave={e => {
                      (e.currentTarget as HTMLDivElement).style.transform = 'scale(1)'
                      ;(e.currentTarget as HTMLDivElement).style.boxShadow = 'none'
                    }}
                  >
                    <span style={{ fontWeight: 500 }}>{seat.seatNumber}</span>
                    <span style={{ fontSize: 10 }}>
                      {SOCKET_ICONS[seat.socketType]}{POSITION_ICONS[seat.position]}
                    </span>
                  </div>
                </Tooltip>
              )
            })}
          </div>
        ))}
      </div>
    </div>
  )
}

export default SeatMap
