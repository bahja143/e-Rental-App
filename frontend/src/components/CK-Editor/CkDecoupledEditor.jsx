import PropTypes from 'prop-types';
import React from 'react';

// third party
import DecoupledEditor from '@ckeditor/ckeditor5-build-decoupled-document';

// project import
import AllCkEditor from './AllCkEditor';

// ==============================|| CK DECOUPLED EDITOR ||============================== //

const CkDecoupledEditor = (props) => {
  return (
    <React.Fragment>
      <AllCkEditor
        editor={DecoupledEditor}
        data={props.html}
        onReady={(editor) => {
          if (props.editor === 'document') {
            const toolbarContainer = document.querySelector('.document-editor__toolbar');
            toolbarContainer.appendChild(editor.ui.view.toolbar.element);
            window.editor = editor;
          }
          // console.log( 'Editor is ready to use!', editor );
        }}
        onChange={() => {
          // const data = editor.getData();
          // console.log( { event, editor, data } );
        }}
        onBlur={() => {
          // console.log( 'Blur.', editor );
        }}
        onFocus={() => {
          // console.log( 'Focus.', editor );
        }}
      />
    </React.Fragment>
  );
};

CkDecoupledEditor.propTypes = {
  html: PropTypes.string,
  editor: PropTypes.string
};

export default CkDecoupledEditor;
