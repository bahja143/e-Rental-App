import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert } from 'react-bootstrap';
import {
  getWithdrawBalances,
  createWithdrawBalance,
  updateWithdrawBalance,
  deleteWithdrawBalance,
  getUsers
} from '../../services/rentalApi';

const emptyForm = {
  user_id: '',
  amount: '',
  status: 'requested',
  date: '',
  before_balance: '',
  after_balance: '',
  bank_name: '',
  branch: '',
  bank_account: '',
  account_holder_name: '',
  swift: ''
};

const WithdrawBalancesManager = () => {
  const [rows, setRows] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, totalItems: 0 });
  const [statusFilter, setStatusFilter] = useState('');
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
      const res = await getWithdrawBalances({
        page,
        limit: 10,
        status: statusFilter || undefined
      });
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, totalItems: p.totalItems ?? 0 });
    } catch (e) {
      console.error(e);
      setMessage({ error: 'Failed to load withdraw balances.', success: '' });
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter]);

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
      amount: row.amount ?? '',
      status: row.status ?? 'requested',
      date: row.date ? String(row.date).slice(0, 10) : '',
      before_balance: row.before_balance ?? '',
      after_balance: row.after_balance ?? '',
      bank_name: row.bank_name ?? '',
      branch: row.branch ?? '',
      bank_account: row.bank_account ?? '',
      account_holder_name: row.account_holder_name ?? '',
      swift: row.swift ?? ''
    });
    setShowModal(true);
  };

  const save = async () => {
    setSaving(true);
    setMessage({ error: '', success: '' });
    try {
      const payload = {
        amount: Number(form.amount),
        status: form.status,
        date: form.date || undefined,
        before_balance: Number(form.before_balance),
        after_balance: Number(form.after_balance),
        bank_name: form.bank_name.trim() || null,
        branch: form.branch.trim() || null,
        bank_account: form.bank_account.trim() || null,
        account_holder_name: form.account_holder_name.trim() || null,
        swift: form.swift.trim() || null
      };
      if (editing?.id) {
        await updateWithdrawBalance(editing.id, payload);
        setMessage({ success: 'Withdraw updated.', error: '' });
      } else {
        await createWithdrawBalance({
          ...payload,
          user_id: Number(form.user_id)
        });
        setMessage({ success: 'Withdraw created.', error: '' });
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
    if (!window.confirm('Delete this withdraw record?')) return;
    try {
      await deleteWithdrawBalance(id);
      setMessage({ success: 'Withdraw deleted.', error: '' });
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
            <i className="feather icon-dollar-sign me-2" />
            Withdraw Balances
          </h5>
          <div className="d-flex gap-2 flex-wrap">
            <Form.Select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setPage(1);
              }}
              style={{ width: 160 }}
            >
              <option value="">All Statuses</option>
              <option value="requested">Requested</option>
              <option value="success">Success</option>
              <option value="failed">Failed</option>
              <option value="cancelled">Cancelled</option>
            </Form.Select>
            <Button size="sm" variant="outline-primary" onClick={loadRows}>
              Refresh
            </Button>
            <Button size="sm" variant="primary" onClick={openCreate}>
              Add Withdraw
            </Button>
          </div>
        </div>
        <div>
              {message.error && <Alert variant="danger">{message.error}</Alert>}
              {message.success && <Alert variant="success">{message.success}</Alert>}
              {loading && rows.length === 0 ? (
                <div className="text-center py-5">
                  <Spinner animation="border" />
                </div>
              ) : (
                <>
                  <div className="table-responsive rental-table-wrap">
                    <Table hover responsive className="rental-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th>ID</th>
                          <th>User</th>
                          <th>Amount</th>
                          <th>Status</th>
                          <th>Date</th>
                          <th>Before/After</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td>{r.user?.name || `User #${r.user_id}`}</td>
                            <td className="fw-bold">${Number(r.amount || 0).toLocaleString()}</td>
                            <td className="text-capitalize">{r.status}</td>
                            <td>{r.date ? new Date(r.date).toLocaleDateString() : '-'}</td>
                            <td>
                              ${Number(r.before_balance || 0).toLocaleString()} / ${Number(r.after_balance || 0).toLocaleString()}
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

      <Modal show={showModal} onHide={() => setShowModal(false)} centered size="xl" className="rental-modal">
        <Modal.Header closeButton className="rental-modal-header">
          <Modal.Title>
            <i className="feather icon-dollar-sign me-2" />
            {editing ? 'Edit Withdraw Balance' : 'Create Withdraw Balance'}
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
            <Col md={3}>
              <Form.Label>Amount</Form.Label>
              <Form.Control type="number" value={form.amount} onChange={(e) => setForm((f) => ({ ...f, amount: e.target.value }))} />
            </Col>
            <Col md={3}>
              <Form.Label>Status</Form.Label>
              <Form.Select value={form.status} onChange={(e) => setForm((f) => ({ ...f, status: e.target.value }))}>
                <option value="requested">Requested</option>
                <option value="success">Success</option>
                <option value="failed">Failed</option>
                <option value="cancelled">Cancelled</option>
              </Form.Select>
            </Col>
            <Col md={3}>
              <Form.Label>Date</Form.Label>
              <Form.Control type="date" value={form.date} onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))} />
            </Col>
            <Col md={3}>
              <Form.Label>Before Balance</Form.Label>
              <Form.Control
                type="number"
                value={form.before_balance}
                onChange={(e) => setForm((f) => ({ ...f, before_balance: e.target.value }))}
              />
            </Col>
            <Col md={3}>
              <Form.Label>After Balance</Form.Label>
              <Form.Control
                type="number"
                value={form.after_balance}
                onChange={(e) => setForm((f) => ({ ...f, after_balance: e.target.value }))}
              />
            </Col>
            <Col md={3}>
              <Form.Label>Bank Name</Form.Label>
              <Form.Control value={form.bank_name} onChange={(e) => setForm((f) => ({ ...f, bank_name: e.target.value }))} />
            </Col>
            <Col md={3}>
              <Form.Label>Branch</Form.Label>
              <Form.Control value={form.branch} onChange={(e) => setForm((f) => ({ ...f, branch: e.target.value }))} />
            </Col>
            <Col md={3}>
              <Form.Label>Bank Account</Form.Label>
              <Form.Control value={form.bank_account} onChange={(e) => setForm((f) => ({ ...f, bank_account: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Account Holder Name</Form.Label>
              <Form.Control
                value={form.account_holder_name}
                onChange={(e) => setForm((f) => ({ ...f, account_holder_name: e.target.value }))}
              />
            </Col>
            <Col md={6}>
              <Form.Label>SWIFT</Form.Label>
              <Form.Control value={form.swift} onChange={(e) => setForm((f) => ({ ...f, swift: e.target.value }))} />
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

export default WithdrawBalancesManager;
