import React, { useState, useEffect } from 'react';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesNavegacao from './InstrucoesNavegacao';
import '../App.css';

const AppWithGeolocation = () => {
  const [latitude, setLatitude] = useState(null);
  const [longitude, setLongitude] = useState(null);
  const [searchQuery, setSearchQuery] = useState(''); // Adicionado searchQuery e setSearchQuery
  const [destinos, setDestinos] = useState([]);
  const [showDestinos, setShowDestinos] = useState(false);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [rota, setRota] = useState([]);
  const [distanciaTotal, setDistanciaTotal] = useState(0);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);

  // Obter a localização atual
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLatitude(position.coords.latitude);
          setLongitude(position.coords.longitude);
        },
        (error) => {
          console.error('Erro ao obter geolocalização:', error);
        }
      );
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

  // Função para calcular a rota e instruções
  const calcularRota = async () => {
    if (!selectedDestino || !latitude || !longitude) {
      alert('Por favor, selecione um destino.');
      return;
    }

    try {
      const response = await axios.post('/api/rota', {
        latitude,
        longitude,
        destino: selectedDestino.destino_nome,
      });

      setRota(response.data.rota);
      setDistanciaTotal(response.data.distanciaTotal);
      setInstrucoes(response.data.instrucoes);

      const tempoMin = (response.data.distanciaTotal * 0.72) / 60;
      const tempoMax = (response.data.distanciaTotal * 0.90) / 60;
      setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);
      setConfirmado(true);
    } catch (error) {
      console.error('Erro ao calcular a rota:', error);
    }
  };

  const handleSearchChange = (event) => {
    setSearchQuery(event.target.value);
  };

  const handleTrocarDestino = () => {
    setConfirmado(false);
    setRota([]);
    setSelectedDestino(null);
    setInstrucoes([]);
  };

  // Filtragem dos destinos conforme a busca
  const filteredDestinos = destinos.filter((destino) =>
    destino.destino_nome.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="app-container">
      {/* Mapa com a rota desenhada */}
      <MapView latitude={latitude} longitude={longitude} rota={rota} />

      {/* Exibe as instruções de navegação, se houver */}
      {instrucoes.length > 0 && <InstrucoesNavegacao instrucoes={instrucoes} />}

      {/* Informações detalhadas do destino selecionado */}
      {selectedDestino && !confirmado && (
        <DestinoInfo
          destino={selectedDestino}
          tempoEstimado={tempoEstimado}
          onClose={() => setSelectedDestino(null)}
          onConfirm={calcularRota}
        />
      )}

      {/* Painel de informações após confirmar o destino */}
      {confirmado && (
        <div className="info-panel">
          <h2>{selectedDestino.destino_nome}</h2>
          <p>Tempo estimado: {tempoEstimado}</p>
        </div>
      )}

      {/* Botão para trocar a rota */}
      {confirmado && (
        <div className="bottom-panel">
          <button className="trocar-destino-button" onClick={handleTrocarDestino}>
            Trocar destino
          </button>
        </div>
      )}

      {/* Botão de seleção de destino */}
      {!selectedDestino && !confirmado && (
        <div className="bottom-panel">
          <button className="destino-button" onClick={() => setShowDestinos(!showDestinos)}>
            Qual seu destino?
          </button>
        </div>
      )}

      {/* Exibição do componente DestinosList quando showDestinos for verdadeiro */}
      {showDestinos && (
        <div className="search-container">
          <input
            type="text"
            className="search-input"
            placeholder="Digite o destino"
            value={searchQuery}
            onChange={handleSearchChange}
          />
          {/* Lista de destinos */}
          <DestinosList
            destinos={filteredDestinos}
            onSelectDestino={(destino) => {
              setSelectedDestino(destino);
              setConfirmado(false);
              setShowDestinos(false);
            }}
          />
        </div>
      )}
    </div>
  );
};

export default AppWithGeolocation;
