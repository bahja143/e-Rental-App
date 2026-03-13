import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert } from 'react-bootstrap';
import {
  getUserBankAccounts,
  createUserBankAccount,
  updateUserBankAccount,
  deleteUserBankAccount,
  getUsers
} from '../../services/rentalApi';

const emptyForm = {
  user_id: '',
  bank_name: '',
  branch: '',
  account_no: '',
  account_holder_name: '',
  swift_code: '',
  is_default: false
};

const UserBankAccountsManager = () => {
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
      const res = await getUserBankAccounts({
        page,
        limit: 10,
        account_holder_name: search.trim() || undefined
      });
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, totalItems: p.totalItems ?? 0 });
    } catch (e) {
      console.error(e);
      setMessage({ error: 'Failed to load bank accounts.', success: '' });
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
      bank_name: row.bank_name ?? '',
      branch: row.branch ?? '',
      account_no: row.account_no ?? '',
      account_holder_name: row.account_holder_name ?? '',
      swift_code: row.swift_code ?? '',
      is_default: Boolean(row.is_default)
    });
    setShowModal(true);
  };

  const save = async () => {
    setSaving(true);
    setMessage({ error: '', success: '' });
    try {
      const payload = {
        bank_name: form.bank_name.trim(),
        branch: form.branch.trim(),
        account_no: form.account_no.trim(),
        account_holder_name: form.account_holder_name.trim(),
        swift_code: form.swift_code.trim() || null,
        is_default: Boolean(form.is_default)
      };
      if (editing?.id) {
        await updateUserBankAccount(editing.id, payload);
        setMessage({ success: 'Bank account updated.', error: '' });
      } else {
        await createUserBankAccount({
          ...payload,
          user_id: Number(form.user_id)
        });
        setMessage({ success: 'Bank account created.', error: '' });
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
    if (!window.confirm('Delete this bank account?')) return;
    try {
      await deleteUserBankAccount(id);
      setMessage({ success: 'Bank account deleted.', error: '' });
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
            <i className="feather icon-credit-card me-2" />
            User Bank Accounts
          </h5>
          <div className="d-flex gap-2 flex-wrap">
                <Form.Control
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(1);
                  }}
                  placeholder="Search holder"
                  style={{ width: 160 }}
                />
                <Button size="sm" variant="outline-primary" onClick={loadRows}>
                  Refresh
                </Button>
                <Button size="sm" variant="primary" onClick={openCreate}>
                  Add Account
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
                          <th>Bank</th>
                          <th>Account #</th>
                          <th>Holder</th>
                          <th>Default</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td>{r.user?.name || `User #${r.user_id}`}</td>
                            <td className="fw-bold">{r.bank_name}</td>
                            <td>{r.account_no}</td>
                            <td>{r.account_holder_name}</td>
                            <td>{r.is_default ? 'Yes' : 'No'}</td>
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
            <i className="feather icon-credit-card me-2" />
            {editing ? 'Edit User Bank Account' : 'Create User Bank Account'}
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
              <Form.Label>Bank Name</Form.Label>
              <Form.Control value={form.bank_name} onChange={(e) => setForm((f) => ({ ...f, bank_name: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Branch</Form.Label>
              <Form.Control value={form.branch} onChange={(e) => setForm((f) => ({ ...f, branch: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Account Number</Form.Label>
              <Form.Control value={form.account_no} onChange={(e) => setForm((f) => ({ ...f, account_no: e.target.value }))} />
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
              <Form.Control value={form.swift_code} onChange={(e) => setForm((f) => ({ ...f, swift_code: e.target.value }))} />
            </Col>
            <Col md={12}>
              <Form.Check
                type="switch"
                id="is-default-bank-account"
                label="Set as default"
                checked={form.is_default}
                onChange={(e) => setForm((f) => ({ ...f, is_default: e.target.checked }))}
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

export default UserBankAccountsManager;
