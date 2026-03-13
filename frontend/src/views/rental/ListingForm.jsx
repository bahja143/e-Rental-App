import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';

// react-bootstrap
import { Row, Col, Form, Button, Spinner } from 'react-bootstrap';

// project import
import { getListingById, createListing, updateListing } from '../../services/rentalApi';

// ==============================|| LISTING FORM ||============================== //

const ListingForm = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEdit = !!id;
  const [loading, setLoading] = useState(isEdit);
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

  useEffect(() => {
    if (isEdit) {
      getListingById(id)
        .then((res) => {
          const d = res.data;
          setForm({
            title: d.title ?? '',
            address: d.address ?? '',
            description: d.description ?? '',
            lat: d.lat ?? '0',
            lng: d.lng ?? '0',
            rent_price: d.rent_price ?? '',
            sell_price: d.sell_price ?? '',
            rent_type: d.rent_type ?? 'daily',
            availability: d.availability === '1' || d.availability === true
          });
        })
        .catch(console.error)
        .finally(() => setLoading(false));
    }
  }, [id, isEdit]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((f) => ({ ...f, [name]: type === 'checkbox' ? checked : value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const payload = {
        title: form.title,
        address: form.address,
        description: form.description,
        lat: parseFloat(form.lat) || 0,
        lng: parseFloat(form.lng) || 0,
        rent_price: form.rent_price ? parseInt(form.rent_price, 10) : null,
        sell_price: form.sell_price ? parseInt(form.sell_price, 10) : null,
        rent_type: form.rent_type,
        availability: form.availability ? '1' : '2'
      };
      if (isEdit) {
        await updateListing(id, payload);
      } else {
        await createListing(payload);
      }
      navigate('/app/rental/listings');
    } catch (err) {
      console.error(err);
      alert(err?.message ?? 'Save failed');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="rental-page">
        <div className="advanced-panel">
          <div className="text-center py-5">
            <Spinner animation="border" style={{ color: '#e7b904' }} />
            <p className="text-muted mt-2">Loading listing...</p>
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
            <i className="feather icon-edit-3 me-2" />
            {isEdit ? 'Edit Listing' : 'New Listing'}
          </h5>
        </div>
        <div>
              <Form onSubmit={handleSubmit}>
                <Form.Group className="mb-3">
                  <Form.Label>Title</Form.Label>
                  <Form.Control name="title" value={form.title} onChange={handleChange} required placeholder="Listing title" />
                </Form.Group>
                <Form.Group className="mb-3">
                  <Form.Label>Address</Form.Label>
                  <Form.Control name="address" value={form.address} onChange={handleChange} placeholder="Address" required />
                </Form.Group>
                <Row>
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Label>Latitude</Form.Label>
                      <Form.Control type="number" step="any" name="lat" value={form.lat} onChange={handleChange} placeholder="0" required />
                    </Form.Group>
                  </Col>
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Label>Longitude</Form.Label>
                      <Form.Control type="number" step="any" name="lng" value={form.lng} onChange={handleChange} placeholder="0" required />
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
                    onChange={handleChange}
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
                        onChange={handleChange}
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
                        onChange={handleChange}
                        placeholder="0"
                      />
                    </Form.Group>
                  </Col>
                </Row>
                <Form.Group className="mb-3">
                  <Form.Label>Rent Type</Form.Label>
                  <Form.Control as="select" name="rent_type" value={form.rent_type} onChange={handleChange}>
                    <option value="daily">Daily</option>
                    <option value="monthly">Monthly</option>
                    <option value="yearly">Yearly</option>
                  </Form.Control>
                </Form.Group>
                <Form.Group className="mb-4">
                  <Form.Check type="checkbox" name="availability" label="Available" checked={form.availability} onChange={handleChange} />
                </Form.Group>
                <Button variant="primary" type="submit" disabled={saving}>
                  {saving ? <Spinner size="sm" /> : isEdit ? 'Update' : 'Create'}
                </Button>
                <Button variant="outline-secondary" className="ms-2" onClick={() => navigate('/app/rental/listings')}>
                  Cancel
                </Button>
              </Form>
        </div>
      </div>
    </div>
  );
};

export default ListingForm;
