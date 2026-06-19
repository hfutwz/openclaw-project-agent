import React, { useEffect, useState } from 'react'
import { Table, Button, Modal, Form, Input, InputNumber, Select, Tag, Space, message, Popconfirm, Tooltip } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, SafetyOutlined } from '@ant-design/icons'
import { roleApi, userApi } from '../../services/admin'
import type { RoleItem, UserItem } from '../../services/admin'

const UserManage: React.FC = () => {
  const [users, setUsers] = useState<UserItem[]>([])
  const [roles, setRoles] = useState<RoleItem[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [roleModalOpen, setRoleModalOpen] = useState(false)
  const [editing, setEditing] = useState<UserItem | null>(null)
  const [assigning, setAssigning] = useState<UserItem | null>(null)
  const [form] = Form.useForm()
  const [roleForm] = Form.useForm()

  const fetchUsers = async (p = page) => {
    setLoading(true)
    try {
      const res = await userApi.list({ page: p, size: 20 })
      if (res.data.code === 200) { setUsers(res.data.data.records); setTotal(res.data.data.total) }
    } finally { setLoading(false) }
  }

  const fetchRoles = async () => {
    const res = await roleApi.list()
    if (res.data.code === 200) setRoles(res.data.data)
  }

  useEffect(() => { fetchUsers(); fetchRoles() }, [])

  const roleOptions = roles.map(role => ({
    value: role.id,
    label: `${role.name}（${role.code}）`,
  }))

  const handleCreate = () => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ userType: 'STUDENT', roleIds: [] })
    setModalOpen(true)
  }
  const handleEdit = (u: UserItem) => {
    setEditing(u)
    form.setFieldsValue({ realName: u.realName, email: u.email, departmentId: u.departmentId, userType: u.userType, roleIds: u.roleIds })
    setModalOpen(true)
  }

  const handleAssign = (u: UserItem) => {
    setAssigning(u)
    roleForm.setFieldsValue({ roleIds: u.roleIds || [] })
    setRoleModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editing) { await userApi.update(editing.id, values); message.success('更新成功') }
      else { await userApi.create(values); message.success('创建成功') }
      setModalOpen(false); fetchUsers()
    } catch (e: any) { message.error(e.response?.data?.message || '操作失败') }
  }

  const handleDelete = async (id: number) => {
    try { await userApi.delete(id); message.success('删除成功'); fetchUsers() }
    catch (e: any) { message.error(e.response?.data?.message || '删除失败') }
  }

  const handleRoleSubmit = async () => {
    if (!assigning) return
    const values = await roleForm.validateFields()
    try {
      await userApi.assignRoles(assigning.id, values.roleIds || [])
      message.success('角色已更新')
      setRoleModalOpen(false)
      setAssigning(null)
      fetchUsers()
    } catch (e: any) {
      message.error(e.response?.data?.message || '角色更新失败')
    }
  }

  const columns = [
    { title: 'ID', dataIndex: 'id', width: 60 },
    { title: '用户名', dataIndex: 'username' },
    { title: '姓名', dataIndex: 'realName' },
    { title: '类型', dataIndex: 'userType', width: 80, render: (t: string) => <Tag color={t === 'ADMIN' ? 'red' : 'blue'}>{t === 'ADMIN' ? '管理员' : '学生'}</Tag> },
    { title: '院系', dataIndex: 'departmentName', render: (v: string) => v || '-' },
    { title: '角色', dataIndex: 'roles', render: (userRoles: string[]) => userRoles?.length ? userRoles.map((r, i) => <Tag key={i}>{r}</Tag>) : '-' },
    { title: '操作', key: 'action', render: (_: any, r: UserItem) => (
      <Space>
        <Tooltip title="编辑资料">
          <Button size="small" icon={<EditOutlined />} onClick={() => handleEdit(r)} />
        </Tooltip>
        <Tooltip title="分配角色">
          <Button size="small" icon={<SafetyOutlined />} onClick={() => handleAssign(r)} />
        </Tooltip>
        <Popconfirm title="确认删除？" onConfirm={() => handleDelete(r.id)}>
          <Button size="small" danger icon={<DeleteOutlined />} />
        </Popconfirm>
      </Space>
    )},
  ]

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <h2>用户管理</h2>
        <Button type="primary" icon={<PlusOutlined />} onClick={handleCreate}>新增用户</Button>
      </div>
      <Table dataSource={users} columns={columns} rowKey="id" loading={loading}
        pagination={{ current: page, total, pageSize: 20, onChange: (p) => { setPage(p); fetchUsers(p) } }} />
      <Modal title={editing ? '编辑用户' : '新增用户'} open={modalOpen} onOk={handleSubmit} onCancel={() => setModalOpen(false)} destroyOnClose>
        <Form form={form} layout="vertical">
          {!editing && <Form.Item name="username" label="用户名" rules={[{ required: true }]}><Input /></Form.Item>}
          {!editing && <Form.Item name="password" label="密码" rules={[{ required: true, min: 6 }]}><Input.Password /></Form.Item>}
          <Form.Item name="realName" label="姓名"><Input /></Form.Item>
          <Form.Item name="email" label="邮箱"><Input /></Form.Item>
          <Form.Item name="departmentId" label="院系ID"><InputNumber min={1} style={{ width: '100%' }} placeholder="全校共享/管理员可留空" /></Form.Item>
          <Form.Item name="userType" label="类型"><Select options={[{ value: 'STUDENT', label: '学生' }, { value: 'ADMIN', label: '管理员' }]} /></Form.Item>
          <Form.Item name="roleIds" label="角色">
            <Select
              mode="multiple"
              allowClear
              placeholder="请选择角色"
              options={roleOptions}
            />
          </Form.Item>
        </Form>
      </Modal>
      <Modal
        title={`分配角色：${assigning?.realName || assigning?.username || ''}`}
        open={roleModalOpen}
        onOk={handleRoleSubmit}
        onCancel={() => setRoleModalOpen(false)}
        destroyOnClose
      >
        <Form form={roleForm} layout="vertical">
          <Form.Item name="roleIds" label="角色">
            <Select
              mode="multiple"
              allowClear
              placeholder="请选择角色"
              options={roleOptions}
            />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}

export default UserManage
