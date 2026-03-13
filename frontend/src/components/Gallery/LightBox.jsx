import PropTypes from 'prop-types';
import React from 'react';

// third party
import { Carousel } from 'react-responsive-carousel';

// ==============================|| LIGHTBOX ||============================== //

const LightBox = ({ currentImage, photos }) => {
  return (
    <React.Fragment>
      <Carousel
        showIndicators={false}
        styles={{ zIndex: '9999' }}
        centerMode={true}
        centerSlidePercentage={100}
        selectedItem={currentImage}
        showThumbs={false}
      >
        {photos.map((x, index) => (
          <React.Fragment key={index}>
            <img src={x.src} alt="Gallery" />
          </React.Fragment>
        ))}
      </Carousel>
    </React.Fragment>
  );
};

LightBox.propTypes = {
  currentImage: PropTypes.number,
  photos: PropTypes.array
};

export default LightBox;
