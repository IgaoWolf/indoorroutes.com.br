import React, { useState, useEffect } from 'react';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesNavegacao from './InstrucoesNavegacao';
import '../App.css';

const AppWithoutGeolocation = () => {
  const [searchQuery, setSearchQuery] = useState(''); // Adicionado searchQuery e setSearchQuery
  const [destinos, setDestinos] = useState([]);
  const [showDestinos, setShowDestinos] = useState(false);
  const [selectedOrigem, setSelectedOrigem] = useState(null);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [rota, setRota] = useState([]);
  const [distanciaTotal, setDistanciaTotal] = useState(0);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);

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
    if (!selectedOrigem || !selectedDestino) {
      alert('Por favor, selecione uma origem e um destino.');
      return;
    }

    try {
      const response = await axios.post('/api/rota', {
        latitude: selectedOrigem.latitude,
        longitude: selectedOrigem.longitude,
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
    setSelectedOrigem(null);
    setInstrucoes([]);
  };

  // Filtragem dos destinos conforme a busca
  const filteredDestinos = destinos.filter((destino) =>
    destino.destino_nome.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="app-container">
      {/* Mapa com a rota desenhada */}
      <MapView latitude={null} longitude={null} rota={rota} />

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

      {/* Botão para selecionar origem */}
      {!selectedOrigem && (
        <div className="bottom-panel">
          <button
            className="origem-button"
            onClick={() => {
              setShowDestinos(true);
            }}
          >
            Selecione sua origem
          </button>
        </div>
      )}

      {/* Exibe o botão de destino após selecionar a origem */}
      {selectedOrigem && !selectedDestino && (
        <div className="bottom-panel">
          <button
            className="destino-button"
            onClick={() => {
              setShowDestinos(true);
            }}
          >
            Selecione seu destino
          </button>
        </div>
      )}

      {/* Exibição do componente DestinosList quando showDestinos for verdadeiro */}
      {showDestinos && (
        <div className="search-container">
          <input
            type="text"
            className="search-input"
            placeholder="Digite o destino ou origem"
            value={searchQuery}
            onChange={handleSearchChange}
          />
          {/* Lista de destinos */}
          <DestinosList
            destinos={filteredDestinos}
            onSelectOrigem={(origem) => {
              setSelectedOrigem(origem);
              setShowDestinos(false); // Esconder a lista após selecionar a origem
            }}
            onSelectDestino={(destino) => {
              setSelectedDestino(destino);
              setShowDestinos(false); // Esconder a lista após selecionar o destino
            }}
            isSelectingOrigem={!selectedOrigem}
          />
        </div>
      )}
    </div>
  );
};

export default AppWithoutGeolocation;
