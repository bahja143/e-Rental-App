import React from 'react';
import { NavLink } from 'react-router-dom';

// react-bootstrap
import { Card, Row, Col, Form, Button } from 'react-bootstrap';

// project import
import useAuth from 'hooks/useAuth';
import Breadcrumb from '../../../layouts/AdminLayout/Breadcrumb';

import loginIllustration from '../../../assets/images/auth/login-illustration.svg';

// ==============================|| SIGN UP 1 ||============================== //

const SignUp1 = () => {
  const { isLoggedIn } = useAuth();

  return (
    <React.Fragment>
      <Breadcrumb />
      <div className="auth-wrapper auth-login-split">
        <Row className="g-0 w-100 flex-grow-1 align-items-stretch">
          <Col lg={7} className="auth-login-left d-none d-lg-flex align-items-center justify-content-center">
            <div className="auth-illustration-wrap">
              <img src={loginIllustration} alt="Rental home" className="img-fluid" />
              <div className="auth-illustration-caption">
                <h5 className="fw-bold mb-2">Welcome to Hantario Rental</h5>
                <p className="mb-0">Manage listings, rentals, and bookings from one place.</p>
              </div>
            </div>
          </Col>
          <Col xs={12} lg={5} className="auth-login-right d-flex align-items-center justify-content-center">
            <div className="auth-card-wrapper">
              <Card className="auth-card border-0 shadow">
                <Card.Body>
                  <div className="text-center mb-3">
                    <div className="auth-icon-wrap d-inline-flex align-items-center justify-content-center rounded-circle mb-2">
                      <i className="feather icon-user-plus auth-icon text-brand-gold" />
                    </div>
                    <h5 className="mb-1 text-brand-primary fw-bold">Hantario Rental</h5>
                    <p className="text-muted small mb-0">Create account</p>
                  </div>

                  <Form>
                    <Form.Group className="mb-2">
                      <Form.Control type="text" placeholder="Username" required />
                    </Form.Group>
                    <Form.Group className="mb-2">
                      <Form.Control type="email" placeholder="Email address" required />
                    </Form.Group>
                    <Form.Group className="mb-3">
                      <Form.Control type="password" placeholder="Password" required />
                    </Form.Group>
                    <Form.Group className="mb-3">
                      <Button className="w-100" variant="primary" type="submit">
                        Sign up
                      </Button>
                    </Form.Group>
                  </Form>

                  <div className="mt-3 pt-3 border-top text-center">
                    <p className="mb-0 small text-muted">
                      Already have an account?{' '}
                      <NavLink to={isLoggedIn ? '/auth/signin-1' : '/login'} className="f-w-400 text-brand-primary">
                        Login
                      </NavLink>
                    </p>
                  </div>
                </Card.Body>
              </Card>
            </div>
          </Col>
        </Row>
      </div>
    </React.Fragment>
  );
};

export default SignUp1;
