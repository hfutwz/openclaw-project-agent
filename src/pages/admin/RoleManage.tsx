import React, { useEffect, useState } from 'react'
import { Table, Button, Modal, Form, Input, Tag, Space, message, Popconfirm, Checkbox } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { roleApi } from '../../services/admin'
import type { RoleItem, PermissionItem } from '../../services/admin'

const RoleManage: React.FC = () => {
  const [roles, setRoles] = useState<RoleItem[]>([])
  const [permissions, setPermissions] = useState<PermissionItem[]>([])
  const [loading, setLoading] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<RoleItem | null>(null)
  const [form] = Form.useForm()

  const fetchRoles = async () => {
    setLoading(true)
    try {
      const res = await roleApi.list()
      if (res.data.code === 200) setRoles(res.data.data)
    } finally { setLoading(false) }
  }

  const fetchPermissions = async () => {
    try {
      const res = await roleApi.permissions()
      if (res.data.code === 200) setPermissions(res.data.data)
    } catch (e) { console.error(e) }
  }

  useEffect(() => { fetchRoles(); fetchPermissions() }, [])

  const handleCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true) }
  const handleEdit = (r: RoleItem) => {
    setEditing(r)
    form.setFieldsValue({ name: r.name, description: r.description, permissionIds: r.permissionIds })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editing) { await roleApi.update(editing.id, values); message.success('更新成功') }
      else { await roleApi.create(values); message.success('创建成功') }
      setModalOpen(false); fetchRoles()
    } catch (e: any) { message.error(e.response?.data?.message || '操作失败') }
  }

  const handleDelete = async (id: number) => {
    try { await roleApi.delete(id); message.success('删除成功'); fetchRoles() }
    catch (e: any) { message.error(e.response?.data?.message || '删除失败') }
  }

  const columns = [
    { title: 'ID', dataIndex: 'id', width: 60 },
    { title: '名称', dataIndex: 'name' },
    { title: '编码', dataIndex: 'code', render: (c: string) => <Tag>{c}</Tag> },
    { title: '描述', dataIndex: 'description' },
    { title: '权限', dataIndex: 'permissions', render: (perms: PermissionItem[]) => perms?.map((p, i) => <Tag key={i} color="blue">{p.name}</Tag>) },
    { title: '操作', key: 'action', render: (_: any, r: RoleItem) => (
      <Space>
        <Button size="small" icon={<EditOutlined />} onClick={() => handleEdit(r)} />
        <Popconfirm title="确认删除？" onConfirm={() => handleDelete(r.id)}><Button size="small" danger icon={<DeleteOutlined />} /></Popconfirm>
      </Space>
    )},
  ]

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <h2>角色管理</h2>
        <Button type="primary" icon={<PlusOutlined />} onClick={handleCreate}>新增角色</Button>
      </div>
      <Table dataSource={roles} columns={columns} rowKey="id" loading={loading} pagination={false} />
      <Modal title={editing ? '编辑角色' : '新增角色'} open={modalOpen} onOk={handleSubmit} onCancel={() => setModalOpen(false)} destroyOnClose width={600}>
        <Form form={form} layout="vertical">
          {!editing && <Form.Item name="code" label="编码" rules={[{ required: true }]}><Input /></Form.Item>}
          <Form.Item name="name" label="名称" rules={[{ required: true }]}><Input /></Form.Item>
          <Form.Item name="description" label="描述"><Input /></Form.Item>
          <Form.Item name="permissionIds" label="权限">
            <Checkbox.Group options={permissions.map(p => ({ label: p.name, value: p.id }))} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}

export default RoleManage
