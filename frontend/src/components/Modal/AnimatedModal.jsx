import PropTypes from 'prop-types';
import React from 'react';

// third party
import Rodal from 'rodal';
import 'rodal/lib/rodal.css';

// ==============================|| ANIMATED MODAL ||============================== //

const AnimatedModal = (props) => {
  return (
    <React.Fragment>
      <Rodal visible={props.visible} onClose={props.onClose} animation={props.animation}>
        {props.children}
      </Rodal>
    </React.Fragment>
  );
};

AnimatedModal.propTypes = {
  visible: PropTypes.bool,
  onClose: PropTypes.func,
  animation: PropTypes.string,
  children: PropTypes.node
};

export default AnimatedModal;
