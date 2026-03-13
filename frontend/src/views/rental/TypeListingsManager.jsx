import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert } from 'react-bootstrap';
import {
  getTypeListings,
  createTypeListing,
  updateTypeListing,
  deleteTypeListing,
  getListings,
  getListingTypes
} from '../../services/rentalApi';
import { getApiErrorMessage } from '../../utils/apiError';

const emptyForm = { listing_id: '', listing_type_id: '' };

const TypeListingsManager = () => {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, total: 0 });
  const [listingFilter, setListingFilter] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ error: '', success: '' });
  const [listings, setListings] = useState([]);
  const [listingTypes, setListingTypes] = useState([]);

  const loadRows = useCallback(async () => {
    setLoading(true);
    setMessage((m) => ({ ...m, error: '' }));
    try {
      const params = { page, limit: 10 };
      if (listingFilter) params.listing_id = listingFilter;
      const res = await getTypeListings(params);
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, total: p.total ?? 0 });
      setMessage((m) => ({ ...m, error: '', success: '' }));
    } catch (e) {
      console.error(e);
      setMessage({ error: getApiErrorMessage(e, 'Failed to load type listings. Check your connection and try again.'), success: '' });
      setRows([]);
    } finally {
      setLoading(false);
    }
  }, [page, listingFilter]);

  const loadOptions = useCallback(async () => {
    try {
      const [listRes, typeRes] = await Promise.all([
        getListings({ page: 1, limit: 200 }),
        getListingTypes({ page: 1, limit: 200 }).catch(() => ({ data: { data: [] } }))
      ]);
      setListings(listRes.data?.data ?? []);
      setListingTypes(typeRes.data?.data ?? []);
    } catch (e) {
      console.error(e);
    }
  }, []);

  useEffect(() => {
    loadRows();
  }, [loadRows]);

  useEffect(() => {
    loadOptions();
  }, [loadOptions]);

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setShowModal(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({ listing_id: row.listing_id ?? '', listing_type_id: row.listing_type_id ?? '' });
    setShowModal(true);
  };

  const save = async () => {
    setSaving(true);
    setMessage({ error: '', success: '' });
    try {
      const payload = { listing_id: Number(form.listing_id), listing_type_id: Number(form.listing_type_id) };
      if (editing?.id) {
        await updateTypeListing(editing.id, payload);
        setMessage({ success: 'Type listing updated.', error: '' });
      } else {
        await createTypeListing(payload);
        setMessage({ success: 'Type listing created.', error: '' });
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
    if (!window.confirm('Delete this type listing relation?')) return;
    try {
      await deleteTypeListing(id);
      setMessage({ success: 'Type listing deleted.', error: '' });
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
            <i className="feather icon-link me-2" />
            Type Listings
          </h5>
          <div className="d-flex gap-2 flex-wrap">
            <Form.Select
              value={listingFilter}
              onChange={(e) => {
                setListingFilter(e.target.value);
                setPage(1);
              }}
              style={{ width: 190 }}
            >
              <option value="">All listings</option>
              {listings.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.title ?? `Listing ${l.id}`}
                </option>
              ))}
            </Form.Select>
            <Button size="sm" variant="outline-primary" onClick={loadRows}>
              Refresh
            </Button>
            <Button size="sm" variant="primary" onClick={openCreate}>
              Add Mapping
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
                          <th>Listing</th>
                          <th>Type</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td className="fw-bold">{r.listing?.title ?? r.listing_id}</td>
                            <td>{r.listingType?.name_en ?? r.listing_type_id}</td>
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
            <i className="feather icon-link me-2" />
            {editing ? 'Edit Type Listing' : 'Create Type Listing'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="g-3">
            <Col md={12}>
              <Form.Label>Listing</Form.Label>
              <Form.Select value={form.listing_id} onChange={(e) => setForm((f) => ({ ...f, listing_id: e.target.value }))}>
                <option value="">Select listing</option>
                {listings.map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.title ?? `Listing ${l.id}`}
                  </option>
                ))}
              </Form.Select>
            </Col>
            <Col md={12}>
              <Form.Label>Listing Type</Form.Label>
              <Form.Select value={form.listing_type_id} onChange={(e) => setForm((f) => ({ ...f, listing_type_id: e.target.value }))}>
                <option value="">Select type</option>
                {listingTypes.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name_en ?? `Type ${t.id}`}
                  </option>
                ))}
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

export default TypeListingsManager;
