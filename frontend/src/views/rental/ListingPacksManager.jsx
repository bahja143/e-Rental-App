import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert, Badge } from 'react-bootstrap';
import { getListingPacks, createListingPack, updateListingPack, deleteListingPack } from '../../services/rentalApi';

const emptyForm = { name_en: '', name_so: '', price: 0, duration: 30, listing_amount: 1, display: 1, features: '{}' };

const ListingPacksManager = () => {
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
      const res = await getListingPacks({ page, limit: 10, search: search.trim() || undefined });
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, totalItems: p.totalItems ?? 0 });
    } catch (e) {
      console.error(e);
      setMessage({ error: 'Failed to load listing packs.', success: '' });
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
      price: row.price ?? 0,
      duration: row.duration ?? 30,
      listing_amount: row.listing_amount ?? 1,
      display: row.display ?? 1,
      features: JSON.stringify(row.features ?? {}, null, 2)
    });
    setShowModal(true);
  };

  const save = async () => {
    setSaving(true);
    setMessage({ error: '', success: '' });
    try {
      let featuresObj = {};
      try {
        featuresObj = form.features?.trim() ? JSON.parse(form.features) : {};
      } catch (_e) {
        setMessage({ error: 'Features must be valid JSON.', success: '' });
        setSaving(false);
        return;
      }
      const payload = {
        name_en: form.name_en.trim(),
        name_so: form.name_so.trim(),
        price: Number(form.price),
        duration: Number(form.duration),
        listing_amount: Number(form.listing_amount),
        display: Number(form.display),
        features: featuresObj
      };
      if (editing?.id) {
        await updateListingPack(editing.id, payload);
        setMessage({ success: 'Listing pack updated.', error: '' });
      } else {
        await createListingPack(payload);
        setMessage({ success: 'Listing pack created.', error: '' });
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
    if (!window.confirm('Delete this listing pack?')) return;
    try {
      await deleteListingPack(id);
      setMessage({ success: 'Listing pack deleted.', error: '' });
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
            <i className="feather icon-package me-2" />
            Listing Packs
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
                  <Spinner animation="border" />
                </div>
              ) : (
                <>
                  <div className="table-responsive rental-table-wrap">
                    <Table hover responsive className="rental-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th>ID</th>
                          <th>Name (EN)</th>
                          <th>Price</th>
                          <th>Duration</th>
                          <th>Listings</th>
                          <th>Display</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td className="fw-bold">{r.name_en}</td>
                            <td>${Number(r.price ?? 0).toLocaleString()}</td>
                            <td>{r.duration} days</td>
                            <td>{r.listing_amount}</td>
                            <td>{Number(r.display) === 1 ? <Badge bg="success">Shown</Badge> : <Badge bg="secondary">Hidden</Badge>}</td>
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
            <i className="feather icon-package me-2" />
            {editing ? 'Edit Listing Pack' : 'Create Listing Pack'}
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
            <Col md={4}>
              <Form.Label>Price</Form.Label>
              <Form.Control type="number" value={form.price} onChange={(e) => setForm((f) => ({ ...f, price: e.target.value }))} />
            </Col>
            <Col md={4}>
              <Form.Label>Duration</Form.Label>
              <Form.Control type="number" value={form.duration} onChange={(e) => setForm((f) => ({ ...f, duration: e.target.value }))} />
            </Col>
            <Col md={4}>
              <Form.Label>Listing Amount</Form.Label>
              <Form.Control
                type="number"
                value={form.listing_amount}
                onChange={(e) => setForm((f) => ({ ...f, listing_amount: e.target.value }))}
              />
            </Col>
            <Col md={12}>
              <Form.Label>Features JSON</Form.Label>
              <Form.Control
                as="textarea"
                rows={5}
                value={form.features}
                onChange={(e) => setForm((f) => ({ ...f, features: e.target.value }))}
              />
            </Col>
            <Col md={12}>
              <Form.Label>Display</Form.Label>
              <Form.Select value={form.display} onChange={(e) => setForm((f) => ({ ...f, display: e.target.value }))}>
                <option value={1}>Shown</option>
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

export default ListingPacksManager;
