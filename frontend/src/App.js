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
  const [rota, setRota] = useState([]);
  const [distanciaTotal, setDistanciaTotal] = useState(0); // Adicionado estado para a distância
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [tempoEstimado, setTempoEstimado] = useState(''); // Adicionado estado para o tempo estimado

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

  const calcularRota = async (destino) => {
    if (!latitude || !longitude || !destino) {
      alert('Por favor, insira a latitude, longitude e selecione um destino.');
      return;
    }

    try {
      const response = await axios.post('/api/rota', {
        latitude,
        longitude,
        destino: destino.nome,
      });

      setRota(response.data.rota);
      setDistanciaTotal(response.data.distanciaTotal); // Salva a distância total

      // Calcula o tempo estimado de caminhada com base na distância
      const tempoMin = (response.data.distanciaTotal * 0.72) / 60; // Tempo mínimo em minutos
      const tempoMax = (response.data.distanciaTotal * 0.90) / 60; // Tempo máximo em minutos
      setTempoEstimado(`Tempo estimado: ${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);

    } catch (error) {
      console.error('Erro ao calcular a rota:', error);
    }
  };

  const handleSearchChange = (event) => {
    setSearchQuery(event.target.value);
  };

  const filteredDestinos = destinos.filter((destino) =>
    destino.nome.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="app-container">
      <MapView latitude={latitude} longitude={longitude} rota={rota} />

      {selectedDestino && (
        <DestinoInfo destino={selectedDestino} tempoEstimado={tempoEstimado} onClose={() => setSelectedDestino(null)} />
      )}

      {!selectedDestino && (
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
                onSelectDestino={(destino) => {
                  setSelectedDestino(destino);
                  calcularRota(destino);
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

