import React, { useContext } from 'react';
import { Link } from 'react-router-dom';

// project import
import { ConfigContext } from '../../../../contexts/ConfigContext';
import * as actionType from '../../../../store/actions';
import brandLogo from '../../../../assets/images/buul-logo-cropped.png';

// ==============================|| NAV LOGO ||============================== //

const NavLogo = () => {
  const configContext = useContext(ConfigContext);
  const { collapseMenu } = configContext.state;
  const { dispatch } = configContext;

  let toggleClass = ['mobile-menu'];
  if (collapseMenu) {
    toggleClass = [...toggleClass, 'on'];
  }

  return (
    <React.Fragment>
      <div className="navbar-brand header-logo">
        <Link to="/app/rental/dashboard" className="b-brand">
          <img src={brandLogo} alt="Buul" className="buul-brand-logo" />
          <span className="b-title">Buul</span>
        </Link>
        <Link to="#" className={toggleClass.join(' ')} id="mobile-collapse" onClick={() => dispatch({ type: actionType.COLLAPSE_MENU })}>
          <span />
        </Link>
      </div>
    </React.Fragment>
  );
};

export default NavLogo;
