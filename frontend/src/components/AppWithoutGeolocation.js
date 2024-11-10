import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesNavegacao from './InstrucoesNavegacao';
import '../styles/AppWithoutGeo.css';
import CenterIcon from '../styles/img/com-geolocalizao.png';

const AppWithoutGeolocation = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [destinos, setDestinos] = useState([]);
  const [showDestinos, setShowDestinos] = useState(false);
  const [selectedOrigem, setSelectedOrigem] = useState(null);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [rota, setRota] = useState([]);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);
  const mapRef = useRef(null);

  useEffect(() => {
    const fetchDestinos = async () => {
      try {
        const response = await axios.get('/api/destinos');
        setDestinos(response.data);
      } catch (error) {
        console.error('Erro ao buscar destinos:', error);
      }
    };
    fetchDestinos();
  }, []);

  const calcularRota = async () => {
    if (!selectedOrigem || !selectedDestino) {
      alert('Por favor, selecione uma origem e um destino.');
      return;
    }

    try {
      const response = await axios.post('/api/rota', {
        origem: selectedOrigem.destino_nome,
        destino: selectedDestino.destino_nome,
      });

      setRota(response.data.rota);
      setTempoEstimado(`${((response.data.distanciaTotal * 0.72) / 60).toFixed(1)} - ${((response.data.distanciaTotal * 0.9) / 60).toFixed(1)} minutos`);
      setInstrucoes(response.data.instrucoes);
      setConfirmado(true);
    } catch (error) {
      console.error('Erro ao calcular a rota:', error);
      alert('Erro ao calcular a rota. Por favor, tente novamente.');
    }
  };

  const handleTrocarDestino = () => {
    setConfirmado(false);
    setRota([]);
    setSelectedDestino(null);
    setSelectedOrigem(null);
    setInstrucoes([]);
    setTempoEstimado('');
    setShowDestinos(false);
    setSearchQuery('');
  };

  return (
    <div className="app-without-geolocation">
      <button className="back-arrow-button" onClick={() => navigate('/')}>←</button>
      <MapView latitude={null} longitude={null} rota={rota} mapRef={mapRef} />

      {instrucoes.length > 0 && (
        <InstrucoesNavegacao instrucoes={instrucoes} />
      )}

      {selectedDestino && selectedOrigem && !confirmado && (
        <DestinoInfo destino={selectedDestino} origem={selectedOrigem} tempoEstimado={tempoEstimado} onConfirm={calcularRota} />
      )}

      {confirmado && (
        <div className="info-panel">
          <h2>Rota de {selectedOrigem.destino_nome} para {selectedDestino.destino_nome}</h2>
          <p>Tempo estimado: {tempoEstimado}</p>
        </div>
      )}

      <div className="bottom-panel">
        <button className="destino-button" onClick={() => setShowDestinos(true)}>
          {showDestinos ? 'Voltar' : 'Selecione seu destino'}
        </button>
      </div>

      {showDestinos && (
        <div className="search-container">
          <input type="text" className="search-input" placeholder="Digite o destino" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
          <DestinosList destinos={destinos} onSelectDestino={(destino) => {
            setSelectedDestino(destino);
            setShowDestinos(false);
          }} />
        </div>
      )}
    </div>
  );
};

export default AppWithoutGeolocation;
