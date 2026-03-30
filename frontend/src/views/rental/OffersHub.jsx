import React from 'react';
import { Link } from 'react-router-dom';
import { Col, Row } from 'react-bootstrap';

const cards = [
  {
    title: 'Coupons',
    description: 'Manage discount codes, activation windows, and usage limits.',
    icon: 'feather icon-tag',
    url: '/app/rental/coupons',
    cta: 'Manage coupons',
  },
  {
    title: 'Promotions',
    description: 'Attach promotional pricing to listings and track campaign status.',
    icon: 'feather icon-award',
    url: '/app/rental/promotions',
    cta: 'Manage promotions',
  },
  {
    title: 'Promotion Packs',
    description: 'Configure the pack options used for promotional upsells.',
    icon: 'feather icon-layers',
    url: '/app/rental/promotion-packs',
    cta: 'Manage promotion packs',
  },
  {
    title: 'Listing Packs',
    description: 'Control premium listing packages and commercial bundle setup.',
    icon: 'feather icon-package',
    url: '/app/rental/listing-packs',
    cta: 'Manage listing packs',
  },
];

const OffersHub = () => (
  <div className="rental-page">
    <div className="advanced-panel mb-4">
      <div className="advanced-panel-header">
        <h5>
          <i className="feather icon-award me-2" />
          Commercial Admin
        </h5>
      </div>
      <p className="text-muted mb-0">Campaign, pricing, and merchandising tools stay together here instead of spreading extra menu items across the whole admin.</p>
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

export default OffersHub;
