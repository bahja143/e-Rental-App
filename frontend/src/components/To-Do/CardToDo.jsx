import PropTypes from 'prop-types';
import React, { useState, useEffect } from 'react';

// react-bootstrap
import { Row, Col, Button, Form as BSForm, InputGroup } from 'react-bootstrap';

// third party
import * as Yup from 'yup';
import { Formik, Form, Field, ErrorMessage } from 'formik';

// project import
import axios from '../../utils/axios';

// assets
import complete from '../../assets/images/complete.png';

// ==============================|| CARD TODO ||============================== //

const CardToDo = (props) => {
  const [cardTodo, setCardTodo] = useState([]);

  const { todoList } = props.todoList ? props : [];

  useEffect(() => {
    setCardTodo(todoList);
  }, [todoList]);

  const completeHandler = async (key) => {
    await axios
      .post('/api/todo/card/complete', {
        key: key
      })
      .then((response) => {
        setCardTodo(response.data.cardTodo);
      });
  };

  const completeStyle = {
    backgroundImage: `url(${complete})`,
    position: 'absolute',
    top: '5px',
    right: '5px',
    content: '',
    width: '55px',
    height: '55px',
    backgroundSize: '100%'
  };

  const todoListHtml = cardTodo.map((item, index) => {
    return (
      // eslint-disable-next-line
      <li
        key={index}
        className={item.complete ? 'complete' : ''}
        onKeyUp={() => completeHandler(index)}
        onClick={() => completeHandler(index)}
      >
        {item.complete ? <span style={completeStyle} /> : ''}
        <p>{item.note}</p>
      </li>
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
                  .post('/api/todo/card/add', {
                    note: values.newNote
                  })
                  .then((response) => {
                    setCardTodo(response.data.cardTodo);
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
              <Form onSubmit={handleSubmit} className="mb-3">
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
          <section id="task-container">
            <ul id="task-list">{todoListHtml}</ul>
          </section>
        </Col>
      </Row>
    </React.Fragment>
  );
};

CardToDo.propTypes = {
  todoList: PropTypes.array
};

export default CardToDo;
