import React from 'react';
import { BrowserRouter as Router, Route, Switch, Link } from 'react-router-dom';
import AdminHeader from './AdminHeader';
import EventosList from './EventosList';
import EventoForm from './EventoForm';
import '../styles/Admin.css';  // Importação do arquivo de estilo

const Admin = () => {
  return (
    <Router>
      <AdminHeader />
      <div className="admin-container">
        <Switch>
          <Route exact path="/admin/eventos" component={EventosList} />
          <Route path="/admin/eventos/novo" component={EventoForm} />
          <Route path="/admin/eventos/editar/:id" component={EventoForm} />
        </Switch>
      </div>
    </Router>
  );
};

export default Admin;
