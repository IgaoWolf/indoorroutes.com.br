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
  const [showDestinos, setShowDestinos] = useState(false); // Controla a exibição da lista de destinos
  const [destinos, setDestinos] = useState([]);
  const [rota, setRota] = useState([]);
  const [distanciaTotal, setDistanciaTotal] = useState(0);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [selectedOrigem, setSelectedOrigem] = useState(null); // Novo estado para origem
  const [confirmado, setConfirmado] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);
  const [useGeolocation, setUseGeolocation] = useState(true); // Determina se a geolocalização será usada
  const [isSelectingOrigem, setIsSelectingOrigem] = useState(false); // Estado para controlar se está selecionando a origem
  const [isSelectingDestino, setIsSelectingDestino] = useState(false); // Estado para controlar se está selecionando o destino

  // Obter a localização atual
  useEffect(() => {
    if (navigator.geolocation && useGeolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLatitude(position.coords.latitude);
          setLongitude(position.coords.longitude);
        },
        () => {
          // Se a geolocalização falhar ou for negada, desativamos o uso dela
          setUseGeolocation(false);
          setLatitude(-23.55052); // Coordenadas padrão para Assis Burgaz
          setLongitude(-46.633308);
        }
      );
    } else if (!useGeolocation) {
      // Define as coordenadas padrão para Assis Burgaz se geolocalização estiver desativada
      setLatitude(-23.55052);
      setLongitude(-46.633308);
    }
  }, [useGeolocation]);

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
    if (!selectedDestino || (!latitude && !longitude && !selectedOrigem)) {
      alert('Por favor, selecione uma origem e um destino.');
      return;
    }

    try {
      const response = await axios.post('/api/rota', {
        latitude: useGeolocation ? latitude : selectedOrigem.latitude,
        longitude: useGeolocation ? longitude : selectedOrigem.longitude,
        destino: selectedDestino.destino_nome,
      });

      setRota(response.data.rota);
      setDistanciaTotal(response.data.distanciaTotal);
      setInstrucoes(response.data.instrucoes);

      const tempoMin = (response.data.distanciaTotal * 0.72) / 60;
      const tempoMax = (response.data.distanciaTotal * 0.90) / 60;
      setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);
      setConfirmado(true); // Confirma a rota
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
    setSelectedOrigem(null); // Limpa a origem selecionada
    setInstrucoes([]);
  };

  // Função para alternar entre uso da geolocalização e origem manual
  const toggleGeolocation = () => {
    setUseGeolocation(!useGeolocation);
    handleTrocarDestino(); // Reinicia o processo ao trocar a forma de localização
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

      {/* Botões para selecionar origem e destino quando a geolocalização está desativada */}
      {!useGeolocation && !selectedOrigem && (
        <div className="bottom-panel">
          <button
            className="origem-button"
            onClick={() => {
              setShowDestinos(true);
              setIsSelectingOrigem(true);
              setIsSelectingDestino(false);
            }}
          >
            Selecione sua origem
          </button>
        </div>
      )}

      {/* Exibe o botão de destino após selecionar a origem */}
      {!useGeolocation && selectedOrigem && !selectedDestino && (
        <div className="bottom-panel">
          <button
            className="destino-button"
            onClick={() => {
              setShowDestinos(true);
              setIsSelectingDestino(true);
              setIsSelectingOrigem(false);
            }}
          >
            Selecione seu destino
          </button>
        </div>
      )}

      {/* Botão de geolocalização e seleção de destino */}
      {!selectedDestino && !confirmado && useGeolocation && (
        <div className="bottom-panel">
          <button className="destino-button" onClick={() => setShowDestinos(!showDestinos)}>
            {useGeolocation ? 'Qual seu destino?' : 'Selecione seu destino'}
          </button>
          <button onClick={toggleGeolocation}>
            {useGeolocation ? 'Usar origem manual' : 'Usar geolocalização'}
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
            onSelectDestino={(destino) => {
              setSelectedDestino(destino);
              setConfirmado(false);
              setShowDestinos(false); // Esconder a lista de destinos após selecionar
            }}
            onSelectOrigem={(origem) => {
              setSelectedOrigem(origem);
              setShowDestinos(false); // Esconder a lista de destinos após selecionar a origem
            }}
            isSelectingOrigem={isSelectingOrigem} // Passa o estado para o componente
            isSelectingDestino={isSelectingDestino} // Passa o estado para o componente
          />
        </div>
      )}
    </div>
  );
};

export default App;
