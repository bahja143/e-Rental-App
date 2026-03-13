import React, { useState } from 'react';

// react-bootstrap
import { Row, Col, Alert, Button, Form } from 'react-bootstrap';

// third party
import * as Yup from 'yup';
import { Formik } from 'formik';

// project import
import useAuth from '../../../hooks/useAuth';
import useScriptRef from '../../../hooks/useScriptRef';

// ==============================|| JWT LOGIN ||============================== //

const JWTLogin = () => {
  const { login } = useAuth();
  const scriptedRef = useScriptRef();
  const [rememberMe, setRememberMe] = useState(true);

  return (
    <Formik
      initialValues={{
        email: '',
        password: '',
        submit: null
      }}
      validationSchema={Yup.object().shape({
        email: Yup.string().email('Must be a valid email').max(255).required('Email is required'),
        password: Yup.string().max(255).required('Password is required')
      })}
      onSubmit={async (values, { setErrors, setStatus, setSubmitting }) => {
        try {
          await login(values.email, values.password, rememberMe);
          if (scriptedRef.current) {
            setStatus({ success: true });
            setSubmitting(false);
          }
        } catch (err) {
          console.error(err);
          if (scriptedRef.current) {
            setStatus({ success: false });
            const msg = err?.error || err?.message || 'Invalid credentials';
            setErrors({ submit: typeof msg === 'string' ? msg : 'Invalid credentials' });
            setSubmitting(false);
          }
        }
      }}
    >
      {({ errors, handleBlur, handleChange, handleSubmit, isSubmitting, touched, values }) => (
        <Form noValidate onSubmit={handleSubmit}>
          <Form.Group className="mb-2">
            <Form.Control
              type="email"
              name="email"
              placeholder="Email address"
              value={values.email}
              onBlur={handleBlur}
              onChange={handleChange}
              isInvalid={touched.email && !!errors.email}
            />
            {touched.email && errors.email && (
              <Form.Control.Feedback type="invalid">{errors.email}</Form.Control.Feedback>
            )}
          </Form.Group>
          <Form.Group className="mb-2">
            <Form.Control
              type="password"
              name="password"
              placeholder="Password"
              value={values.password}
              onBlur={handleBlur}
              onChange={handleChange}
              isInvalid={touched.password && !!errors.password}
            />
            {touched.password && errors.password && (
              <Form.Control.Feedback type="invalid">{errors.password}</Form.Control.Feedback>
            )}
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Check
              type="checkbox"
              id="remember-me"
              label="Remember me"
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              className="text-muted"
            />
          </Form.Group>

          {errors.submit && (
            <Col sm={12}>
              <Alert variant="danger" className="py-2">{errors.submit}</Alert>
            </Col>
          )}

          <Row>
            <Col>
              <Button
                className="w-100 mb-2"
                variant="primary"
                disabled={isSubmitting}
                type="submit"
              >
                {isSubmitting ? 'Signing in...' : 'Sign in'}
              </Button>
            </Col>
          </Row>
        </Form>
      )}
    </Formik>
  );
};

export default JWTLogin;
