import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesCompactas from './InstrucoesCompactas';
import '../styles/AppWithoutGeo.css';
import CenterIcon from '../styles/img/com-geolocalizao.png';

const AppWithoutGeolocation = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [destinos, setDestinos] = useState([]);
  const [showDestinos, setShowDestinos] = useState(false);
  const [selectingOrigem, setSelectingOrigem] = useState(true); // Controla se estamos selecionando a origem ou o destino
  const [selectedOrigem, setSelectedOrigem] = useState(null);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [rota, setRota] = useState([]);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);
  const mapRef = useRef(null);

  // Função para centralizar o mapa na origem selecionada
  const handleCenterMap = () => {
    if (mapRef.current && selectedOrigem) {
      mapRef.current.setView([selectedOrigem.latitude, selectedOrigem.longitude], 18);
    } else {
      alert('Origem não selecionada para centralizar no mapa.');
    }
  };

  // Busca os destinos na API
  useEffect(() => {
    const fetchDestinos = async () => {
      try {
        const response = await axios.get('/api/destinos');
        setDestinos(response.data);
        console.log("Destinos carregados:", response.data);
      } catch (error) {
        console.error('Erro ao buscar destinos:', error);
      }
    };
    fetchDestinos();
  }, []);

  // Calcula a rota com base nas seleções de origem e destino
  const calcularRota = useCallback(async () => {
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
      setInstrucoes(response.data.instrucoes);

      const distanciaTotal = response.data.distanciaTotal;
      const tempoMin = (distanciaTotal * 0.72) / 60;
      const tempoMax = (distanciaTotal * 0.9) / 60;
      setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);
      setConfirmado(true);
    } catch (error) {
      console.error('Erro ao calcular a rota:', error);
      alert('Erro ao calcular a rota. Por favor, tente novamente.');
    }
  }, [selectedOrigem, selectedDestino]);

  const handleBack = () => {
    setShowDestinos(false);
    setSelectedOrigem(null);
    setSelectedDestino(null);
    setConfirmado(false);
    setRota([]);
    setTempoEstimado('');
    setInstrucoes([]);
    setSelectingOrigem(true); // Volta para o estado inicial de seleção de origem
    navigate('/');
  };

  // Alterna entre selecionar origem e destino
  const toggleDestinos = () => {
    setShowDestinos(true);
    console.log("Exibindo destinos para seleção de", selectingOrigem ? "origem" : "destino");
  };

  return (
    <div className="app-without-geolocation">
      <button className="back-arrow-button" onClick={handleBack}>←</button>

      <div className="map-section">
        <MapView latitude={null} longitude={null} rota={rota} mapRef={mapRef} />
        <button className="center-button" onClick={handleCenterMap}>
          <img src={CenterIcon} alt="Center Map" style={{ width: '24px', height: '24px' }} />
        </button>
      </div>

      {instrucoes.length > 0 && (
        <InstrucoesCompactas instrucoes={instrucoes} onVoltar={handleBack} />
      )}

      {selectedOrigem && selectedDestino && !confirmado && (
        <DestinoInfo destino={selectedDestino} origem={selectedOrigem} tempoEstimado={tempoEstimado} onConfirm={calcularRota} />
      )}

      {confirmado && (
        <div className="info-panel">
          <h2>Rota de {selectedOrigem.destino_nome} para {selectedDestino.destino_nome}</h2>
          <p>Tempo estimado: {tempoEstimado}</p>
        </div>
      )}

      {/* Botão para selecionar origem ou destino */}
      <div className="bottom-panel">
        <button className="destino-button" onClick={toggleDestinos}>
          {showDestinos ? 'Voltar' : selectingOrigem ? 'Selecione sua origem' : 'Selecione seu destino'}
        </button>
      </div>

      {/* Lista de destinos para seleção de origem ou destino */}
      {showDestinos && (
        <div className="search-container">
          <input
            type="text"
            className="search-input"
            placeholder={`Digite o ${selectingOrigem ? 'origem' : 'destino'}`}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          <DestinosList
            destinos={destinos.filter(destino =>
              destino.destino_nome.toLowerCase().includes(searchQuery.toLowerCase())
            )}
            onSelectDestino={(selecionado) => {
              if (selectingOrigem) {
                setSelectedOrigem(selecionado);
                setSelectingOrigem(false); // Após selecionar origem, passa para selecionar destino
              } else {
                setSelectedDestino(selecionado);
                setShowDestinos(false); // Esconde a lista após selecionar o destino
              }
              setSearchQuery(''); // Limpa o campo de busca
              console.log(`${selectingOrigem ? 'Origem' : 'Destino'} selecionado:`, selecionado);
            }}
          />
        </div>
      )}
    </div>
  );
};

export default AppWithoutGeolocation;
