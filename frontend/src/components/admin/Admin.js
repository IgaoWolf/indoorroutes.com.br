import React from 'react';
import { Routes, Route } from 'react-router-dom';
import AdminHeader from './AdminHeader';
import EventosList from './EventosList';
import EventoForm from './EventoForm';

const Admin = () => {
  return (
    <div>
      <AdminHeader />
      <div className="admin-container">
        <Routes>
          <Route path="/" element={<EventosList />} />
          <Route path="eventos" element={<EventosList />} />
          <Route path="eventos/novo" element={<EventoForm />} />
          <Route path="eventos/editar/:id" element={<EventoForm />} />
        </Routes>
      </div>
    </div>
  );
};

export default Admin;
