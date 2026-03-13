import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert, Badge } from 'react-bootstrap';
import { getPromotions, createPromotion, updatePromotion, deletePromotion, getListings, getCoupons } from '../../services/rentalApi';

const defaultForm = {
  listing_id: '',
  subtotal: '',
  discount: 0,
  total: '',
  start_date: '',
  end_date: '',
  coupon_id: '',
  status: 'active'
};

const PromotionsManager = () => {
  const [loading, setLoading] = useState(true);
  const [rows, setRows] = useState([]);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, totalItems: 0 });
  const [statusFilter, setStatusFilter] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(defaultForm);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState({ error: '', success: '' });
  const [listingOptions, setListingOptions] = useState([]);
  const [couponOptions, setCouponOptions] = useState([]);

  const loadPromotions = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 10, include_coupon: true };
      if (statusFilter) params.status = statusFilter;
      const res = await getPromotions(params);
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, totalItems: p.totalItems ?? 0 });
    } catch (e) {
      console.error(e);
      setFeedback({ error: 'Failed to load promotions.', success: '' });
      setRows([]);
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter]);

  const loadOptions = useCallback(async () => {
    try {
      const [listRes, couponRes] = await Promise.all([getListings({ page: 1, limit: 200 }), getCoupons({ page: 1, limit: 200 })]);
      setListingOptions(listRes.data?.data ?? []);
      setCouponOptions((couponRes.data?.data ?? []).filter((c) => c.is_active));
    } catch (e) {
      console.error(e);
    }
  }, []);

  useEffect(() => {
    loadPromotions();
  }, [loadPromotions]);

  useEffect(() => {
    loadOptions();
  }, [loadOptions]);

  const openCreate = () => {
    setEditing(null);
    setForm(defaultForm);
    setShowModal(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({
      listing_id: row.listing_id ?? '',
      subtotal: Number(row.subtotal ?? 0),
      discount: Number(row.discount ?? 0),
      total: Number(row.total ?? 0),
      start_date: row.start_date ? `${row.start_date}`.slice(0, 10) : '',
      end_date: row.end_date ? `${row.end_date}`.slice(0, 10) : '',
      coupon_id: row.coupon_id ?? '',
      status: row.status ?? 'active'
    });
    setShowModal(true);
  };

  const recalcTotal = (next) => {
    const subtotal = Number(next.subtotal || 0);
    const discount = Number(next.discount || 0);
    return { ...next, total: Math.max(0, subtotal - discount).toFixed(2) };
  };

  const handleSave = async () => {
    setSaving(true);
    setFeedback({ error: '', success: '' });
    try {
      const payload = {
        listing_id: Number(form.listing_id),
        subtotal: Number(form.subtotal),
        discount: Number(form.discount || 0),
        total: Number(form.total),
        start_date: form.start_date,
        end_date: form.end_date,
        coupon_id: form.coupon_id === '' ? null : Number(form.coupon_id),
        status: form.status
      };
      if (editing?.id) {
        await updatePromotion(editing.id, payload);
        setFeedback({ success: 'Promotion updated.', error: '' });
      } else {
        await createPromotion(payload);
        setFeedback({ success: 'Promotion created.', error: '' });
      }
      setShowModal(false);
      loadPromotions();
    } catch (e) {
      console.error(e);
      setFeedback({ error: e?.response?.data?.error || e?.message || 'Save failed.', success: '' });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this promotion?')) return;
    try {
      await deletePromotion(id);
      setFeedback({ success: 'Promotion deleted.', error: '' });
      loadPromotions();
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
            <i className="feather icon-award me-2" />
            Promotions
          </h5>
          <div className="d-flex gap-2 flex-wrap">
                <Form.Select
                  value={statusFilter}
                  onChange={(e) => {
                    setStatusFilter(e.target.value);
                    setPage(1);
                  }}
                  style={{ width: 130 }}
                >
                  <option value="">All status</option>
                  <option value="active">Active</option>
                  <option value="expired">Expired</option>
                </Form.Select>
                <Button size="sm" variant="outline-primary" onClick={loadPromotions}>
                  Refresh
                </Button>
                <Button size="sm" variant="primary" onClick={openCreate}>
                  Add Promotion
                </Button>
          </div>
        </div>
        <div>
              {feedback.error && <Alert variant="danger">{feedback.error}</Alert>}
              {feedback.success && <Alert variant="success">{feedback.success}</Alert>}

              {loading && rows.length === 0 ? (
                <div className="text-center py-5">
                  <Spinner animation="border" style={{ color: '#e7b904' }} />
                  <p className="text-muted mt-2">Loading promotions...</p>
                </div>
              ) : rows.length === 0 ? (
                <p className="text-muted mb-0">No promotions found.</p>
              ) : (
                <>
                  <div className="table-responsive rental-table-wrap">
                    <Table hover responsive className="rental-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th>ID</th>
                          <th>Listing</th>
                          <th>Coupon</th>
                          <th>Subtotal</th>
                          <th>Discount</th>
                          <th>Total</th>
                          <th>Status</th>
                          <th>Dates</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td>{r.listing?.title ?? r.listing_id}</td>
                            <td>{r.coupon?.code ?? r.coupon_code ?? '-'}</td>
                            <td>${Number(r.subtotal ?? 0).toLocaleString()}</td>
                            <td>${Number(r.discount ?? 0).toLocaleString()}</td>
                            <td>${Number(r.total ?? 0).toLocaleString()}</td>
                            <td>{r.status === 'active' ? <Badge bg="success">Active</Badge> : <Badge bg="secondary">Expired</Badge>}</td>
                            <td>
                              {r.start_date ? new Date(r.start_date).toLocaleDateString() : '-'} to{' '}
                              {r.end_date ? new Date(r.end_date).toLocaleDateString() : '-'}
                            </td>
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
            <i className="feather icon-award me-2" />
            {editing ? 'Edit Promotion' : 'Create Promotion'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="g-3">
            <Col md={6}>
              <Form.Label>Listing</Form.Label>
              <Form.Select value={form.listing_id} onChange={(e) => setForm((f) => recalcTotal({ ...f, listing_id: e.target.value }))}>
                <option value="">Select listing</option>
                {listingOptions.map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.title ?? `Listing ${l.id}`}
                  </option>
                ))}
              </Form.Select>
            </Col>
            <Col md={6}>
              <Form.Label>Coupon (optional)</Form.Label>
              <Form.Select value={form.coupon_id} onChange={(e) => setForm((f) => ({ ...f, coupon_id: e.target.value }))}>
                <option value="">No coupon</option>
                {couponOptions.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.code}
                  </option>
                ))}
              </Form.Select>
            </Col>
            <Col md={4}>
              <Form.Label>Subtotal</Form.Label>
              <Form.Control
                type="number"
                value={form.subtotal}
                onChange={(e) => setForm((f) => recalcTotal({ ...f, subtotal: e.target.value }))}
              />
            </Col>
            <Col md={4}>
              <Form.Label>Discount</Form.Label>
              <Form.Control
                type="number"
                value={form.discount}
                onChange={(e) => setForm((f) => recalcTotal({ ...f, discount: e.target.value }))}
              />
            </Col>
            <Col md={4}>
              <Form.Label>Total</Form.Label>
              <Form.Control type="number" value={form.total} onChange={(e) => setForm((f) => ({ ...f, total: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Start date</Form.Label>
              <Form.Control type="date" value={form.start_date} onChange={(e) => setForm((f) => ({ ...f, start_date: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>End date</Form.Label>
              <Form.Control type="date" value={form.end_date} onChange={(e) => setForm((f) => ({ ...f, end_date: e.target.value }))} />
            </Col>
            <Col md={12}>
              <Form.Label>Status</Form.Label>
              <Form.Select value={form.status} onChange={(e) => setForm((f) => ({ ...f, status: e.target.value }))}>
                <option value="active">Active</option>
                <option value="expired">Expired</option>
              </Form.Select>
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

export default PromotionsManager;
