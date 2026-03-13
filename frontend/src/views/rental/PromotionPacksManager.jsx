import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert, Badge } from 'react-bootstrap';
import { getPromotionPacks, createPromotionPack, updatePromotionPack, deletePromotionPack } from '../../services/rentalApi';

const emptyForm = { name_en: '', name_so: '', duration: 30, price: 0, availability: 1 };

const PromotionPacksManager = () => {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, totalItems: 0 });
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState(emptyForm);
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ error: '', success: '' });

  const loadRows = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getPromotionPacks({ page, limit: 10, search: search.trim() || undefined });
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, totalItems: p.totalItems ?? 0 });
    } catch (e) {
      console.error(e);
      setMessage({ error: 'Failed to load promotion packs.', success: '' });
    } finally {
      setLoading(false);
    }
  }, [page, search]);

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
      name_en: row.name_en ?? '',
      name_so: row.name_so ?? '',
      duration: row.duration ?? 30,
      price: row.price ?? 0,
      availability: row.availability ?? 1
    });
    setShowModal(true);
  };

  const save = async () => {
    setSaving(true);
    setMessage({ error: '', success: '' });
    try {
      const payload = {
        name_en: form.name_en.trim(),
        name_so: form.name_so.trim(),
        duration: Number(form.duration),
        price: Number(form.price),
        availability: Number(form.availability)
      };
      if (editing?.id) {
        await updatePromotionPack(editing.id, payload);
        setMessage({ success: 'Promotion pack updated.', error: '' });
      } else {
        await createPromotionPack(payload);
        setMessage({ success: 'Promotion pack created.', error: '' });
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
    if (!window.confirm('Delete this promotion pack?')) return;
    try {
      await deletePromotionPack(id);
      setMessage({ success: 'Promotion pack deleted.', error: '' });
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
            <i className="feather icon-layers me-2" />
            Promotion Packs
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
            <Button size="sm" variant="outline-primary" onClick={loadRows}>
              Refresh
            </Button>
            <Button size="sm" variant="primary" onClick={openCreate}>
              Add Pack
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
                          <th>Name (EN)</th>
                          <th>Name (SO)</th>
                          <th>Duration</th>
                          <th>Price</th>
                          <th>Availability</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td className="fw-bold">{r.name_en}</td>
                            <td>{r.name_so}</td>
                            <td>{r.duration} days</td>
                            <td>${Number(r.price ?? 0).toLocaleString()}</td>
                            <td>
                              {Number(r.availability) === 1 ? <Badge bg="success">Available</Badge> : <Badge bg="secondary">Hidden</Badge>}
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

      <Modal show={showModal} onHide={() => setShowModal(false)} centered className="rental-modal">
        <Modal.Header closeButton className="rental-modal-header">
          <Modal.Title>
            <i className="feather icon-layers me-2" />
            {editing ? 'Edit Promotion Pack' : 'Create Promotion Pack'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="g-3">
            <Col md={6}>
              <Form.Label>Name EN</Form.Label>
              <Form.Control value={form.name_en} onChange={(e) => setForm((f) => ({ ...f, name_en: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Name SO</Form.Label>
              <Form.Control value={form.name_so} onChange={(e) => setForm((f) => ({ ...f, name_so: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Duration</Form.Label>
              <Form.Control type="number" value={form.duration} onChange={(e) => setForm((f) => ({ ...f, duration: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Price</Form.Label>
              <Form.Control type="number" value={form.price} onChange={(e) => setForm((f) => ({ ...f, price: e.target.value }))} />
            </Col>
            <Col md={12}>
              <Form.Label>Availability</Form.Label>
              <Form.Select value={form.availability} onChange={(e) => setForm((f) => ({ ...f, availability: e.target.value }))}>
                <option value={1}>Available</option>
                <option value={0}>Hidden</option>
              </Form.Select>
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

export default PromotionPacksManager;
