import React from 'react';
import { Link } from 'react-router-dom';

const AdminHeader = () => {
  return (
    <nav className="admin-header">
      <ul>
        <li>
          <Link to="/admin/eventos">Eventos</Link>
        </li>
        <li>
          <Link to="/admin/eventos/novo">Criar Novo Evento</Link>
        </li>
      </ul>
    </nav>
  );
};

export default AdminHeader;
