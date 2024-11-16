import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesCompactas from './InstrucoesCompactas';
import { FaArrowLeft } from 'react-icons/fa';
import '../styles/AppWithoutGeo.css';
import CenterIcon from '../styles/img/com-geolocalizao.png';

const AppWithoutGeolocation = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [destinos, setDestinos] = useState([]);
  const [showDestinos, setShowDestinos] = useState(false);
  const [selectingOrigem, setSelectingOrigem] = useState(true);
  const [selectedOrigem, setSelectedOrigem] = useState(null);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [rota, setRota] = useState([]);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);
  const mapRef = useRef(null);

  const handleCenterMap = () => {
    if (mapRef.current && selectedOrigem) {
      mapRef.current.setView([selectedOrigem.latitude, selectedOrigem.longitude], 18);
    } else {
      alert('Origem não selecionada para centralizar no mapa.');
    }
  };

  const fetchDestinos = async (query = '') => {
    try {
      const response = await axios.get('/api/destinos');
      let destinosFiltrados = response.data;

      if (query) {
        destinosFiltrados = destinosFiltrados.filter((destino) =>
          destino.destino_nome.toLowerCase().includes(query.toLowerCase()) ||
          (destino.bloco_nome && destino.bloco_nome.toLowerCase().includes(query.toLowerCase())) ||
          (destino.andar_nome && destino.andar_nome.toLowerCase().includes(query.toLowerCase()))
        );
      }

      setDestinos(destinosFiltrados);
      console.log("Destinos filtrados:", destinosFiltrados);
    } catch (error) {
      console.error('Erro ao buscar destinos:', error);
    }
  };

  useEffect(() => {
    if (showDestinos) {
      fetchDestinos(searchQuery);
    }
  }, [showDestinos, searchQuery]);

  const calcularRota = useCallback(async () => {
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
      setInstrucoes(response.data.instrucoes);

      const distanciaTotal = response.data.distanciaTotal;
      const tempoMin = (distanciaTotal * 0.72) / 60;
      const tempoMax = (distanciaTotal * 0.9) / 60;
      setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);
      setConfirmado(true);
    } catch (error) {
      console.error('Erro ao calcular a rota:', error);
      alert('Erro ao calcular a rota. Por favor, tente novamente.');
    }
  }, [selectedOrigem, selectedDestino]);

  const handleBack = () => {
    setShowDestinos(false);
    setSelectedOrigem(null);
    setSelectedDestino(null);
    setConfirmado(false);
    setRota([]);
    setTempoEstimado('');
    setInstrucoes([]);
    setSelectingOrigem(true);
    navigate('/');
  };

  const toggleDestinos = () => {
    setShowDestinos(!showDestinos);
    if (!showDestinos) {
      setSearchQuery('');
      setDestinos([]);
    }
  };

  const handleSelectDestino = (selecionado) => {
    if (selectingOrigem) {
      setSelectedOrigem(selecionado);
      setSelectingOrigem(false);
    } else {
      setSelectedDestino(selecionado);
      setShowDestinos(false);
    }
    setSearchQuery('');
  };

  return (
    <div className="app-without-geolocation">
      <button className="back-arrow" onClick={handleBack}>
        <FaArrowLeft />
      </button>

      <div className="map-section">
        <MapView latitude={null} longitude={null} rota={rota} mapRef={mapRef} />
        <button className="center-button" onClick={handleCenterMap}>
          <img src={CenterIcon} alt="Center Map" style={{ width: '24px', height: '24px' }} />
        </button>
      </div>

      {instrucoes.length > 0 && (
        <InstrucoesCompactas instrucoes={instrucoes} onBack={handleBack} />
      )}

      {selectedOrigem && selectedDestino && !confirmado && (
        <DestinoInfo destino={selectedDestino} origem={selectedOrigem} tempoEstimado={tempoEstimado} onConfirm={calcularRota} />
      )}

      {confirmado && (
        <div className="info-panel">
          <h2>Rota de {selectedOrigem.destino_nome} para {selectedDestino.destino_nome}</h2>
          <p>Tempo estimado: {tempoEstimado}</p>
        </div>
      )}

      <div className="bottom-panel">
        <button className="destino-button" onClick={toggleDestinos}>
          {showDestinos ? 'Voltar' : selectingOrigem ? 'Selecione sua origem' : 'Agora escolha seu destino'}
        </button>
      </div>

      {showDestinos && (
        <div className="search-container">
          <input
            type="text"
            className="search-input"
            placeholder={`Digite o ${selectingOrigem ? 'origem' : 'destino'}`}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          <DestinosList destinos={destinos} onSelectDestino={handleSelectDestino} />
        </div>
      )}
    </div>
  );
};

export default AppWithoutGeolocation;
