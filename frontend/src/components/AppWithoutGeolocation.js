import React, { useState, useEffect } from 'react';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesNavegacao from './InstrucoesNavegacao';
import '../styles/App.css';

const AppWithoutGeolocation = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [destinos, setDestinos] = useState([]);
  const [showDestinos, setShowDestinos] = useState(false);
  const [selectingOrigem, setSelectingOrigem] = useState(true);
  const [selectedOrigem, setSelectedOrigem] = useState(null);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [rota, setRota] = useState([]);
  const [distanciaTotal, setDistanciaTotal] = useState(0);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);
  const [instrucoesConcluidas, setInstrucoesConcluidas] = useState([]); // Adicionado

  // Buscar destinos ao carregar o componente
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

  // Função para calcular a rota
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
      setDistanciaTotal(response.data.distanciaTotal);
      setInstrucoes(response.data.instrucoes);

      const tempoMin = (response.data.distanciaTotal * 0.72) / 60;
      const tempoMax = (response.data.distanciaTotal * 0.9) / 60;
      setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);
      setConfirmado(true);
      setInstrucoesConcluidas([]); // Reinicia as instruções concluídas
    } catch (error) {
      console.error(
        'Erro ao calcular a rota:',
        error.response ? error.response.data : error.message
      );
      alert('Erro ao calcular a rota. Por favor, tente novamente.');
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
    setDistanciaTotal(0);
    setTempoEstimado('');
    setShowDestinos(false);
    setSearchQuery('');
    setSelectingOrigem(true);
    setInstrucoesConcluidas([]); // Reinicia as instruções concluídas
  };

  // Filtrar destinos com base na busca
  const filteredDestinos = destinos.filter((destino) =>
    destino.destino_nome.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="app-container">
      {/* Mapa com a rota */}
      <MapView latitude={null} longitude={null} rota={rota} />

      {/* Instruções de navegação */}
      {instrucoes.length > 0 && (
        <InstrucoesNavegacao
          instrucoes={instrucoes}
          instrucoesConcluidas={instrucoesConcluidas} // Adicionado
        />
      )}

      {/* Informações detalhadas do destino */}
      {selectedDestino && selectedOrigem && !confirmado && (
        <DestinoInfo
          destino={selectedDestino}
          origem={selectedOrigem}
          tempoEstimado={tempoEstimado}
          onClose={() => {
            setSelectedDestino(null);
            setSelectedOrigem(null);
            setSelectingOrigem(true);
          }}
          onConfirm={calcularRota}
        />
      )}

      {/* Painel de informações após confirmar a rota */}
      {confirmado && (
        <div className="info-panel">
          <h2>
            Rota de {selectedOrigem.destino_nome} para {selectedDestino.destino_nome}
          </h2>
          <p>Tempo estimado: {tempoEstimado}</p>
        </div>
      )}

      {/* Botão para trocar origem e destino */}
      {confirmado && (
        <div className="bottom-panel">
          <button className="trocar-destino-button" onClick={handleTrocarDestino}>
            Trocar origem e destino
          </button>
        </div>
      )}

      {/* Botão para selecionar origem ou destino */}
      {!confirmado && (!selectedOrigem || !selectedDestino) && (
        <div className="bottom-panel">
          <button
            className="destino-button"
            onClick={() => {
              setShowDestinos(true);
            }}
          >
            {selectingOrigem ? 'Selecione sua origem' : 'Selecione seu destino'}
          </button>
        </div>
      )}

      {/* Componente DestinosList */}
      {showDestinos && (
        <div className="search-container">
          <input
            type="text"
            className="search-input"
            placeholder={`Digite o ${selectingOrigem ? 'origem' : 'destino'}`}
            value={searchQuery}
            onChange={handleSearchChange}
          />
          <DestinosList
            destinos={filteredDestinos}
            onSelectDestino={(destino) => {
              if (selectingOrigem) {
                setSelectedOrigem(destino);
                setSelectingOrigem(false);
              } else {
                setSelectedDestino(destino);
              }
              setShowDestinos(false);
              setSearchQuery('');
            }}
          />
        </div>
      )}
    </div>
  );
};

export default AppWithoutGeolocation;
