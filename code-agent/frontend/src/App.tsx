import React from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { Spin } from 'antd'
import { useAuth } from './hooks/useAuth'

// Layouts
import StudentLayout from './layouts/StudentLayout'
import AdminLayout from './layouts/AdminLayout'

// Pages
import LoginPage from './pages/Login'
import ForbiddenPage from './pages/Forbidden'
import NotFoundPage from './pages/NotFound'

// Student pages (M2)
import RoomList from './pages/student/RoomList'
import RoomDetailPage from './pages/student/RoomDetailPage'

// Student pages (M3)
import MyReservations from './pages/student/MyReservations'

// Student pages (M4)
import CheckInPage from './pages/student/CheckInPage'
import MyViolations from './pages/student/MyViolations'

// Student pages (M6)
import Assistant from './pages/student/Assistant'

// Admin pages (M2)
import RoomManage from './pages/admin/RoomManage'
import SeatManage from './pages/admin/SeatManage'

// Admin pages (M3)
import ReservationManage from './pages/admin/ReservationManage'

// Admin pages (M4)
import ViolationManage from './pages/admin/ViolationManage'

// Admin pages (M5)
import Dashboard from './pages/admin/Dashboard'
import UserManage from './pages/admin/UserManage'
import RoleManage from './pages/admin/RoleManage'
import SystemConfigPage from './pages/admin/SystemConfigPage'
import CheckInCodeManage from './pages/admin/CheckInCodeManage'

// Student pages (M5)
import Search from './pages/student/Search'

// Admin placeholder pages (removed, implemented in M5)

// 路由守卫：需要登录
const RequireAuth: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { loading, isLoggedIn } = useAuth()
  if (loading) {
    return <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}><Spin size="large" /></div>
  }
  if (!isLoggedIn()) {
    return <Navigate to="/login" replace />
  }
  return <>{children}</>
}

// 路由守卫：仅管理员
const RequireAdmin: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { userInfo } = useAuth()
  if (userInfo?.userType !== 'ADMIN') {
    return <Navigate to="/403" replace />
  }
  return <>{children}</>
}

const App: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        {/* 公开路由 */}
        <Route path="/login" element={<LoginPage />} />

        {/* 学生端路由 */}
        <Route path="/student" element={
          <RequireAuth>
            <StudentLayout />
          </RequireAuth>
        }>
          <Route index element={<Navigate to="rooms" replace />} />
          <Route path="rooms" element={<RoomList />} />
          <Route path="rooms/:id" element={<RoomDetailPage />} />
          <Route path="search" element={<Search />} />
          <Route path="reservations" element={<MyReservations />} />
          <Route path="check-in" element={<CheckInPage />} />
          <Route path="violations" element={<MyViolations />} />
          <Route path="assistant" element={<Assistant />} />
        </Route>

        {/* 管理端路由 */}
        <Route path="/admin" element={
          <RequireAuth>
            <RequireAdmin>
              <AdminLayout />
            </RequireAdmin>
          </RequireAuth>
        }>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="rooms" element={<RoomManage />} />
          <Route path="seats" element={<SeatManage />} />
          <Route path="seats/:roomId" element={<SeatManage />} />
          <Route path="reservations" element={<ReservationManage />} />
          <Route path="violations" element={<ViolationManage />} />
          <Route path="users" element={<UserManage />} />
          <Route path="roles" element={<RoleManage />} />
          <Route path="config" element={<SystemConfigPage />} />
          <Route path="check-in-codes" element={<CheckInCodeManage />} />
        </Route>

        {/* 错误页面 */}
        <Route path="/403" element={<ForbiddenPage />} />
        <Route path="/404" element={<NotFoundPage />} />

        {/* 默认跳转 */}
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
