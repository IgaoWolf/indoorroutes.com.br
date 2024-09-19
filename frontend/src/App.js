import React, { useState, useEffect } from 'react';
import axios from 'axios';
import MapView from './components/MapView';
import DestinosList from './components/DestinosList';
import DestinoInfo from './components/DestinoInfo';
import InstrucoesNavegacao from './components/InstrucoesNavegacao';
import './App.css';

const App = () => {
  const [latitude, setLatitude] = useState(null);
  const [longitude, setLongitude] = useState(null);
  const [showDestinos, setShowDestinos] = useState(false);
  const [destinos, setDestinos] = useState([]);
  const [rota, setRota] = useState([]);
  const [distanciaTotal, setDistanciaTotal] = useState(0);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]); // Estado para instruções de navegação

  // Obter a localização atual
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        setLatitude(position.coords.latitude);
        setLongitude(position.coords.longitude);
      });
    } else {
      alert('Geolocalização não é suportada pelo seu navegador.');
    }
  }, []);

  // Função para buscar destinos
  useEffect(() => {
    if (showDestinos) {
      const fetchDestinos = async () => {
        try {
          const response = await axios.get('/api/destinos');
          setDestinos(response.data);
        } catch (error) {
          console.error('Erro ao buscar destinos:', error);
        }
      };
      fetchDestinos();
    }
  }, [showDestinos]);

  // Função para calcular a rota e instruções
  const calcularRota = async (destino) => {
    if (!latitude || !longitude || !destino) {
      alert('Por favor, selecione um destino.');
      return;
    }

    try {
      const response = await axios.post('/api/rota', {
        latitude,
        longitude,
        destino: destino.destino_nome, // Ajuste aqui para combinar com os dados do backend
      });

      setRota(response.data.rota);
      setDistanciaTotal(response.data.distanciaTotal);
      setInstrucoes(response.data.instrucoes); // Armazena as instruções recebidas

      const tempoMin = (response.data.distanciaTotal * 0.72) / 60;
      const tempoMax = (response.data.distanciaTotal * 0.90) / 60;
      setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);

    } catch (error) {
      console.error('Erro ao calcular a rota:', error);
    }
  };

  const handleSearchChange = (event) => {
    setSearchQuery(event.target.value);
  };

  const handleConfirmarRota = () => {
    if (selectedDestino) {
      calcularRota(selectedDestino);
      setConfirmado(true); // Confirma a rota para ser gerada
    }
  };

  const handleTrocarDestino = () => {
    setConfirmado(false);
    setRota([]);
    setSelectedDestino(null);
    setInstrucoes([]); // Limpa as instruções ao trocar de destino
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
          onConfirm={handleConfirmarRota}
        />
      )}

      {/* Painel de informações após confirmar o destino */}
      {confirmado && (
        <div className="info-panel">
          <h2>{selectedDestino.destino_nome}</h2>
          <p>Tempo estimado: {tempoEstimado}</p>
          <button className="trocar-destino-button" onClick={handleTrocarDestino}>Trocar destino</button>
        </div>
      )}

      {/* Botão e painel para selecionar o destino */}
      {!selectedDestino && !confirmado && (
        <div className="bottom-panel">
          <button className="destino-button" onClick={() => setShowDestinos(!showDestinos)}>
            Qual seu destino?
          </button>
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
                  setConfirmado(false); // Reseta a confirmação ao selecionar um novo destino
                }}
              />
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default App;
