import React from 'react';
import { NavLink } from 'react-router-dom';

// react-bootstrap
import { Card, Row, Col } from 'react-bootstrap';

// project import
import Breadcrumb from '../../../layouts/AdminLayout/Breadcrumb';
import useAuth from 'hooks/useAuth';

import AuthLogin from './JWTLogin';

import loginIllustration from '../../../assets/images/auth/login-illustration.svg';

// ==============================|| SIGN IN 1 ||============================== //

const Signin1 = () => {
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
                    <i className="feather icon-settings auth-icon text-brand-gold" />
                  </div>
                <h5 className="mb-1 text-brand-primary fw-bold">Hantario Rental</h5>
                <p className="text-muted small mb-0">Admin sign in</p>
                </div>

                <AuthLogin />

                <div className="mt-3 pt-3 border-top text-center">
                  <p className="mb-2 small text-muted">
                    Forgot password?{' '}
                    <NavLink to={isLoggedIn ? '/auth/reset-password-1' : '/reset-password'} className="f-w-400 text-brand-primary">
                      Reset
                    </NavLink>
                  </p>
                  <p className="mb-0 small text-muted">
                    Don&apos;t have an account?{' '}
                    <NavLink to={isLoggedIn ? '/auth/signup-1' : '/signup'} className="f-w-400 text-brand-primary">
                      Sign up
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

export default Signin1;
