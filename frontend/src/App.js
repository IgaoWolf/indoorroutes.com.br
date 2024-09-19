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

  // Função para calcular as instruções de navegação, incluindo mudanças de andar
  const calcularInstrucoes = (rota) => {
    return rota.map((ponto, index) => {
      if (index === 0) return "Comece aqui";
      const prevPonto = rota[index - 1];
      
      const deltaX = ponto.longitude - prevPonto.longitude;
      const deltaY = ponto.latitude - prevPonto.latitude;

      // Verifica se há mudança de andar
      if (ponto.andar !== prevPonto.andar) {
        if (ponto.tipo === 'escada') {
          return `Suba para o andar ${ponto.andar} pela escada`;
        } else if (ponto.tipo === 'elevador') {
          return `Pegue o elevador para o andar ${ponto.andar}`;
        } else {
          return `Mude para o andar ${ponto.andar}`;
        }
      }

      // Instruções simples para virar à esquerda, direita, ou seguir em frente
      if (Math.abs(deltaX) > Math.abs(deltaY)) {
        return deltaX > 0 ? "Vire à direita" : "Vire à esquerda";
      } else {
        return deltaY > 0 ? "Siga em frente" : null ;
      }
    });
  };

  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        setLatitude(position.coords.latitude);
        setLongitude(position.coords.longitude);

        // Calcular a rota inicial para o primeiro waypoint
        calcularRota(null); // Passa null para calcular a rota até o primeiro waypoint
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

  // Função para calcular a rota, incluindo a lógica de andar
  const calcularRota = async (destino) => {
    if (!latitude || !longitude) {
      alert('Por favor, permita acesso à sua localização.');
      return;
    }

    try {
      const response = await axios.post('/api/rota', {
        latitude,
        longitude,
        destino: destino ? destino.nome : null, // Se não houver destino, calcula até o primeiro waypoint
      });

      // Supondo que a API retorna 'andar' e 'tipo' (escada/elevador)
      setRota(response.data.rota.map(ponto => ({
        ...ponto,
        andar: ponto.andar || 1, // Define um andar padrão caso não esteja presente
        tipo: ponto.tipo || null, // Define o tipo de movimentação entre andares
      })));
      
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
            {showDestinos ? 'Fechar' : 'Qual seu destino?'}
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
                  calcularRota(destino); // Calcula a rota quando um destino é selecionado
                }}
              />
            </div>
          )}
        </div>
      )}

      {rota.length > 0 && (
        <div className="instrucoes-container">
          {calcularInstrucoes(rota).map((instrucao, index) => (
            <p key={index}>{instrucao}</p>
          ))}
        </div>
      )}
    </div>
  );
};

export default App;

