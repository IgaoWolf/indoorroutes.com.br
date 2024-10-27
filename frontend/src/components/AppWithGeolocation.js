import React, { useState, useEffect, useCallback, useRef } from 'react';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesNavegacao from './InstrucoesNavegacao';
import '../styles/App.css';

const AppWithGeolocation = () => {
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
  const [instrucoesConcluidas, setInstrucoesConcluidas] = useState([]);
  const [isRecalculating, setIsRecalculating] = useState(false);

  const mapRef = useRef(null);

  // Função para centralizar o mapa na posição atual do usuário
  const handleCenterMap = () => {
    if (latitude && longitude && mapRef.current) {
      mapRef.current.setView([latitude, longitude], 18);
    } else {
      alert('Localização não disponível para centralizar no mapa.');
    }
  };

  // Obter a localização atual continuamente
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

  // Função para buscar destinos
  useEffect(() => {
    const fetchDestinos = async () => {
      try {
        const response = await axios.get('/api/destinos');
        setDestinos(response.data);
      } catch (error) {
        console.error('Erro ao buscar destinos:', error);
      }
    };

    if (showDestinos) {
      fetchDestinos();
    }
  }, [showDestinos]);

  // Função para calcular a rota quando o destino é confirmado
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

        // Estimativa de tempo baseada na distância total
        const distanciaTotal = response.data.distanciaTotal;
        const tempoMin = (distanciaTotal * 0.72) / 60;
        const tempoMax = (distanciaTotal * 0.9) / 60;
        setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);
        setIsRecalculating(false);
        setInstrucoesConcluidas([]);
      } catch (error) {
        console.error('Erro ao calcular a rota:', error);
        setIsRecalculating(false);
      }
    },
    [latitude, longitude]
  );

  // Função para alternar a exibição do painel de destinos
  const toggleDestinos = () => {
    setShowDestinos(!showDestinos);
    if (showDestinos) {
      setSelectedDestino(null);
      setConfirmado(false);
    }
  };

  // Função para selecionar um destino
  const handleSelectDestino = (destino) => {
    setSelectedDestino(destino);
    setShowDestinos(false);
  };

  // Função para confirmar o destino e iniciar a rota
  const handleConfirmarDestino = () => {
    if (selectedDestino) {
      calcularRota(selectedDestino);
      setConfirmado(true);
    }
  };

  return (
    <div className="app-container">
      {/* Seção do mapa */}
      <div className="map-section">
        <MapView latitude={latitude} longitude={longitude} rota={rota} mapRef={mapRef} />

        {/* Botão para centralizar o mapa */}
        <button className="center-button" onClick={handleCenterMap}>
          📍
        </button>
      </div>

      {/* Seção da lista de destinos */}
      {showDestinos && (
        <div className="destinos-section">
          <div className="search-container">
            <input
              type="text"
              className="search-input"
              placeholder="Digite o destino"
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
            />
            <div className="destinos-list-container">
              <DestinosList
                destinos={destinos.filter((destino) =>
                  destino.destino_nome.toLowerCase().includes(searchQuery.toLowerCase())
                )}
                onSelectDestino={handleSelectDestino}
              />
            </div>
          </div>
          <div className="voltar-container">
            <button className="destino-button voltar" onClick={toggleDestinos}>
              Voltar
            </button>
          </div>
        </div>
      )}

      {/* Informações do destino selecionado */}
      {selectedDestino && !confirmado && (
        <div className="destino-info-container">
          <DestinoInfo destino={selectedDestino} tempoEstimado={tempoEstimado} />
          <button className="destino-button" onClick={handleConfirmarDestino}>
            Iniciar Rota
          </button>
        </div>
      )}

      {/* Instruções de navegação */}
      {confirmado && (
        <InstrucoesNavegacao
          instrucoes={instrucoes}
          instrucoesConcluidas={instrucoesConcluidas}
          setInstrucoesConcluidas={setInstrucoesConcluidas}
        />
      )}

      {/* Botão para selecionar o destino */}
      {!confirmado && !showDestinos && (
        <div className="bottom-panel">
          <button className="destino-button" onClick={toggleDestinos}>
            Qual seu destino?
          </button>
        </div>
      )}

      {/* Painel de informações após confirmar a rota */}
      {confirmado && (
        <div className="info-panel">
          <h2>{selectedDestino?.destino_nome}</h2>
          <p>Tempo estimado: {tempoEstimado}</p>
        </div>
      )}

      {/* Botão para trocar a rota */}
      {confirmado && (
        <div className="bottom-panel">
          <button className="trocar-destino-button" onClick={toggleDestinos}>
            Trocar destino
          </button>
        </div>
      )}
    </div>
  );
};

export default AppWithGeolocation;

