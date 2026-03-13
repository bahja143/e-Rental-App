import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert, Badge } from 'react-bootstrap';
import { getFaqs, createFaq, updateFaq, deleteFaq } from '../../services/rentalApi';

const emptyForm = {
  title_en: '',
  title_so: '',
  description_en: '',
  description_so: '',
  type: 'buyer'
};

const FaqsManager = () => {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, totalItems: 0 });
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ error: '', success: '' });

  const loadRows = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 10, search: search.trim() || undefined };
      if (typeFilter) params.type = typeFilter;
      const res = await getFaqs(params);
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, totalItems: p.totalItems ?? 0 });
    } catch (e) {
      console.error(e);
      setMessage({ error: 'Failed to load FAQs.', success: '' });
    } finally {
      setLoading(false);
    }
  }, [page, search, typeFilter]);

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
      title_en: row.title_en ?? '',
      title_so: row.title_so ?? '',
      description_en: row.description_en ?? '',
      description_so: row.description_so ?? '',
      type: row.type ?? 'buyer'
    });
    setShowModal(true);
  };

  const save = async () => {
    setSaving(true);
    setMessage({ error: '', success: '' });
    try {
      const payload = {
        title_en: form.title_en.trim(),
        title_so: form.title_so.trim(),
        description_en: form.description_en,
        description_so: form.description_so,
        type: form.type
      };
      if (editing?.id) {
        await updateFaq(editing.id, payload);
        setMessage({ success: 'FAQ updated.', error: '' });
      } else {
        await createFaq(payload);
        setMessage({ success: 'FAQ created.', error: '' });
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
    if (!window.confirm('Delete this FAQ?')) return;
    try {
      await deleteFaq(id);
      setMessage({ success: 'FAQ deleted.', error: '' });
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
            <i className="feather icon-help-circle me-2" />
            FAQs
          </h5>
          <div className="d-flex gap-2 flex-wrap">
            <Form.Control
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              placeholder="Search"
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
              <option value="buyer">Buyer</option>
              <option value="seller">Seller</option>
            </Form.Select>
            <Button size="sm" variant="outline-primary" onClick={loadRows}>
              Refresh
            </Button>
            <Button size="sm" variant="primary" onClick={openCreate}>
              Add FAQ
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
                          <th>Title</th>
                          <th>Type</th>
                          <th>Description</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td className="fw-bold">{r.title_en}</td>
                            <td>
                              {r.type === 'buyer' ? (
                                <Badge bg="primary">Buyer</Badge>
                              ) : (
                                <Badge bg="warning" text="dark">
                                  Seller
                                </Badge>
                              )}
                            </td>
                            <td className="text-muted">{(r.description_en ?? '').slice(0, 90) || '-'}</td>
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
            <i className="feather icon-help-circle me-2" />
            {editing ? 'Edit FAQ' : 'Create FAQ'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="g-3">
            <Col md={6}>
              <Form.Label>Title EN</Form.Label>
              <Form.Control value={form.title_en} onChange={(e) => setForm((f) => ({ ...f, title_en: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Title SO</Form.Label>
              <Form.Control value={form.title_so} onChange={(e) => setForm((f) => ({ ...f, title_so: e.target.value }))} />
            </Col>
            <Col md={12}>
              <Form.Label>Type</Form.Label>
              <Form.Select value={form.type} onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}>
                <option value="buyer">Buyer</option>
                <option value="seller">Seller</option>
              </Form.Select>
            </Col>
            <Col md={12}>
              <Form.Label>Description EN</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                value={form.description_en}
                onChange={(e) => setForm((f) => ({ ...f, description_en: e.target.value }))}
              />
            </Col>
            <Col md={12}>
              <Form.Label>Description SO</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                value={form.description_so}
                onChange={(e) => setForm((f) => ({ ...f, description_so: e.target.value }))}
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

export default FaqsManager;
