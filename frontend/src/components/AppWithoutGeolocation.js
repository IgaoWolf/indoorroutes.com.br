import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import OrigemDestinoSelector from './OrigemDestinoSelector';
import '../styles/AppWithoutGeo.css';
import CenterIcon from '../styles/img/com-geolocalizao.png';

const AppWithoutGeolocation = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [destinos, setDestinos] = useState([]);
  const [filteredDestinos, setFilteredDestinos] = useState([]); // Destinos filtrados pela busca
  const [showOrigemList, setShowOrigemList] = useState(false);
  const [showDestinoList, setShowDestinoList] = useState(false);
  const [selectedOrigem, setSelectedOrigem] = useState(null);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [rota, setRota] = useState([]);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const mapRef = useRef(null);

  // Busca os destinos na API
  const fetchDestinos = async (query = '') => {
    try {
      const response = await axios.get('/api/destinos');
      let destinosFiltrados = response.data;

      // Filtra os destinos com base na query (similar ao AppWithGeolocation)
      if (query) {
        destinosFiltrados = destinosFiltrados.filter((destino) =>
          destino.destino_nome.toLowerCase().includes(query.toLowerCase()) ||
          (destino.bloco_nome && destino.bloco_nome.toLowerCase().includes(query.toLowerCase())) ||
          (destino.andar_nome && destino.andar_nome.toLowerCase().includes(query.toLowerCase()))
        );
      }

      setDestinos(response.data); // Armazena todos os destinos
      setFilteredDestinos(destinosFiltrados); // Armazena os destinos filtrados
    } catch (error) {
      console.error('Erro ao buscar destinos:', error);
    }
  };

  useEffect(() => {
    fetchDestinos(); // Inicializa com todos os destinos ao carregar
  }, []);

  // Atualiza os destinos filtrados sempre que a busca muda
  useEffect(() => {
    fetchDestinos(searchQuery);
  }, [searchQuery]);

  const handleSelectOrigem = (origem) => {
    setSelectedOrigem(origem);
    setShowOrigemList(false);
    if (selectedDestino) {
      calcularRota(origem, selectedDestino);
    }
  };

  const handleSelectDestino = (destino) => {
    setSelectedDestino(destino);
    setShowDestinoList(false);
    if (selectedOrigem) {
      calcularRota(selectedOrigem, destino);
    }
  };

  const calcularRota = useCallback(
    async (origem, destino) => {
      if (!origem || !destino) return;

      try {
        const response = await axios.post('/api/rota', {
          origem: origem.destino_nome,
          destino: destino.destino_nome,
        });

        setRota(response.data.rota);

        const distanciaTotal = response.data.distanciaTotal;
        const tempoMin = (distanciaTotal * 0.72) / 60;
        const tempoMax = (distanciaTotal * 0.9) / 60;
        setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);
      } catch (error) {
        console.error('Erro ao calcular a rota:', error);
        alert('Erro ao calcular a rota. Por favor, tente novamente.');
      }
    },
    []
  );

  const handleBack = () => {
    setShowOrigemList(false);
    setShowDestinoList(false);
    setSelectedOrigem(null);
    setSelectedDestino(null);
    setRota([]);
    setTempoEstimado('');
    navigate('/');
  };

  return (
    <div className="app-without-geolocation">
      <div className="map-section">
        <MapView latitude={null} longitude={null} rota={rota} mapRef={mapRef} />
        <button className="center-button">
          <img src={CenterIcon} alt="Center Map" style={{ width: '24px', height: '24px' }} />
        </button>
      </div>

      {/* Componente de seleção de origem e destino */}
      <OrigemDestinoSelector
        origem={selectedOrigem}
        destino={selectedDestino}
        onSelectOrigem={() => {
          setSearchQuery('');
          setShowOrigemList(true);
        }}
        onSelectDestino={() => {
          setSearchQuery('');
          setShowDestinoList(true);
        }}
        onBack={handleBack}
        onGenerateRoute={() => calcularRota(selectedOrigem, selectedDestino)}
        isGenerateRouteDisabled={!selectedOrigem || !selectedDestino}
        showSearchContainer={showOrigemList || showDestinoList}
        searchContainer={
          (showOrigemList || showDestinoList) && (
            <div className="search-container">
              <input
                type="text"
                className="search-input"
                placeholder={`Digite ${showOrigemList ? 'a origem' : 'o destino'}`}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
              <DestinosList
                destinos={filteredDestinos} // Usa os destinos filtrados
                onSelectDestino={showOrigemList ? handleSelectOrigem : handleSelectDestino}
              />
            </div>
          )
        }
      />

      {/* Tempo estimado e botões */}
      {selectedOrigem && selectedDestino && rota.length > 0 && (
        <div className="route-info-panel">
          <h3>Rota Calculada</h3>
          <p>Tempo estimado: {tempoEstimado}</p>
        </div>
      )}
    </div>
  );
};

export default AppWithoutGeolocation;

