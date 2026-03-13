import React, { useContext } from 'react';
import { Link } from 'react-router-dom';

// react-bootstrap
import { ListGroup, Dropdown } from 'react-bootstrap';

// project import
import { ConfigContext } from '../../../../contexts/ConfigContext';
import useAuth from '../../../../hooks/useAuth';

// assets
import avatar1 from '../../../../assets/images/user/avatar-1.jpg';

// ==============================|| NAV RIGHT ||============================== //

const NavRight = () => {
  const configContext = useContext(ConfigContext);
  const { user, logout } = useAuth();
  const { rtlLayout } = configContext.state;

  const displayName = user?.name || user?.email || 'User';
  const rawRole = user?.role ? String(user.role).charAt(0).toUpperCase() + String(user.role).slice(1) : null;
  const userRole = rawRole && rawRole.toLowerCase() !== displayName.toLowerCase() ? rawRole : null;
  const avatarSrc = user?.profile_picture_url || avatar1;

  const handleLogout = async () => {
    try {
      await logout();
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <ListGroup as="ul" bsPrefix=" " className="navbar-nav ml-auto align-items-center" id="navbar-right">
      <ListGroup.Item as="li" bsPrefix=" " className="d-flex align-items-center">
        <Dropdown align={!rtlLayout ? 'end' : 'start'} className="drp-user">
          <Dropdown.Toggle as={Link} variant="link" to="#" id="dropdown-basic" className="rental-user-toggle">
            <span className="rental-user-block">
              <span className="rental-user-avatar-wrap">
                <img src={avatarSrc} className="rental-user-avatar" alt="" />
              </span>
              <span className="rental-user-info d-none d-md-flex">
                <span className="rental-user-name">{displayName}</span>
                {userRole && <span className="rental-user-role">{userRole}</span>}
              </span>
              <i className="feather icon-chevron-down rental-user-chevron" />
            </span>
          </Dropdown.Toggle>
          <Dropdown.Menu align="end" className="profile-notification">
            <div className="pro-head rental-pro-head">
              <div className="rental-pro-head-avatar">
                <img src={avatarSrc} alt="" />
              </div>
              <div className="rental-pro-head-info">
                <span className="rental-pro-head-name">{displayName}</span>
                {userRole && <span className="rental-pro-head-role">{userRole}</span>}
              </div>
            </div>
            <ListGroup as="ul" bsPrefix=" " variant="flush" className="pro-body">
              <ListGroup.Item as="li" bsPrefix=" ">
                <Link to="/app/rental/profile" className="dropdown-item">
                  <i className="feather icon-user me-2" />
                  Edit Profile
                </Link>
              </ListGroup.Item>
              <ListGroup.Item as="li" bsPrefix=" ">
                <button type="button" className="dropdown-item w-100 text-start border-0 bg-transparent" onClick={handleLogout}>
                  <i className="feather icon-log-out me-2" />
                  Logout
                </button>
              </ListGroup.Item>
            </ListGroup>
          </Dropdown.Menu>
        </Dropdown>
      </ListGroup.Item>
    </ListGroup>
  );
};

export default NavRight;
