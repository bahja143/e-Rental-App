import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert, Badge } from 'react-bootstrap';
import { getCoupons, createCoupon, updateCoupon, deleteCoupon } from '../../services/rentalApi';

const defaultForm = {
  code: '',
  type: 'percentage',
  value: 10,
  use_case: 'listing_rent',
  min_purchase: '',
  start_date: '',
  expire_date: '',
  usage_limit: '',
  per_user_limit: '',
  is_active: true
};

const CouponsManager = () => {
  const [loading, setLoading] = useState(true);
  const [rows, setRows] = useState([]);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, totalItems: 0 });
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(defaultForm);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState({ error: '', success: '' });

  const loadCoupons = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 10 };
      if (search.trim()) params.search = search.trim();
      if (typeFilter) params.type = typeFilter;
      if (statusFilter) params.is_active = statusFilter;
      const res = await getCoupons(params);
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, totalItems: p.totalItems ?? 0 });
    } catch (e) {
      console.error(e);
      setFeedback({ error: 'Failed to load coupons.', success: '' });
      setRows([]);
    } finally {
      setLoading(false);
    }
  }, [page, search, typeFilter, statusFilter]);

  useEffect(() => {
    loadCoupons();
  }, [loadCoupons]);

  const openCreate = () => {
    setEditing(null);
    setForm(defaultForm);
    setShowModal(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({
      code: row.code ?? '',
      type: row.type ?? 'percentage',
      value: Number(row.value ?? 0),
      use_case: row.use_case ?? 'listing_rent',
      min_purchase: row.min_purchase ?? '',
      start_date: row.start_date ? `${row.start_date}`.slice(0, 10) : '',
      expire_date: row.expire_date ? `${row.expire_date}`.slice(0, 10) : '',
      usage_limit: row.usage_limit ?? '',
      per_user_limit: row.per_user_limit ?? '',
      is_active: Boolean(row.is_active)
    });
    setShowModal(true);
  };

  const handleSave = async () => {
    setSaving(true);
    setFeedback({ error: '', success: '' });
    try {
      const payload = {
        code: form.code.trim(),
        type: form.type,
        value: Number(form.value),
        use_case: form.use_case,
        min_purchase: form.min_purchase === '' ? null : Number(form.min_purchase),
        start_date: form.start_date || null,
        expire_date: form.expire_date || null,
        usage_limit: form.usage_limit === '' ? null : Number(form.usage_limit),
        per_user_limit: form.per_user_limit === '' ? null : Number(form.per_user_limit),
        is_active: Boolean(form.is_active)
      };
      if (editing?.id) {
        await updateCoupon(editing.id, payload);
        setFeedback({ success: 'Coupon updated.', error: '' });
      } else {
        await createCoupon(payload);
        setFeedback({ success: 'Coupon created.', error: '' });
      }
      setShowModal(false);
      loadCoupons();
    } catch (e) {
      console.error(e);
      setFeedback({ error: e?.response?.data?.error || e?.message || 'Save failed.', success: '' });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this coupon?')) return;
    try {
      await deleteCoupon(id);
      setFeedback({ success: 'Coupon deleted.', error: '' });
      loadCoupons();
    } catch (e) {
      console.error(e);
      setFeedback({ error: e?.response?.data?.error || 'Delete failed.', success: '' });
    }
  };

  return (
    <div className="rental-page">
      <div className="advanced-panel mb-0">
        <div className="advanced-panel-header">
          <h5>
            <i className="feather icon-tag me-2" />
            Coupons
          </h5>
              <div className="d-flex gap-2 flex-wrap">
                <Form.Control
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(1);
                  }}
                  placeholder="Search code"
                  style={{ width: 160 }}
                />
                <Form.Select
                  value={typeFilter}
                  onChange={(e) => {
                    setTypeFilter(e.target.value);
                    setPage(1);
                  }}
                  style={{ width: 120 }}
                >
                  <option value="">All types</option>
                  <option value="percentage">Percentage</option>
                  <option value="fixed">Fixed</option>
                </Form.Select>
                <Form.Select
                  value={statusFilter}
                  onChange={(e) => {
                    setStatusFilter(e.target.value);
                    setPage(1);
                  }}
                  style={{ width: 130 }}
                >
                  <option value="">All status</option>
                  <option value="true">Active</option>
                  <option value="false">Inactive</option>
                </Form.Select>
                <Button size="sm" variant="outline-primary" onClick={loadCoupons}>
                  Refresh
                </Button>
                <Button size="sm" variant="primary" onClick={openCreate}>
                  Add Coupon
                </Button>
              </div>
        </div>
        <div>
              {feedback.error && <Alert variant="danger">{feedback.error}</Alert>}
              {feedback.success && <Alert variant="success">{feedback.success}</Alert>}

              {loading && rows.length === 0 ? (
                <div className="text-center py-5">
                  <Spinner animation="border" />
                </div>
              ) : rows.length === 0 ? (
                <p className="text-muted mb-0">No coupons found.</p>
              ) : (
                <>
                  <div className="table-responsive rental-table-wrap">
                    <Table hover responsive className="rental-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th>ID</th>
                          <th>Code</th>
                          <th>Type</th>
                          <th>Value</th>
                          <th>Use case</th>
                          <th>Active</th>
                          <th>Used</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td className="fw-bold">{r.code}</td>
                            <td>{r.type}</td>
                            <td>{Number(r.value ?? 0)}</td>
                            <td>{r.use_case}</td>
                            <td>{r.is_active ? <Badge bg="success">Active</Badge> : <Badge bg="secondary">Inactive</Badge>}</td>
                            <td>{r.used ?? 0}</td>
                            <td className="text-end">
                              <Button size="sm" variant="outline-primary" className="me-2" onClick={() => openEdit(r)}>
                                Edit
                              </Button>
                              <Button size="sm" variant="outline-danger" onClick={() => handleDelete(r.id)}>
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
            <i className="feather icon-tag me-2" />
            {editing ? 'Edit Coupon' : 'Create Coupon'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="g-3">
            <Col md={6}>
              <Form.Label>Code</Form.Label>
              <Form.Control value={form.code} onChange={(e) => setForm((f) => ({ ...f, code: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Type</Form.Label>
              <Form.Select value={form.type} onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}>
                <option value="percentage">Percentage</option>
                <option value="fixed">Fixed</option>
              </Form.Select>
            </Col>
            <Col md={6}>
              <Form.Label>Value</Form.Label>
              <Form.Control type="number" value={form.value} onChange={(e) => setForm((f) => ({ ...f, value: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Use Case</Form.Label>
              <Form.Select value={form.use_case} onChange={(e) => setForm((f) => ({ ...f, use_case: e.target.value }))}>
                <option value="listing_package">listing_package</option>
                <option value="promotion_package">promotion_package</option>
                <option value="listing_buy">listing_buy</option>
                <option value="listing_rent">listing_rent</option>
              </Form.Select>
            </Col>
            <Col md={4}>
              <Form.Label>Min Purchase</Form.Label>
              <Form.Control
                type="number"
                value={form.min_purchase}
                onChange={(e) => setForm((f) => ({ ...f, min_purchase: e.target.value }))}
              />
            </Col>
            <Col md={4}>
              <Form.Label>Usage Limit</Form.Label>
              <Form.Control
                type="number"
                value={form.usage_limit}
                onChange={(e) => setForm((f) => ({ ...f, usage_limit: e.target.value }))}
              />
            </Col>
            <Col md={4}>
              <Form.Label>Per User Limit</Form.Label>
              <Form.Control
                type="number"
                value={form.per_user_limit}
                onChange={(e) => setForm((f) => ({ ...f, per_user_limit: e.target.value }))}
              />
            </Col>
            <Col md={6}>
              <Form.Label>Start Date</Form.Label>
              <Form.Control type="date" value={form.start_date} onChange={(e) => setForm((f) => ({ ...f, start_date: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Expire Date</Form.Label>
              <Form.Control
                type="date"
                value={form.expire_date}
                onChange={(e) => setForm((f) => ({ ...f, expire_date: e.target.value }))}
              />
            </Col>
            <Col md={12}>
              <Form.Check
                type="switch"
                id="coupon-active"
                label="Active"
                checked={form.is_active}
                onChange={(e) => setForm((f) => ({ ...f, is_active: e.target.checked }))}
              />
            </Col>
          </Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="outline-secondary" onClick={() => setShowModal(false)}>
            Cancel
          </Button>
          <Button variant="primary" onClick={handleSave} disabled={saving}>
            {saving ? 'Saving...' : 'Save'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default CouponsManager;
