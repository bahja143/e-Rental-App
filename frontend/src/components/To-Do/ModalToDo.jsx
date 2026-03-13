import PropTypes from 'prop-types';
import React, { useState, useEffect } from 'react';

// react-bootstrap
import { Row, Col, Button, Form as BSForm, Modal } from 'react-bootstrap';

// third party
import * as Yup from 'yup';
import { Formik, Form, Field, ErrorMessage } from 'formik';

// project import
import axios from '../../utils/axios';

// ==============================|| MODAL TODO ||============================== //

const ModalToDo = (props) => {
  const [modalTodo, setModalTodo] = useState([]);
  const [isBasic, setIsBasic] = useState(false);

  const { todoList } = props.todoList ? props : [];

  useEffect(() => {
    setModalTodo(todoList);
  }, [todoList]);

  const completeHandler = async (e, key) => {
    await axios
      .post('/api/todo/modal/complete', {
        key: key,
        complete: e.target.checked
      })
      .then((response) => {
        setModalTodo(response.data.modalTodo);
      });
  };

  const deleteHandler = async (key) => {
    await axios
      .post('/api/todo/modal/delete', {
        key: key
      })
      .then((response) => {
        setModalTodo(response.data.modalTodo);
      });
  };

  const todoListHtml = modalTodo.map((item, index) => {
    return (
      <div key={index}>
        <div className="to-do-list mb-3">
          <div className="d-inline-block ">
            <div className={[item.complete ? 'form-check done-task' : '', 'check-task form-check d-flex justify-content-center'].join(' ')}>
              <input
                type="checkbox"
                className="form-check-input custom-control-input"
                id={`chkmdltodo-${index}`}
                defaultChecked={item.complete}
                onChange={(e) => completeHandler(e, index)}
              />
              <label className="form-check-label custom-control-label ms-2" htmlFor={`chkmdltodo-${index}`}>
                {item.note}
              </label>
            </div>
          </div>
          <div className="float-end">
            <a href="#!" className="delete_todolist" onClick={() => deleteHandler(index)}>
              <i className="fa fa-trash-alt" />
            </a>
          </div>
        </div>
      </div>
    );
  });

  return (
    <React.Fragment>
      <Row>
        <Col>
          <div className="new-task">{todoListHtml}</div>
          <Button variant="primary" onClick={() => setIsBasic(true)}>
            ADD NEW TASK
          </Button>
          <Modal show={isBasic} onHide={() => setIsBasic(false)}>
            <Formik
              initialValues={{ newNote: '' }}
              validationSchema={Yup.object().shape({
                newNote: Yup.string().max(255).required('This field is required')
              })}
              onSubmit={async (values, { setErrors, resetForm, setSubmitting }) => {
                try {
                  await axios
                    .post('/api/todo/modal/add', {
                      note: values.newNote
                    })
                    .then((response) => {
                      setModalTodo(response.data.modalTodo);
                    });
                  resetForm();
                  setSubmitting(false);
                } catch (err) {
                  if (scriptedRef.current) {
                    setErrors();
                    setSubmitting(false);
                  }
                }
              }}
            >
              {({ handleSubmit, errors, touched }) => (
                <Form onSubmit={handleSubmit}>
                  <Modal.Header closeButton>
                    <Modal.Title as="h5">Add New Todo</Modal.Title>
                  </Modal.Header>
                  <Modal.Body>
                    <Field
                      as={BSForm.Control}
                      name="newNote"
                      placeholder="Create your task list"
                      className={touched.newNote && errors.newNote ? 'is-invalid' : ''}
                    />
                    {errors.newNote && <ErrorMessage name="newNote" component="small" className="text-c-red" />}
                  </Modal.Body>
                  <Modal.Footer className="p-3">
                    <Button variant="primary" type="submit" onClick={() => setIsBasic(false)}>
                      Save
                    </Button>
                    <Button variant="light" onClick={() => setIsBasic(false)}>
                      Close
                    </Button>
                  </Modal.Footer>
                </Form>
              )}
            </Formik>
          </Modal>
        </Col>
      </Row>
    </React.Fragment>
  );
};

ModalToDo.propTypes = {
  todoList: PropTypes.array
};

export default ModalToDo;
