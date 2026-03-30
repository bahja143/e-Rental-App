import React from 'react';
import { Link } from 'react-router-dom';
import { Col, Row } from 'react-bootstrap';

const cards = [
  {
    title: 'Property Categories',
    description: 'Control the top-level property taxonomy used by listings.',
    icon: 'feather icon-grid',
    url: '/app/rental/property-categories',
    cta: 'Open categories',
  },
  {
    title: 'Facilities',
    description: 'Manage reusable amenity labels shown across the marketplace.',
    icon: 'feather icon-check-square',
    url: '/app/rental/facilities',
    cta: 'Open facilities',
  },
  {
    title: 'Nearby Places',
    description: 'Maintain distance-based reference points for listing context.',
    icon: 'feather icon-map',
    url: '/app/rental/nearby-places',
    cta: 'Open places',
  },
  {
    title: 'FAQs',
    description: 'Keep support content and back-office guidance current.',
    icon: 'feather icon-help-circle',
    url: '/app/rental/faqs',
    cta: 'Open FAQs',
  },
];

const CatalogHub = () => (
  <div className="rental-page">
    <div className="advanced-panel mb-4">
      <div className="advanced-panel-header">
        <h5>
          <i className="feather icon-grid me-2" />
          Catalog Admin
        </h5>
      </div>
      <p className="text-muted mb-0">Reference data, taxonomy, and support content are grouped here so the menu stays lean while the admin functionality stays available.</p>
    </div>
    <Row className="g-4">
      {cards.map((card) => (
        <Col md={6} key={card.title}>
          <div className="hub-card">
            <div className="hub-card-icon">
              <i className={card.icon} />
            </div>
            <h5>{card.title}</h5>
            <p>{card.description}</p>
            <Link to={card.url} className="btn btn-primary btn-sm">
              {card.cta}
            </Link>
          </div>
        </Col>
      ))}
    </Row>
  </div>
);

export default CatalogHub;
