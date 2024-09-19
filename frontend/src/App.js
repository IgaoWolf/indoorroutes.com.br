import React, { useState, useEffect } from 'react';
import axios from 'axios';
import MapView from './components/MapView';
import DestinosList from './components/DestinosList';
import DestinoInfo from './components/DestinoInfo';
import './App.css';

const App = () => {
  const [latitude, setLatitude] = useState(null);
  const [longitude, setLongitude] = useState(null);
  const [showDestinos, setShowDestinos] = useState(false);
  const [destinos, setDestinos] = useState([]);
  const [rota, setRota] = useState([]); // Estado para armazenar a rota calculada
  const [distanciaTotal, setDistanciaTotal] = useState(0);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [waypointAndares, setWaypointAndares] = useState({}); // Estado para armazenar o mapeamento de waypoint_id -> andares

  // Função para obter a localização do usuário
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

  // Função para buscar os destinos e seus respectivos andares
  useEffect(() => {
    if (showDestinos) {
      const fetchDestinos = async () => {
        try {
          const response = await axios.get('/api/destinos'); // Pega os destinos
          const destinosData = response.data;

          // Obter os waypoints_id de cada destino
          const waypointIds = destinosData.map(destino => destino.waypoint_id);

          // Agora faz a consulta para obter os andares com base nos waypoint_id
          const andaresResponse = await axios.post('/api/andares', { waypointIds }); // Supondo que a API retorne os andares

          const andaresMap = {}; // Cria um mapeamento de waypoint_id -> andar
          andaresResponse.data.forEach(andar => {
            andaresMap[andar.waypoint_id] = andar.andar;
          });

          setDestinos(destinosData); // Define os destinos
          setWaypointAndares(andaresMap); // Define o mapeamento dos andares

        } catch (error) {
          console.error('Erro ao buscar destinos ou andares:', error);
        }
      };
      fetchDestinos();
    }
  }, [showDestinos]);

  // Função para calcular a rota
  const calcularRota = async (destino) => {
    if (!latitude || !longitude || !destino) {
      alert('Por favor, selecione um destino.');
      return;
    }

    try {
      const response = await axios.post('/api/rota', {
        latitude,
        longitude,
        destino: destino.nome,
      });

      setRota(response.data.rota); // Armazena a rota retornada pela API
      setDistanciaTotal(response.data.distanciaTotal); // Armazena a distância total
      console.log("Rota calculada: ", response.data.rota);

    } catch (error) {
      console.error('Erro ao calcular a rota:', error);
    }
  };

  const handleConfirmarRota = async () => {
    if (selectedDestino) {
      await calcularRota(selectedDestino); // Calcula a rota antes de confirmar
      setConfirmado(true); // Define como confirmado após a rota ser calculada
    }
  };

  const handleTrocarDestino = () => {
    setConfirmado(false);
    setRota([]); // Limpa a rota ao trocar de destino
    setSelectedDestino(null); // Limpa o destino selecionado
  };

  const handleSearchChange = (event) => {
    setSearchQuery(event.target.value);
  };

  // Filtra os destinos com base na consulta de pesquisa
  const filteredDestinos = destinos.filter((destino) =>
    destino.nome.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="app-container">
      <MapView latitude={latitude} longitude={longitude} rota={rota} /> {/* Passa a rota para o MapView */}

      {selectedDestino && !confirmado && (
        <DestinoInfo
          destino={selectedDestino}
          onClose={() => setSelectedDestino(null)}
          onConfirm={handleConfirmarRota}
        />
      )}

      {confirmado && (
        <div className="info-panel">
          <h2>{selectedDestino.nome}</h2>
          <p>Rota confirmada!</p>
          <button className="trocar-destino-button" onClick={handleTrocarDestino}>
            Trocar destino
          </button>
        </div>
      )}

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
              <DestinosList
                destinos={filteredDestinos}
                waypointAndares={waypointAndares} // Passa o mapeamento dos andares para a listagem
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

