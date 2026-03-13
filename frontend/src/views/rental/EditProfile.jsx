import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

// react-bootstrap
import { Form, Button, Spinner } from 'react-bootstrap';

// project import
import useAuth from '../../hooks/useAuth';

// ==============================|| EDIT PROFILE ||============================== //

const EditProfile = () => {
  const navigate = useNavigate();
  const { user, updateProfile } = useAuth();
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    name: '',
    email: '',
    phone: '',
    city: '',
    profile_picture_url: ''
  });

  useEffect(() => {
    if (user) {
      setForm({
        name: user.name || '',
        email: user.email || '',
        phone: user.phone || '',
        city: user.city || '',
        profile_picture_url: user.profile_picture_url || ''
      });
    }
  }, [user]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((f) => ({ ...f, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await updateProfile({
        name: form.name,
        phone: form.phone || null,
        city: form.city || null,
        profile_picture_url: form.profile_picture_url || null
      });
      navigate('/app/rental/dashboard');
    } catch (err) {
      console.error(err);
      alert(err?.message ?? 'Failed to update profile');
    } finally {
      setSaving(false);
    }
  };

  if (!user) {
    return (
      <div className="rental-page">
        <div className="advanced-panel">
          <div className="text-center py-5">
            <Spinner animation="border" style={{ color: '#e7b904' }} />
            <p className="text-muted mt-2">Loading profile...</p>
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
            <i className="feather icon-user me-2" />
            Edit Profile
          </h5>
        </div>
        <div>
              <Form onSubmit={handleSubmit}>
                <Form.Group className="mb-3">
                  <Form.Label>Name</Form.Label>
                  <Form.Control
                    type="text"
                    name="name"
                    value={form.name}
                    onChange={handleChange}
                    required
                    minLength={2}
                    maxLength={100}
                    placeholder="Your name"
                  />
                </Form.Group>
                <Form.Group className="mb-3">
                  <Form.Label>Email</Form.Label>
                  <Form.Control type="email" value={form.email} disabled readOnly />
                  <Form.Text className="text-muted">Email cannot be changed.</Form.Text>
                </Form.Group>
                <Form.Group className="mb-3">
                  <Form.Label>Phone</Form.Label>
                  <Form.Control
                    type="tel"
                    name="phone"
                    value={form.phone}
                    onChange={handleChange}
                    placeholder="+1234567890"
                  />
                </Form.Group>
                <Form.Group className="mb-3">
                  <Form.Label>City</Form.Label>
                  <Form.Control
                    type="text"
                    name="city"
                    value={form.city}
                    onChange={handleChange}
                    placeholder="Your city"
                  />
                </Form.Group>
                <Form.Group className="mb-4">
                  <Form.Label>Profile Picture URL</Form.Label>
                  <Form.Control
                    type="url"
                    name="profile_picture_url"
                    value={form.profile_picture_url}
                    onChange={handleChange}
                    placeholder="https://..."
                  />
                </Form.Group>
                <div className="d-flex gap-2">
                  <Button type="submit" variant="primary" disabled={saving}>
                    {saving ? (
                      <>
                        <Spinner animation="border" size="sm" className="me-1" />
                        Saving...
                      </>
                    ) : (
                      'Save Changes'
                    )}
                  </Button>
                  <Button type="button" variant="outline-secondary" onClick={() => navigate(-1)}>
                    Cancel
                  </Button>
                </div>
              </Form>
        </div>
      </div>
    </div>
  );
};

export default EditProfile;
