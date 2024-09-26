import React from 'react';
import AdminHeader from './AdminHeader';
import EventosList from './EventosList';
import EventoForm from './EventoForm';

const Admin = () => {
  return (
    <div>
      <AdminHeader />
      <EventoForm />
      <EventosList />
    </div>
  );
};

export default Admin;
