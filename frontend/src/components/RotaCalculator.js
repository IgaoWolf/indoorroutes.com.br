import React, { useState } from 'react';
import axios from 'axios';
import { MapContainer, TileLayer, Marker, Polyline, Popup } from 'react-leaflet';

const RotaCalculator = ({ destinos }) => {
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [selectedDestino, setSelectedDestino] = useState('');
  const [rota, setRota] = useState([]);
  const [loading, setLoading] = useState(false);

  const calcularRota = async () => {
    if (!latitude || !longitude || !selectedDestino) {
      alert('Por favor, insira a latitude, longitude e selecione um destino.');
      return;
    }

    setLoading(true);
    try {
      const response = await axios.post('/api/rota', {
        latitude,
        longitude,
        destino: selectedDestino,
      });
      setRota(response.data.rota);
    } catch (error) {
      console.error('Erro ao calcular a rota:', error);
    } finally {
      setLoading(false);
    }
  };

  // Verifica se há latitude e longitude válidas para centralizar o mapa
  const centralizarMapa = {
    lat: latitude ? parseFloat(latitude) : -25.4284, // Use uma latitude padrão se não for fornecida
    lng: longitude ? parseFloat(longitude) : -49.2733, // Use uma longitude padrão se não for fornecida
  };

  return (
    <div>
      <h2>Calcular Rota</h2>
      <div>
        <label>
          Latitude:
          <input
            type="text"
            value={latitude}
            onChange={(e) => setLatitude(e.target.value)}
            placeholder="Ex: -25.4284"
          />
        </label>
        <label>
          Longitude:
          <input
            type="text"
            value={longitude}
            onChange={(e) => setLongitude(e.target.value)}
            placeholder="Ex: -49.2733"
          />
        </label>
        <label>
          Destino:
          <select value={selectedDestino} onChange={(e) => setSelectedDestino(e.target.value)}>
            <option value="">Selecione um destino</option>
            {destinos.map((destino) => (
              <option key={destino.id} value={destino.nome}>
                {destino.nome}
              </option>
            ))}
          </select>
        </label>
        <button onClick={calcularRota} disabled={loading}>
          {loading ? 'Carregando...' : 'Calcular Rota'}
        </button>
      </div>

      {/* Sempre renderiza o mapa, mesmo sem rota */}
      <div style={{ marginTop: '20px' }}>
        <h3>Mapa</h3>
        <MapContainer
          center={centralizarMapa}
          zoom={16}
          style={{ height: '400px', width: '100%' }}
        >
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          />

          {/* Marca a origem */}
          {latitude && longitude && (
            <Marker position={[parseFloat(latitude), parseFloat(longitude)]}>
              <Popup>Origem</Popup>
            </Marker>
          )}

          {/* Exibe a rota como uma linha poligonal, se disponível */}
          {rota.length > 0 && (
            <Polyline
              positions={rota.map((ponto) => [ponto.latitude, ponto.longitude])}
              color="blue"
            />
          )}

          {/* Marca todos os pontos da rota, se disponíveis */}
          {rota.map((ponto, index) => (
            <Marker key={index} position={[ponto.latitude, ponto.longitude]}>
              <Popup>
                Ponto {index + 1}: Latitude {ponto.latitude}, Longitude {ponto.longitude}
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>
    </div>
  );
};

export default RotaCalculator;

