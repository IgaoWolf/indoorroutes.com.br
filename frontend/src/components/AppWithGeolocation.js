import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesCompactas from './InstrucoesCompactas';
import { FaArrowLeft } from 'react-icons/fa';
import '../styles/AppWithGeo.css';
import * as turf from '@turf/turf';

const AppWithGeolocation = () => {
  const navigate = useNavigate();
  const [latitude, setLatitude] = useState(null);
  const [longitude, setLongitude] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [destinos, setDestinos] = useState([]);
  const [showDestinos, setShowDestinos] = useState(false);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [rota, setRota] = useState([]);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);
  const [isRecalculating, setIsRecalculating] = useState(false);

  const mapRef = useRef(null);

  const handleCenterMap = () => {
    if (latitude && longitude && mapRef.current) {
      mapRef.current.setView([latitude, longitude], 18);
    } else {
      alert('Localização não disponível para centralizar no mapa.');
    }
  };

  useEffect(() => {
    if (navigator.geolocation) {
      const watchId = navigator.geolocation.watchPosition(
        (position) => {
          setLatitude(position.coords.latitude);
          setLongitude(position.coords.longitude);
        },
        (error) => {
          console.error('Erro ao obter geolocalização:', error);
        },
        { enableHighAccuracy: true, maximumAge: 1000, timeout: 5000 }
      );
      return () => navigator.geolocation.clearWatch(watchId);
    }
  }, []);

  const fetchDestinos = async () => {
    try {
      const response = await axios.get('/api/destinos');
      setDestinos(response.data);
    } catch (error) {
      console.error('Erro ao buscar destinos:', error);
    }
  };

  useEffect(() => {
    if (showDestinos) {
      fetchDestinos();
    }
  }, [showDestinos]);

  const calcularRota = useCallback(
    async (destino) => {
      if (!latitude || !longitude || !destino) {
        alert('Por favor, selecione um destino e garanta que a localização esteja disponível.');
        return;
      }

      try {
        const response = await axios.post('/api/rota', {
          latitude,
          longitude,
          destino: destino.destino_nome,
        });

        setRota(response.data.rota);
        setInstrucoes(response.data.instrucoes);

        const distanciaTotal = response.data.distanciaTotal;
        const tempoMin = (distanciaTotal * 0.72) / 60;
        const tempoMax = (distanciaTotal * 0.9) / 60;
        setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);
        setConfirmado(true);
        setIsRecalculating(false);
      } catch (error) {
        console.error('Erro ao calcular a rota:', error);
        setIsRecalculating(false);
      }
    },
    [latitude, longitude]
  );

  const toggleDestinos = () => {
    setShowDestinos(!showDestinos);
    if (showDestinos) {
      setSelectedDestino(null);
      setConfirmado(false);
    }
  };

  return (
    <div className="app-with-geolocation">
      <button className="back-arrow" onClick={() => navigate('/')}>
        <FaArrowLeft />
      </button>

      <div className="map-section">
        <MapView latitude={latitude} longitude={longitude} rota={rota} mapRef={mapRef} />
        <button className="center-button" onClick={handleCenterMap}>📍</button>
      </div>

      {instrucoes.length > 0 && (
        <InstrucoesCompactas instrucao={instrucoes[0]} />
      )}

      {selectedDestino && !confirmado && (
        <DestinoInfo destino={selectedDestino} tempoEstimado={tempoEstimado} onConfirm={() => calcularRota(selectedDestino)} />
      )}

      {confirmado && (
        <div className="info-panel">
          <h2>{selectedDestino.destino_nome}</h2>
          <p>Tempo estimado: {tempoEstimado}</p>
        </div>
      )}

      <div className="bottom-panel">
        <button className="destino-button" onClick={toggleDestinos}>
          {showDestinos ? 'Voltar' : 'Qual seu destino?'}
        </button>
      </div>

      {showDestinos && (
        <div className="search-container">
          <input type="text" className="search-input" placeholder="Digite o destino" value={searchQuery} onChange={(event) => setSearchQuery(event.target.value)} />
          <DestinosList destinos={destinos} onSelectDestino={(destino) => { setSelectedDestino(destino); setShowDestinos(false); setConfirmado(false); }} />
        </div>
      )}
    </div>
  );
};

export default AppWithGeolocation;

