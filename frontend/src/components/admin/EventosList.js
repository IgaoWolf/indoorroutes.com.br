import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';

const EventosList = () => {
  const [eventos, setEventos] = useState([]);

  useEffect(() => {
    const fetchEventos = async () => {
      try {
        const response = await axios.get('/admin/eventos');
        setEventos(response.data.eventos); // Acessa 'eventos' no objeto de resposta
      } catch (error) {
        console.error('Erro ao buscar eventos:', error);
      }
    };
    fetchEventos();
  }, []);

  const handleDelete = async (id) => {
    try {
      await axios.delete(`/admin/eventos/${id}`);
      setEventos(eventos.filter(evento => evento.id !== id));
    } catch (error) {
      console.error('Erro ao deletar evento:', error);
    }
  };

  return (
    <div>
      <h2>Lista de Eventos</h2>
      {eventos.length > 0 ? (
        <ul>
          {eventos.map((evento) => (
            <li key={evento.id}>
              <h3>{evento.nome}</h3>
              <p>{evento.descricao}</p>
              <p>{new Date(evento.data_inicio).toLocaleString()} - {new Date(evento.data_fim).toLocaleString()}</p>
              <Link to={`/admin/eventos/editar/${evento.id}`}>Editar</Link>
              <button onClick={() => handleDelete(evento.id)}>Deletar</button>
            </li>
          ))}
        </ul>
      ) : (
        <p>Nenhum evento encontrado.</p>
      )}
    </div>
  );
};

export default EventosList;
