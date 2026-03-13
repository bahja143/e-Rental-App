import PropTypes from 'prop-types';
import React from 'react';

// third party
import { Highlight, themes } from 'prism-react-renderer';

// ==============================|| PRISM ||============================== //

const Prism = (props) => {
  return (
    <Highlight theme={themes.dracula} code={props.code} language={props.language}>
      {({ className, style, tokens, getLineProps, getTokenProps }) => (
        <div className="m-t-15">
          <pre className={className} style={style}>
            <code className="language-markup">
              {tokens.map((line, i) => (
                <div key={i} {...getLineProps({ line, key: i })}>
                  {line.map((token, key) => (
                    <span key={key} {...getTokenProps({ token, key })} />
                  ))}
                </div>
              ))}
            </code>
          </pre>
        </div>
      )}
    </Highlight>
  );
};

Prism.propTypes = {
  code: PropTypes.string,
  language: PropTypes.string
};

export default Prism;
