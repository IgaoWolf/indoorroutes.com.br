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
  const [distanciaTotal, setDistanciaTotal] = useState(0);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [tempoEstimado, setTempoEstimado] = useState('');

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
          console.log('Destinos recebidos:', response.data); // Adicione este log para verificar os dados
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
      alert('Por favor, selecione um destino.');
      return;
    }

    try {
      const response = await axios.post('/api/rota', {
        latitude,
        longitude,
        destino: destino.destino_nome, // Ajuste para refletir a chave correta
      });

      setRota(response.data.rota);
      setDistanciaTotal(response.data.distanciaTotal);

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
  };

  const filteredDestinos = destinos.filter((destino) =>
    destino.destino_nome.toLowerCase().includes(searchQuery.toLowerCase()) // Ajuste o filtro
  );

  return (
    <div className="app-container">
      <MapView latitude={latitude} longitude={longitude} rota={rota} />

      {selectedDestino && !confirmado && (
        <DestinoInfo
          destino={selectedDestino}
          tempoEstimado={tempoEstimado}
          onClose={() => setSelectedDestino(null)}
          onConfirm={handleConfirmarRota}
        />
      )}

      {confirmado && (
        <div className="info-panel">
          <h2>{selectedDestino.destino_nome}</h2> {/* Ajuste aqui */}
          <p>Tempo estimado: {tempoEstimado}</p>
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

