import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Alert, Badge, Button, Col, Form, Modal, Pagination, Row, Spinner, Table } from 'react-bootstrap';
import { createListing, deleteListing, getListings, updateListing } from '../../services/rentalApi';

const initialForm = {
  title: '',
  address: '',
  description: '',
  lat: '',
  lng: '',
  rent_price: '',
  sell_price: '',
  rent_type: 'monthly',
  availability: true,
};

const parseBooleanAvailability = (value) => value === '1' || value === 1 || value === true;

const ListingsList = () => {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, total: 0 });
  const [search, setSearch] = useState('');
  const [availability, setAvailability] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState({ error: '', success: '' });
  const [form, setForm] = useState(initialForm);

  const resetForm = () => {
    setEditing(null);
    setForm(initialForm);
  };

  const loadRows = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 10 };
      if (search.trim()) params.search = search.trim();
      if (availability) params.availability = availability;
      const res = await getListings(params);
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({
        totalPages: p.totalPages ?? 1,
        total: p.total ?? 0,
      });
    } catch (err) {
      console.error(err);
      setFeedback({ error: err?.error || err?.message || 'Failed to load listings.', success: '' });
      setRows([]);
    } finally {
      setLoading(false);
    }
  }, [page, search, availability]);

  useEffect(() => {
    loadRows();
  }, [loadRows]);

  const openCreate = () => {
    resetForm();
    setShowModal(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({
      title: row.title ?? '',
      address: row.address ?? '',
      description: row.description ?? '',
      lat: row.lat ?? '',
      lng: row.lng ?? '',
      rent_price: row.rent_price ?? '',
      sell_price: row.sell_price ?? '',
      rent_type: row.rent_type ?? 'monthly',
      availability: parseBooleanAvailability(row.availability),
    });
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    resetForm();
  };

  const activePriceField = useMemo(() => (form.sell_price ? 'sell' : 'rent'), [form.sell_price]);

  const handleFormChange = (key, value) => {
    setForm((current) => ({ ...current, [key]: value }));
  };

  const validateForm = () => {
    if (!form.title.trim() || !form.address.trim()) {
      return 'Title and address are required.';
    }
    if (form.lat === '' || form.lng === '') {
      return 'Latitude and longitude are required.';
    }
    if (!form.rent_price && !form.sell_price) {
      return 'Add a rent price or a sell price.';
    }
    return '';
  };

  const handleSave = async () => {
    const validationError = validateForm();
    if (validationError) {
      setFeedback({ error: validationError, success: '' });
      return;
    }

    setSaving(true);
    setFeedback({ error: '', success: '' });
    try {
      const payload = {
        title: form.title.trim(),
        address: form.address.trim(),
        description: form.description.trim(),
        lat: parseFloat(form.lat),
        lng: parseFloat(form.lng),
        rent_price: form.rent_price === '' ? null : Number(form.rent_price),
        sell_price: form.sell_price === '' ? null : Number(form.sell_price),
        rent_type: form.sell_price ? null : form.rent_type,
        availability: form.availability ? '1' : '2',
      };

      if (editing?.id) {
        await updateListing(editing.id, payload);
        setFeedback({ success: 'Listing updated.', error: '' });
      } else {
        await createListing(payload);
        setFeedback({ success: 'Listing created.', error: '' });
      }

      closeModal();
      loadRows();
    } catch (err) {
      console.error(err);
      setFeedback({ error: err?.error || err?.message || 'Failed to save listing.', success: '' });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this listing?')) return;
    try {
      await deleteListing(id);
      setFeedback({ success: 'Listing deleted.', error: '' });
      loadRows();
    } catch (err) {
      console.error(err);
      setFeedback({ error: err?.error || err?.message || 'Delete failed.', success: '' });
    }
  };

  if (loading && rows.length === 0) {
    return (
      <div className="rental-page">
        <div className="advanced-panel">
          <div className="text-center py-5">
            <Spinner animation="border" style={{ color: '#e7b904' }} />
            <p className="text-muted mt-2">Loading listings...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="rental-page">
      <div className="advanced-panel mb-0">
        <div className="advanced-panel-header">
          <h5>
            <i className="feather icon-map-pin me-2" />
            Listings
          </h5>
          <div className="d-flex gap-2 flex-wrap">
            <Form.Control
              value={search}
              onChange={(event) => {
                setSearch(event.target.value);
                setPage(1);
              }}
              placeholder="Search title or address"
              style={{ width: 220 }}
            />
            <Form.Select
              value={availability}
              onChange={(event) => {
                setAvailability(event.target.value);
                setPage(1);
              }}
              style={{ width: 150 }}
            >
              <option value="">All availability</option>
              <option value="1">Available</option>
              <option value="2">Unavailable</option>
            </Form.Select>
            <Button size="sm" variant="outline-primary" onClick={loadRows}>
              Refresh
            </Button>
            <Button size="sm" variant="primary" onClick={openCreate}>
              Add Listing
            </Button>
          </div>
        </div>

        {feedback.error && <Alert variant="danger">{feedback.error}</Alert>}
        {feedback.success && <Alert variant="success">{feedback.success}</Alert>}

        {rows.length === 0 ? (
          <p className="text-muted mb-0">No listings found.</p>
        ) : (
          <>
            <div className="table-responsive rental-table-wrap">
              <Table hover responsive className="rental-table mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Title</th>
                    <th>Address</th>
                    <th>Owner</th>
                    <th>Mode</th>
                    <th>Price</th>
                    <th>Availability</th>
                    <th className="text-end">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((row) => {
                    const hasSellPrice = Number(row.sell_price || 0) > 0;
                    const priceLabel = hasSellPrice ? money(row.sell_price) : money(row.rent_price);
                    const mode = hasSellPrice ? 'Sell' : `Rent / ${row.rent_type || 'monthly'}`;
                    return (
                      <tr key={row.id}>
                        <td>{row.id}</td>
                        <td className="fw-bold">{row.title}</td>
                        <td>{row.address ?? '-'}</td>
                        <td>{row.user?.name ?? row.user_id ?? '-'}</td>
                        <td>{mode}</td>
                        <td>{priceLabel}</td>
                        <td>
                          <Badge bg={parseBooleanAvailability(row.availability) ? 'success' : 'secondary'}>
                            {parseBooleanAvailability(row.availability) ? 'Available' : 'Unavailable'}
                          </Badge>
                        </td>
                        <td className="text-end">
                          <Button size="sm" variant="outline-primary" className="me-2" onClick={() => openEdit(row)}>
                            Edit
                          </Button>
                          <Button size="sm" variant="outline-danger" onClick={() => handleDelete(row.id)}>
                            Delete
                          </Button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </Table>
            </div>

            {pagination.totalPages > 1 && (
              <Pagination className="mt-3 mb-0 flex-wrap">
                <Pagination.Prev disabled={page <= 1} onClick={() => setPage((current) => Math.max(1, current - 1))} />
                <Pagination.Item active>{page}</Pagination.Item>
                <Pagination.Next
                  disabled={page >= pagination.totalPages}
                  onClick={() => setPage((current) => Math.min(pagination.totalPages, current + 1))}
                />
              </Pagination>
            )}
          </>
        )}
      </div>

      <Modal show={showModal} onHide={closeModal} size="lg" centered className="rental-modal">
        <Modal.Header closeButton className="rental-modal-header">
          <Modal.Title>
            <i className="feather icon-edit-3 me-2" />
            {editing ? 'Edit Listing' : 'Create Listing'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="g-3">
            <Col md={12}>
              <Form.Label>Title</Form.Label>
              <Form.Control value={form.title} onChange={(event) => handleFormChange('title', event.target.value)} />
            </Col>
            <Col md={12}>
              <Form.Label>Address</Form.Label>
              <Form.Control value={form.address} onChange={(event) => handleFormChange('address', event.target.value)} />
            </Col>
            <Col md={6}>
              <Form.Label>Latitude</Form.Label>
              <Form.Control type="number" step="any" value={form.lat} onChange={(event) => handleFormChange('lat', event.target.value)} />
            </Col>
            <Col md={6}>
              <Form.Label>Longitude</Form.Label>
              <Form.Control type="number" step="any" value={form.lng} onChange={(event) => handleFormChange('lng', event.target.value)} />
            </Col>
            <Col md={12}>
              <Form.Label>Description</Form.Label>
              <Form.Control as="textarea" rows={4} value={form.description} onChange={(event) => handleFormChange('description', event.target.value)} />
            </Col>
            <Col md={6}>
              <Form.Label>Rent Price</Form.Label>
              <Form.Control
                type="number"
                min="0"
                step="0.01"
                value={form.rent_price}
                onChange={(event) => handleFormChange('rent_price', event.target.value)}
                placeholder="Leave empty for sell-only"
              />
            </Col>
            <Col md={6}>
              <Form.Label>Sell Price</Form.Label>
              <Form.Control
                type="number"
                min="0"
                step="0.01"
                value={form.sell_price}
                onChange={(event) => handleFormChange('sell_price', event.target.value)}
                placeholder="Leave empty for rent-only"
              />
            </Col>
            <Col md={6}>
              <Form.Label>Rent Type</Form.Label>
              <Form.Select
                value={form.rent_type}
                onChange={(event) => handleFormChange('rent_type', event.target.value)}
                disabled={activePriceField === 'sell'}
              >
                <option value="daily">Daily</option>
                <option value="monthly">Monthly</option>
                <option value="yearly">Yearly</option>
              </Form.Select>
            </Col>
            <Col md={6} className="d-flex align-items-end">
              <Form.Check
                type="switch"
                id="listing-availability"
                label="Listing available"
                checked={form.availability}
                onChange={(event) => handleFormChange('availability', event.target.checked)}
              />
            </Col>
          </Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="outline-secondary" onClick={closeModal}>
            Cancel
          </Button>
          <Button variant="primary" onClick={handleSave} disabled={saving}>
            {saving ? 'Saving...' : editing ? 'Update Listing' : 'Create Listing'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default ListingsList;
