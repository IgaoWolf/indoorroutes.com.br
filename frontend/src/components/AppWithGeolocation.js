import React, { useState, useEffect, useCallback, useRef } from 'react';
import axios from 'axios';
import MapView from './MapView';
import DestinosList from './DestinosList';
import DestinoInfo from './DestinoInfo';
import InstrucoesNavegacao from './InstrucoesNavegacao';
import '../styles/App.css';
import * as turf from '@turf/turf';

const AppWithGeolocation = () => {
  const [latitude, setLatitude] = useState(null);
  const [longitude, setLongitude] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [destinos, setDestinos] = useState([]);
  const [showDestinos, setShowDestinos] = useState(false);
  const [selectedDestino, setSelectedDestino] = useState(null);
  const [confirmado, setConfirmado] = useState(false);
  const [rota, setRota] = useState([]);
  const [tempoEstimado, setTempoEstimado] = useState('');
  const [instrucoes, setInstrucoes] = useState([]);
  const [instrucoesConcluidas, setInstrucoesConcluidas] = useState([]);
  const [isRecalculating, setIsRecalculating] = useState(false);

  const mapRef = useRef(null);

  // Função para centralizar o mapa na posição atual do usuário
  const handleCenterMap = () => {
    if (latitude && longitude && mapRef.current) {
      mapRef.current.setView([latitude, longitude], 18);
    } else {
      alert('Localização não disponível para centralizar no mapa.');
    }
  };

  // Obter a localização atual continuamente
  useEffect(() => {
    if (navigator.geolocation) {
      const watchId = navigator.geolocation.watchPosition(
        (position) => {
          setLatitude(position.coords.latitude);
          setLongitude(position.coords.longitude);
        },
        (error) => {
          console.error('Erro ao obter geolocalização:', error);
        },
        { enableHighAccuracy: true, maximumAge: 1000, timeout: 5000 }
      );
      return () => navigator.geolocation.clearWatch(watchId);
    }
  }, []);

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

  // Função para alternar a exibição do painel de destinos
  const toggleDestinos = () => {
    setShowDestinos(!showDestinos);
    if (showDestinos) {
      // Se o painel estava visível, voltamos ao estado inicial
      setSelectedDestino(null);
      setConfirmado(false);
    }
  };

  // Função para calcular a rota quando o destino é confirmado
  const calcularRota = useCallback(
    async (destino) => {
      if (!latitude || !longitude || !destino) {
        alert('Por favor, selecione um destino e garanta que a localização esteja disponível.');
        return;
      }

      try {
        const response = await axios.post('/api/rota', {
          latitude,
          longitude,
          destino: destino.destino_nome,
        });

        setRota(response.data.rota);
        setInstrucoes(response.data.instrucoes);
        console.log('Instruções recebidas:', response.data.instrucoes);

        // Estimativa de tempo baseada na distância total
        const distanciaTotal = response.data.distanciaTotal;
        const tempoMin = (distanciaTotal * 0.72) / 60;
        const tempoMax = (distanciaTotal * 0.9) / 60;
        setTempoEstimado(`${tempoMin.toFixed(1)} - ${tempoMax.toFixed(1)} minutos`);
        setConfirmado(true);
        setIsRecalculating(false);
        setInstrucoesConcluidas([]); // Reinicia as instruções concluídas
      } catch (error) {
        console.error('Erro ao calcular a rota:', error);
        setIsRecalculating(false);
      }
    },
    [latitude, longitude]
  );

  // Verificar se o usuário saiu da rota
  useEffect(() => {
    if (latitude && longitude && rota.length > 0 && confirmado) {
      const isOffRoute = checkIfOffRoute(latitude, longitude, rota);
      if (isOffRoute && !isRecalculating) {
        setIsRecalculating(true);
        calcularRota(selectedDestino);
      }
    }
  }, [latitude, longitude, rota, confirmado, isRecalculating, calcularRota, selectedDestino]);

  const checkIfOffRoute = (latitude, longitude, rota) => {
    // Convert rota to GeoJSON LineString
    const line = turf.lineString(
      rota.map((coord) => [coord.longitude, coord.latitude])
    );

    // Posição do usuário como um Ponto
    const point = turf.point([longitude, latitude]);

    // Calcula a distância do usuário até a rota em metros
    const distance = turf.pointToLineDistance(point, line, { units: 'meters' });

    const threshold = 20; // Limiar em metros

    return distance > threshold;
  };

  // Atualizar instruções concluídas com base na posição do usuário
  useEffect(() => {
    if (latitude && longitude && instrucoes.length > 0) {
      const novasInstrucoesConcluidas = [];

      instrucoes.forEach((instrucao) => {
        let instrucaoLatitude, instrucaoLongitude;

        // Verifique a estrutura real das instruções
        if (
          instrucao &&
          instrucao.position &&
          Number.isFinite(instrucao.position.latitude) &&
          Number.isFinite(instrucao.position.longitude)
        ) {
          instrucaoLatitude = instrucao.position.latitude;
          instrucaoLongitude = instrucao.position.longitude;
        } else if (
          Number.isFinite(instrucao.latitude) &&
          Number.isFinite(instrucao.longitude)
        ) {
          instrucaoLatitude = instrucao.latitude;
          instrucaoLongitude = instrucao.longitude;
        } else {
          console.warn('Instrução inválida ou propriedades faltando:', instrucao);
          return; // pula para a próxima iteração
        }

        if (!instrucoesConcluidas.includes(instrucao.texto)) {
          const instrucaoPoint = turf.point([instrucaoLongitude, instrucaoLatitude]);
          const userPoint = turf.point([longitude, latitude]);
          const distance = turf.distance(instrucaoPoint, userPoint, { units: 'meters' });

          if (distance < 10) {
            novasInstrucoesConcluidas.push(instrucao.texto);
          }
        }
      });

      if (novasInstrucoesConcluidas.length > 0) {
        setInstrucoesConcluidas((prev) => [...prev, ...novasInstrucoesConcluidas]);
      }
    }
  }, [latitude, longitude, instrucoes, instrucoesConcluidas]);

  return (
    <div className="app-container" style={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* Mapa com a rota desenhada */}
      <div className="map-section" style={{ flex: 1, position: 'relative' }}>
        <MapView latitude={latitude} longitude={longitude} rota={rota} mapRef={mapRef} />

        {/* Botão para centralizar o mapa */}
        <button className="center-button" onClick={handleCenterMap}>
          📍
        </button>
      </div>

      {/* Exibe as instruções de navegação, se houver */}
      {instrucoes.length > 0 && (
        <InstrucoesNavegacao
          instrucoes={instrucoes}
          instrucoesConcluidas={instrucoesConcluidas}
        />
      )}

      {/* Painel de informações detalhadas do destino */}
      {selectedDestino && !confirmado && (
        <DestinoInfo
          destino={selectedDestino}
          tempoEstimado={tempoEstimado}
          onClose={() => setSelectedDestino(null)}
          onConfirm={() => calcularRota(selectedDestino)}
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
          <button className="trocar-destino-button" onClick={toggleDestinos}>
            Trocar destino
          </button>
        </div>
      )}

      {/* Botão de seleção de destino / Voltar */}
      {!confirmado && (
        <div className="bottom-panel">
          <button className="destino-button" onClick={toggleDestinos}>
            {showDestinos ? 'Voltar' : 'Qual seu destino?'}
          </button>
        </div>
      )}

      {/* Exibição do componente DestinosList quando showDestinos for verdadeiro */}
      {showDestinos && (
        <div className="search-container">
          <input
            type="text"
            className="search-input"
            placeholder="Digite o destino"
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
          />
          <DestinosList
            destinos={destinos.filter((destino) =>
              destino.destino_nome.toLowerCase().includes(searchQuery.toLowerCase())
            )}
            onSelectDestino={(destino) => {
              setSelectedDestino(destino);
              setShowDestinos(false); // Fechar o painel de seleção
              setConfirmado(false); // Garantir que o destino será confirmado apenas após clicar no botão
            }}
          />
        </div>
      )}
    </div>
  );
};

export default AppWithGeolocation;

