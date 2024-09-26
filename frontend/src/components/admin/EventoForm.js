import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate, useParams } from 'react-router-dom';

const EventoForm = () => {
  const [nome, setNome] = useState('');
  const [descricao, setDescricao] = useState('');
  const [dataInicio, setDataInicio] = useState('');
  const [dataFim, setDataFim] = useState('');
  const [destinos, setDestinos] = useState([]);
  const [destinoId, setDestinoId] = useState('');
  const { id } = useParams(); // Se o evento já existir
  const navigate = useNavigate(); // Correção na navegação

  useEffect(() => {
    const fetchDestinos = async () => {
      try {
        const response = await axios.get('/api/destinos');
        setDestinos(response.data);
      } catch (error) {
        console.error('Erro ao buscar destinos:', error);
      }
    };

    if (id) {
      // Buscar detalhes do evento existente para edição
      const fetchEvento = async () => {
        try {
          const response = await axios.get(`/admin/eventos/${id}`);
          const evento = response.data;
          setNome(evento.nome);
          setDescricao(evento.descricao);
          setDataInicio(evento.data_inicio);
          setDataFim(evento.data_fim);
          setDestinoId(evento.destino_id);
        } catch (error) {
          console.error('Erro ao buscar evento:', error);
        }
      };
      fetchEvento();
    }

    fetchDestinos();
  }, [id]);

  const handleSubmit = async (event) => {
    event.preventDefault();
    const eventoData = { nome, descricao, data_inicio: dataInicio, data_fim: dataFim, destino_id: destinoId };
    
    try {
      if (id) {
        // Atualizar evento existente
        await axios.put(`/admin/eventos/${id}`, eventoData);
      } else {
        // Criar novo evento
        await axios.post('/admin/eventos', eventoData);
      }
      navigate('/admin/eventos');
    } catch (error) {
      console.error('Erro ao salvar evento:', error);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <h2>{id ? 'Editar Evento' : 'Criar Novo Evento'}</h2>
      <input 
        type="text" 
        placeholder="Nome do Evento" 
        value={nome} 
        onChange={(e) => setNome(e.target.value)} 
        required 
      />
      <textarea 
        placeholder="Descrição do Evento" 
        value={descricao} 
        onChange={(e) => setDescricao(e.target.value)} 
      />
      <input 
        type="datetime-local" 
        value={dataInicio} 
        onChange={(e) => setDataInicio(e.target.value)} 
        required 
      />
      <input 
        type="datetime-local" 
        value={dataFim} 
        onChange={(e) => setDataFim(e.target.value)} 
        required 
      />
      <select value={destinoId} onChange={(e) => setDestinoId(e.target.value)} required>
        <option value="">Selecione um destino</option>
        {destinos.map(destino => (
          <option key={destino.destino_id} value={destino.destino_id}>
            {destino.destino_nome}
          </option>
        ))}
      </select>
      <button type="submit">{id ? 'Atualizar Evento' : 'Criar Evento'}</button>
    </form>
  );
};

export default EventoForm;
