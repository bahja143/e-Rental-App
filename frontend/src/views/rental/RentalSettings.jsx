import React, { useState, useEffect } from 'react';
import { Form, Button, Spinner, Alert, Row, Col, Card } from 'react-bootstrap';
import { getAppSettings, updateAppSettings } from '../../services/rentalApi';

const RentalSettings = () => {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState({ error: '', success: '' });

  const [form, setForm] = useState({
    videoSharingEnabled: false,
    maintenanceMode: false,
    newRegistrationsEnabled: true,
    maxListingsPerUser: 50,
    appName: 'Hantario Rental'
  });

  useEffect(() => {
    getAppSettings()
      .then((res) => {
        const data = res.data ?? {};
        setForm({
          videoSharingEnabled: Boolean(data.videoSharingEnabled),
          maintenanceMode: Boolean(data.maintenanceMode),
          newRegistrationsEnabled: data.newRegistrationsEnabled !== false,
          maxListingsPerUser: Number(data.maxListingsPerUser) || 50,
          appName: data.appName ?? 'Hantario Rental'
        });
      })
      .catch((e) => {
        setFeedback({ error: e?.error || e?.message || 'Failed to load settings.', success: '' });
      })
      .finally(() => setLoading(false));
  }, []);

  const handleChange = (key, value) => {
    setForm((f) => ({ ...f, [key]: value }));
    setFeedback({ error: '', success: '' });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setFeedback({ error: '', success: '' });
    try {
      await updateAppSettings(form);
      setFeedback({ success: 'Settings saved successfully.', error: '' });
    } catch (e) {
      setFeedback({
        error: e?.error || e?.message || 'Failed to save settings.',
        success: ''
      });
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
            <p className="text-muted mt-2">Loading settings...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="rental-page">
      <div className="advanced-panel mb-0">
        <div className="advanced-panel-header">
          <h5 className="mb-0">
            <i className="feather icon-settings me-2" />
            Settings
          </h5>
        </div>
        <div className="p-4">
          {feedback.error && <Alert variant="danger" dismissible onClose={() => setFeedback((f) => ({ ...f, error: '' }))}>{feedback.error}</Alert>}
          {feedback.success && <Alert variant="success" dismissible onClose={() => setFeedback((f) => ({ ...f, success: '' }))}>{feedback.success}</Alert>}

          <Form onSubmit={handleSubmit}>
            <Card className="border-0 bg-light mb-4">
              <Card.Body>
                <h6 className="text-muted text-uppercase mb-3">General</h6>
                <Form.Group className="mb-0">
                  <Form.Label className="fw-semibold">App Name</Form.Label>
                  <Form.Control
                    value={form.appName}
                    onChange={(e) => handleChange('appName', e.target.value)}
                    placeholder="Hantario Rental"
                    className="form-control-lg"
                  />
                  <Form.Text className="text-muted">Display name for the application.</Form.Text>
                </Form.Group>
              </Card.Body>
            </Card>

            <Card className="border-0 bg-light mb-4">
              <Card.Body>
                <h6 className="text-muted text-uppercase mb-3">Features</h6>
                <Row>
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Check
                        type="switch"
                        id="video-sharing"
                        label="Video Sharing"
                        checked={form.videoSharingEnabled}
                        onChange={(e) => handleChange('videoSharingEnabled', e.target.checked)}
                      />
                      <Form.Text className="text-muted d-block ms-4">Allow video uploads in chat.</Form.Text>
                    </Form.Group>
                  </Col>
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Check
                        type="switch"
                        id="new-registrations"
                        label="New Registrations"
                        checked={form.newRegistrationsEnabled}
                        onChange={(e) => handleChange('newRegistrationsEnabled', e.target.checked)}
                      />
                      <Form.Text className="text-muted d-block ms-4">Allow new user sign-ups.</Form.Text>
                    </Form.Group>
                  </Col>
                </Row>
              </Card.Body>
            </Card>

            <Card className="border-0 bg-light mb-4">
              <Card.Body>
                <h6 className="text-muted text-uppercase mb-3">System</h6>
                <Row>
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Check
                        type="switch"
                        id="maintenance-mode"
                        label="Maintenance Mode"
                        checked={form.maintenanceMode}
                        onChange={(e) => handleChange('maintenanceMode', e.target.checked)}
                      />
                      <Form.Text className="text-muted d-block ms-4">When enabled, the app may restrict access.</Form.Text>
                    </Form.Group>
                  </Col>
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Label className="fw-semibold">Max Listings Per User</Form.Label>
                      <Form.Control
                        type="number"
                        min={1}
                        max={999}
                        value={form.maxListingsPerUser}
                        onChange={(e) => handleChange('maxListingsPerUser', parseInt(e.target.value, 10) || 50)}
                        style={{ maxWidth: 120 }}
                      />
                      <Form.Text className="text-muted">Maximum listings per user (1–999).</Form.Text>
                    </Form.Group>
                  </Col>
                </Row>
              </Card.Body>
            </Card>

            <div className="d-flex gap-2">
              <Button variant="primary" type="submit" disabled={saving}>
                {saving ? (
                  <>
                    <Spinner animation="border" size="sm" className="me-2" />
                    Saving...
                  </>
                ) : (
                  'Save Settings'
                )}
              </Button>
            </div>
          </Form>
        </div>
      </div>
    </div>
  );
};

export default RentalSettings;
