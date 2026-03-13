import PropTypes from 'prop-types';
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';

// react-bootstrap
import { Row, Col, Button, Form as BSForm, InputGroup } from 'react-bootstrap';

// third party
import * as Yup from 'yup';
import { Formik, Form, Field, ErrorMessage } from 'formik';

// project import
import axios from '../../utils/axios';

// ==============================|| BASIC TODO ||============================== //

const BasicToDo = (props) => {
  const [basicTodo, setBasicTodo] = useState([]);

  const { todoList } = props.todoList ? props : [];

  useEffect(() => {
    setBasicTodo(todoList);
  }, [todoList]);

  const completeHandler = async (e, key) => {
    await axios
      .post('/api/todo/basic/complete', {
        key: key,
        complete: e.target.checked
      })
      .then((response) => {
        setBasicTodo(response.data.basicTodo);
      });
  };

  const deleteHandler = async (key) => {
    await axios
      .post('/api/todo/basic/delete', {
        key: key
      })
      .then((response) => {
        setBasicTodo(response.data.basicTodo);
      });
  };

  const todoListHTML = basicTodo.map((item, index) => {
    return (
      <div key={index}>
        <div className="to-do-list mb-3">
          <div className="d-inline-block">
            <div
              className={[
                item.complete ? 'form-check done-task' : '',
                'form-check check-task custom-control custom-checkbox d-flex justify-content-center'
              ].join(' ')}
            >
              <input
                type="checkbox"
                className="form-check-input custom-control-input"
                id={`chktodo-${index}`}
                defaultChecked={item.complete}
                onChange={(e) => completeHandler(e, index)}
              />
              <label className="form-check-label custom-control-label ms-2" htmlFor={`chktodo-${index}`}>
                {item.note}
              </label>
            </div>
          </div>
          <div className="float-end">
            <Link to="#" className="delete_todolist" onClick={() => deleteHandler(index)}>
              <i className="fa fa-trash-alt" />
            </Link>
          </div>
        </div>
      </div>
    );
  });

  return (
    <React.Fragment>
      <Row>
        <Col>
          <Formik
            initialValues={{ newNote: '' }}
            validationSchema={Yup.object().shape({
              newNote: Yup.string().max(255).required('This field is required')
            })}
            onSubmit={async (values, { setErrors, resetForm, setSubmitting }) => {
              try {
                await axios
                  .post('/api/todo/basic/add', {
                    note: values.newNote
                  })
                  .then((response) => {
                    setBasicTodo(response.data.basicTodo);
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
                <InputGroup hasValidation>
                  <Field
                    as={BSForm.Control}
                    name="newNote"
                    placeholder="Create your task list"
                    className={touched.newNote && errors.newNote ? 'is-invalid' : ''}
                  />
                  <Button type="submit" variant="secondary" className="btn-icon">
                    <i className="fa fa-plus" />
                  </Button>
                </InputGroup>
                {errors.newNote && <ErrorMessage name="newNote" component="small" className="text-c-red" />}
              </Form>
            )}
          </Formik>
          <div className="new-task mt-3">{todoListHTML}</div>
        </Col>
      </Row>
    </React.Fragment>
  );
};

BasicToDo.propTypes = {
  todoList: PropTypes.array
};

export default BasicToDo;
