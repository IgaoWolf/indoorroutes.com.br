import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesCompactas from './InstrucoesCompactas';
import { FaArrowLeft } from 'react-icons/fa';
import '../styles/AppWithGeo.css';
import CenterIcon from '../styles/img/com-geolocalizao.png';

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
    } catch (error) {
      console.error('Erro ao buscar destinos:', error);
    }
  };

  useEffect(() => {
    if (showDestinos) {
      fetchDestinos(searchQuery);
    }
  }, [showDestinos, searchQuery]);

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
      } catch (error) {
        console.error('Erro ao calcular a rota:', error);
      }
    },
    [latitude, longitude]
  );

  const toggleDestinos = () => {
    setShowDestinos(!showDestinos);
    if (showDestinos) {
      setSelectedDestino(null);
      setConfirmado(false);
      setRota([]);
      setTempoEstimado('');
      setInstrucoes([]);
    }
  };

  const handleBack = () => {
    setShowDestinos(false);
    setSelectedDestino(null);
    setConfirmado(false);
    setRota([]);
    setTempoEstimado('');
    setInstrucoes([]);
    navigate('/');
  };

  return (
    <div className="app-with-geolocation">
      <button className="back-arrow" onClick={handleBack}>
        <FaArrowLeft />
      </button>

      <div className="map-section">
        <MapView latitude={latitude} longitude={longitude} rota={rota} mapRef={mapRef} />
        <button className="center-button" onClick={handleCenterMap}>
          <img src={CenterIcon} alt="Center Map" style={{ width: '24px', height: '24px' }} />
        </button>
      </div>

      {instrucoes.length > 0 && (
        <InstrucoesCompactas
          instrucoes={instrucoes}
          origem={latitude && longitude ? 'Sua localização atual' : 'Localização desconhecida'}
          destino={selectedDestino ? selectedDestino.destino_nome : 'Destino não selecionado'}
          onBack={handleBack}
        />
      )}

      {selectedDestino && !confirmado && (
        <DestinoInfo
          destino={selectedDestino}
          tempoEstimado={tempoEstimado}
          onConfirm={() => calcularRota(selectedDestino)}
        />
      )}

      <div className="bottom-panel">
        <button className="destino-button" onClick={toggleDestinos}>
          {showDestinos ? 'Voltar' : confirmado ? 'Escolher outro destino' : 'Qual seu destino?'}
        </button>
      </div>

      {showDestinos && (
        <div className="search-container">
          <input
            type="text"
            className="search-input"
            placeholder="Digite o destino"
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
          />
          <DestinosList
            destinos={destinos}
            searchQuery={searchQuery}
            onSelectDestino={(destino) => {
              setSelectedDestino(destino);
              setShowDestinos(false);
              setConfirmado(false);
              setRota([]);
              setTempoEstimado('');
              setInstrucoes([]);
            }}
          />
        </div>
      )}
    </div>
  );
};

export default AppWithGeolocation;


