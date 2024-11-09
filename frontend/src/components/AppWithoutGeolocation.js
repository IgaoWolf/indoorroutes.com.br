import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesNavegacao from './InstrucoesNavegacao';
import '../styles/AppWithoutGeo.css';

const AppWithoutGeolocation = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [destinos, setDestinos] = useState([]);
  const [showDestinos, setShowDestinos] = useState(false);
  const [selectingOrigem, setSelectingOrigem] = useState(true);
  const [selectedOrigem, setSelectedOrigem] = useState(null);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [rota, setRota] = useState([]);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);
  const [instrucoesConcluidas, setInstrucoesConcluidas] = useState([]);
  const mapRef = useRef(null);

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
      setTempoEstimado(`${((response.data.distanciaTotal * 0.72) / 60).toFixed(1)} - ${((response.data.distanciaTotal * 0.9) / 60).toFixed(1)} minutos`);
      setInstrucoes(response.data.instrucoes);
      setConfirmado(true);
      setInstrucoesConcluidas([]);
    } catch (error) {
      console.error('Erro ao calcular a rota:', error);
      alert('Erro ao calcular a rota. Por favor, tente novamente.');
    }
  };

  const handleTrocarDestino = () => {
    setConfirmado(false);
    setRota([]);
    setSelectedDestino(null);
    setSelectedOrigem(null);
    setInstrucoes([]);
    setTempoEstimado('');
    setShowDestinos(false);
    setSearchQuery('');
    setSelectingOrigem(true);
    setInstrucoesConcluidas([]);
  };

  return (
    <div className="app-container">
      {/* Seta de voltar à tela inicial */}
      <button className="back-arrow" onClick={() => navigate('/')}>
        ←
      </button>

      <MapView latitude={null} longitude={null} rota={rota} mapRef={mapRef} />

      {instrucoes.length > 0 && (
        <InstrucoesNavegacao instrucoes={instrucoes} instrucoesConcluidas={instrucoesConcluidas} />
      )}

      {selectedDestino && selectedOrigem && !confirmado && (
        <DestinoInfo destino={selectedDestino} origem={selectedOrigem} tempoEstimado={tempoEstimado} onConfirm={calcularRota} />
      )}

      {confirmado && (
        <div className="info-panel">
          <h2>Rota de {selectedOrigem.destino_nome} para {selectedDestino.destino_nome}</h2>
          <p>Tempo estimado: {tempoEstimado}</p>
        </div>
      )}

      {confirmado && (
        <div className="bottom-panel">
          <button className="trocar-destino-button" onClick={handleTrocarDestino}>Trocar origem e destino</button>
        </div>
      )}

      {!confirmado && (!selectedOrigem || !selectedDestino) && (
        <div className="bottom-panel">
          <button className="destino-button" onClick={() => setShowDestinos(true)}>
            {selectingOrigem ? 'Selecione sua origem' : 'Selecione seu destino'}
          </button>
        </div>
      )}

      {showDestinos && (
        <div className="search-container">
          <input type="text" className="search-input" placeholder={`Digite o ${selectingOrigem ? 'origem' : 'destino'}`} value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
          <DestinosList destinos={destinos.filter((destino) => destino.destino_nome.toLowerCase().includes(searchQuery.toLowerCase()))} onSelectDestino={(destino) => {
            if (selectingOrigem) {
              setSelectedOrigem(destino);
              setSelectingOrigem(false);
            } else {
              setSelectedDestino(destino);
            }
            setShowDestinos(false);
            setSearchQuery('');
          }} />
        </div>
      )}
    </div>
  );
};

export default AppWithoutGeolocation;

