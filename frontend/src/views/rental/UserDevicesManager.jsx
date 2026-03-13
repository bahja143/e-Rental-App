import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert } from 'react-bootstrap';
import { getUserDevices, createUserDevice, updateUserDevice, deleteUserDevice, getUsers } from '../../services/rentalApi';

const emptyForm = {
  user_id: '',
  device_type: '',
  fcm_token: ''
};

const UserDevicesManager = () => {
  const [rows, setRows] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, totalItems: 0 });
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ error: '', success: '' });

  const loadUsers = useCallback(async () => {
    try {
      const res = await getUsers({ page: 1, limit: 200 });
      setUsers(res.data?.data ?? []);
    } catch (e) {
      console.error(e);
    }
  }, []);

  const loadRows = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getUserDevices({ page, limit: 10, search: search.trim() || undefined });
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, totalItems: p.totalItems ?? 0 });
    } catch (e) {
      console.error(e);
      setMessage({ error: 'Failed to load user devices.', success: '' });
    } finally {
      setLoading(false);
    }
  }, [page, search]);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  useEffect(() => {
    loadRows();
  }, [loadRows]);

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setShowModal(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({
      user_id: row.user_id ?? '',
      device_type: row.device_type ?? '',
      fcm_token: row.fcm_token ?? ''
    });
    setShowModal(true);
  };

  const save = async () => {
    setSaving(true);
    setMessage({ error: '', success: '' });
    try {
      if (editing?.id) {
        await updateUserDevice(editing.id, {
          device_type: form.device_type.trim(),
          fcm_token: form.fcm_token.trim()
        });
        setMessage({ success: 'Device updated.', error: '' });
      } else {
        await createUserDevice({
          user_id: Number(form.user_id),
          device_type: form.device_type.trim(),
          fcm_token: form.fcm_token.trim()
        });
        setMessage({ success: 'Device created.', error: '' });
      }
      setShowModal(false);
      loadRows();
    } catch (e) {
      console.error(e);
      setMessage({ error: e?.response?.data?.error || 'Save failed.', success: '' });
    } finally {
      setSaving(false);
    }
  };

  const remove = async (id) => {
    if (!window.confirm('Delete this device token?')) return;
    try {
      await deleteUserDevice(id);
      setMessage({ success: 'Device deleted.', error: '' });
      loadRows();
    } catch (e) {
      console.error(e);
      setMessage({ error: e?.response?.data?.error || 'Delete failed.', success: '' });
    }
  };

  return (
    <div className="rental-page">
      <div className="advanced-panel mb-0">
        <div className="advanced-panel-header">
          <h5>
            <i className="feather icon-smartphone me-2" />
            User Devices
          </h5>
          <div className="d-flex gap-2 flex-wrap">
            <Form.Control
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              placeholder="Search device/token"
              style={{ width: 180 }}
            />
            <Button size="sm" variant="outline-primary" onClick={loadRows}>
              Refresh
            </Button>
            <Button size="sm" variant="primary" onClick={openCreate}>
              Add Device
            </Button>
          </div>
        </div>
        <div>
              {message.error && <Alert variant="danger">{message.error}</Alert>}
              {message.success && <Alert variant="success">{message.success}</Alert>}
              {loading && rows.length === 0 ? (
                <div className="text-center py-5">
                  <Spinner animation="border" style={{ color: '#e7b904' }} />
                  <p className="text-muted mt-2">Loading...</p>
                </div>
              ) : (
                <>
                  <div className="table-responsive rental-table-wrap">
                    <Table hover responsive className="rental-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th>ID</th>
                          <th>User</th>
                          <th>Device Type</th>
                          <th>FCM Token</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td>{r.user?.name || `User #${r.user_id}`}</td>
                            <td className="fw-bold">{r.device_type}</td>
                            <td style={{ maxWidth: 340 }}>
                              <span className="text-truncate d-inline-block" style={{ maxWidth: 340 }}>
                                {r.fcm_token}
                              </span>
                            </td>
                            <td className="text-end">
                              <Button size="sm" variant="outline-primary" className="me-2" onClick={() => openEdit(r)}>
                                Edit
                              </Button>
                              <Button size="sm" variant="outline-danger" onClick={() => remove(r.id)}>
                                Delete
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </Table>
                  </div>
                  {pagination.totalPages > 1 && (
                    <Pagination className="mt-3 mb-0">
                      <Pagination.Prev disabled={page <= 1} onClick={() => setPage((p) => Math.max(1, p - 1))} />
                      <Pagination.Item active>{page}</Pagination.Item>
                      <Pagination.Next
                        disabled={page >= pagination.totalPages}
                        onClick={() => setPage((p) => Math.min(pagination.totalPages, p + 1))}
                      />
                    </Pagination>
                  )}
                </>
              )}
        </div>
      </div>

      <Modal show={showModal} onHide={() => setShowModal(false)} centered size="lg" className="rental-modal">
        <Modal.Header closeButton className="rental-modal-header">
          <Modal.Title>
            <i className="feather icon-smartphone me-2" />
            {editing ? 'Edit User Device' : 'Create User Device'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="g-3">
            {!editing && (
              <Col md={6}>
                <Form.Label>User</Form.Label>
                <Form.Select value={form.user_id} onChange={(e) => setForm((f) => ({ ...f, user_id: e.target.value }))}>
                  <option value="">Select user</option>
                  {users.map((u) => (
                    <option key={u.id} value={u.id}>
                      {u.name || u.email} (#{u.id})
                    </option>
                  ))}
                </Form.Select>
              </Col>
            )}
            <Col md={6}>
              <Form.Label>Device Type</Form.Label>
              <Form.Control
                value={form.device_type}
                onChange={(e) => setForm((f) => ({ ...f, device_type: e.target.value }))}
                placeholder="android / ios / web"
              />
            </Col>
            <Col md={12}>
              <Form.Label>FCM Token</Form.Label>
              <Form.Control
                as="textarea"
                rows={4}
                value={form.fcm_token}
                onChange={(e) => setForm((f) => ({ ...f, fcm_token: e.target.value }))}
              />
            </Col>
          </Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="outline-secondary" onClick={() => setShowModal(false)}>
            Cancel
          </Button>
          <Button variant="primary" onClick={save} disabled={saving}>
            {saving ? 'Saving...' : 'Save'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default UserDevicesManager;
