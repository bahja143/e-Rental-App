import React, { useState, useEffect, useCallback } from 'react';
import { Link } from 'react-router-dom';

// react-bootstrap
import { Row, Col, Table, Button, Spinner, Pagination, Modal, Form } from 'react-bootstrap';

// project import
import { getListings, deleteListing, createListing } from '../../services/rentalApi';

// ==============================|| LISTINGS LIST ||============================== //

const ListingsList = () => {
  const [listings, setListings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, total: 0 });
  const [showAddModal, setShowAddModal] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    title: '',
    address: '',
    description: '',
    lat: '0',
    lng: '0',
    rent_price: '',
    sell_price: '',
    rent_type: 'daily',
    availability: true
  });

  const resetForm = () => {
    setForm({
      title: '',
      address: '',
      description: '',
      lat: '0',
      lng: '0',
      rent_price: '',
      sell_price: '',
      rent_type: 'daily',
      availability: true
    });
  };

  const handleAddClose = () => {
    setShowAddModal(false);
    resetForm();
  };

  const handleFormChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((f) => ({ ...f, [name]: type === 'checkbox' ? checked : value }));
  };

  const handleAddSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await createListing({
        title: form.title,
        address: form.address,
        description: form.description,
        lat: parseFloat(form.lat) || 0,
        lng: parseFloat(form.lng) || 0,
        rent_price: form.rent_price ? parseInt(form.rent_price, 10) : null,
        sell_price: form.sell_price ? parseInt(form.sell_price, 10) : null,
        rent_type: form.rent_type,
        availability: form.availability ? '1' : '2'
      });
      handleAddClose();
      fetchListings();
    } catch (err) {
      console.error(err);
      alert(err?.message ?? 'Create failed');
    } finally {
      setSaving(false);
    }
  };

  const fetchListings = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getListings({ page, limit: 10 });
      const data = res.data?.data;
      const p = res.data?.pagination ?? {};
      setListings(Array.isArray(data) ? data : []);
      setPagination({
        totalPages: p.totalPages ?? 1,
        total: p.total ?? 0
      });
    } catch (e) {
      console.error(e);
      setListings([]);
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => {
    fetchListings();
  }, [fetchListings]);

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this listing?')) return;
    try {
      await deleteListing(id);
      fetchListings();
    } catch (e) {
      console.error(e);
      alert(e?.message ?? 'Delete failed');
    }
  };

  if (loading && listings.length === 0) {
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
            <i className="feather icon-list me-2" />
            Listings
          </h5>
          <Button size="sm" variant="primary" onClick={() => setShowAddModal(true)}>
            <i className="feather icon-plus me-1" />
            Add Listing
          </Button>
        </div>
        {listings.length === 0 ? (
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
                    <th>Rent Price</th>
                    <th>Rent Type</th>
                    <th>Owner</th>
                    <th>Availability</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {listings.map((l) => (
                    <tr key={l.id}>
                      <td>{l.id}</td>
                      <td className="fw-bold">{l.title}</td>
                      <td>{l.address ?? '-'}</td>
                      <td>${l.rent_price ?? l.sell_price ?? '-'}</td>
                      <td>{l.rent_type ?? '-'}</td>
                      <td>{l.user?.name ?? l.user_id}</td>
                      <td>
                        <span
                          className={`badge ${
                            l.availability === '1' || l.availability === 1 || l.availability === true
                              ? 'bg-success'
                              : 'bg-secondary'
                          }`}
                        >
                          {l.availability === '1' || l.availability === 1 || l.availability === true ? 'Available' : 'Unavailable'}
                        </span>
                      </td>
                      <td className="text-end">
                        <Link
                          to={`/app/rental/listings/${l.id}/edit`}
                          className="btn btn-sm btn-outline-primary me-1"
                          style={{ textDecoration: 'none' }}
                        >
                          Edit
                        </Link>
                        <Button size="sm" variant="outline-danger" onClick={() => handleDelete(l.id)}>
                          Delete
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            </div>
            {pagination.totalPages > 1 && (
              <Pagination className="mt-3 mb-0 flex-wrap">
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

      <Modal show={showAddModal} onHide={handleAddClose} size="lg" centered className="rental-modal">
        <Modal.Header closeButton className="rental-modal-header">
          <Modal.Title>
            <i className="feather icon-plus-circle me-2" />
            Add Listing
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form onSubmit={handleAddSubmit}>
            <Form.Group className="mb-3">
              <Form.Label>Title</Form.Label>
              <Form.Control name="title" value={form.title} onChange={handleFormChange} required placeholder="Listing title" />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Address</Form.Label>
              <Form.Control name="address" value={form.address} onChange={handleFormChange} placeholder="Address" required />
            </Form.Group>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Latitude</Form.Label>
                  <Form.Control type="number" step="any" name="lat" value={form.lat} onChange={handleFormChange} placeholder="0" required />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Longitude</Form.Label>
                  <Form.Control type="number" step="any" name="lng" value={form.lng} onChange={handleFormChange} placeholder="0" required />
                </Form.Group>
              </Col>
            </Row>
            <Form.Group className="mb-3">
              <Form.Label>Description</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                name="description"
                value={form.description}
                onChange={handleFormChange}
                placeholder="Description"
              />
            </Form.Group>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Rent Price</Form.Label>
                  <Form.Control
                    type="number"
                    step="0.01"
                    name="rent_price"
                    value={form.rent_price}
                    onChange={handleFormChange}
                    placeholder="0"
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Sell Price</Form.Label>
                  <Form.Control
                    type="number"
                    step="0.01"
                    name="sell_price"
                    value={form.sell_price}
                    onChange={handleFormChange}
                    placeholder="0"
                  />
                </Form.Group>
              </Col>
            </Row>
            <Form.Group className="mb-3">
              <Form.Label>Rent Type</Form.Label>
              <Form.Control as="select" name="rent_type" value={form.rent_type} onChange={handleFormChange}>
                <option value="daily">Daily</option>
                <option value="monthly">Monthly</option>
                <option value="yearly">Yearly</option>
              </Form.Control>
            </Form.Group>
            <Form.Group className="mb-4">
              <Form.Check type="checkbox" name="availability" label="Available" checked={form.availability} onChange={handleFormChange} />
            </Form.Group>
            <div className="d-flex justify-content-end gap-2">
              <Button variant="secondary" onClick={handleAddClose}>
                Cancel
              </Button>
              <Button variant="primary" type="submit" disabled={saving}>
                {saving ? (
                  <>
                    <Spinner animation="border" size="sm" className="me-1" />
                    Creating...
                  </>
                ) : (
                  'Create'
                )}
              </Button>
            </div>
          </Form>
        </Modal.Body>
      </Modal>
    </div>
  );
};

export default ListingsList;
