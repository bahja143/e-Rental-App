import PropTypes from 'prop-types';
import React from 'react';

// third party
import ClassicEditor from '@ckeditor/ckeditor5-build-classic';

// project import
import AllCkEditor from './AllCkEditor';

// ==============================|| CK CLASSIC EDITOR ||============================== //

const CkClassicEditor = (props) => {
  return (
    <React.Fragment>
      <AllCkEditor
        editor={ClassicEditor}
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

CkClassicEditor.propTypes = {
  html: PropTypes.string,
  editor: PropTypes.string
};

export default CkClassicEditor;
