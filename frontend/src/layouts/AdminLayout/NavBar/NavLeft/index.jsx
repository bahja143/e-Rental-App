import React from 'react';

// react-bootstrap
import { ListGroup } from 'react-bootstrap';

// ==============================|| NAV LEFT ||============================== //

const NavLeft = () => {
  return (
    <ListGroup as="ul" bsPrefix=" " className="navbar-nav mr-auto">
      {/* Left side intentionally minimal - only functional items in NavRight */}
    </ListGroup>
  );
};

export default NavLeft;
