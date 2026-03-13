import PropTypes from 'prop-types';
import React from 'react';

// react-bootstrap
import { Alert } from 'react-bootstrap';

// ==============================|| NOTIFICATION ||============================== //

const Notification = (props) => {
  return (
    <React.Fragment>
      <Alert variant="warning">
        {props.message}
        <Alert.Link href={props.link} target="_blank" className="float-right">
          Demo & Documentation
        </Alert.Link>
      </Alert>
    </React.Fragment>
  );
};

Notification.propTypes = {
  message: PropTypes.string,
  link: PropTypes.string
};

export default Notification;
