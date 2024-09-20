import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Tooltip, Polyline } from 'react-leaflet';
import L from 'leaflet';

// Ícone de boneco para a posição do usuário
const userIcon = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/512/149/149071.png', // Ícone de boneco
  iconSize: [38, 38],
  iconAnchor: [19, 38],
  popupAnchor: [0, -38],
});

// Ícone para o ponto de chegada (vermelho)
const endIcon = new L.Icon({
  iconUrl: 'https://maps.google.com/mapfiles/ms/icons/red-dot.png', // Ícone vermelho para o ponto de chegada
  iconSize: [32, 32],
  iconAnchor: [16, 32],
  popupAnchor: [0, -32],
});

// Ícone para escada
const stairIcon = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/512/2927/2927067.png', // Ícone de escada
  iconSize: [32, 32],
  iconAnchor: [16, 32],
  popupAnchor: [0, -32],
});

// Ícone para elevador
const elevatorIcon = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/512/2927/2927066.png', // Ícone de elevador
  iconSize: [32, 32],
  iconAnchor: [16, 32],
  popupAnchor: [0, -32],
});

const MapView = ({ latitude, longitude, rota }) => {
  const [userPosition, setUserPosition] = useState({ lat: latitude, lon: longitude });
  const defaultZoom = 18; // Zoom padrão
  const pontoFinal = rota.length > 0 ? rota[rota.length - 1] : null; // Último ponto da rota

  // Função para atualizar a localização do usuário em tempo real
  useEffect(() => {
    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        setUserPosition({
          lat: position.coords.latitude,
          lon: position.coords.longitude,
        });
      },
      (error) => {
        console.error('Erro ao obter localização:', error);
      },
      { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
    );

    // Limpa o watcher de geolocalização ao desmontar o componente
    return () => navigator.geolocation.clearWatch(watchId);
  }, []);

  return (
    <div className="map-container">
      {latitude && longitude ? (
        <MapContainer center={[latitude, longitude]} zoom={defaultZoom} style={{ height: '100%', width: '100%' }}>
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          />

          {/* Linha da rota */}
          {rota.length > 0 && (
            <Polyline
              positions={rota.map((ponto) => [ponto.latitude, ponto.longitude])}
              color="blue"
            />
          )}

          {/* Marker para o ponto final com ícone vermelho e popup */}
          {pontoFinal && (
            <Marker position={[pontoFinal.latitude, pontoFinal.longitude]} icon={endIcon}>
              <Tooltip direction="top" offset={[0, -20]} permanent>
                <strong>Ponto de Chegada</strong>
              </Tooltip>
            </Marker>
          )}

          {/* Marker para a localização do usuário em tempo real */}
          {userPosition.lat && userPosition.lon && (
            <Marker position={[userPosition.lat, userPosition.lon]} icon={userIcon}>
              <Tooltip direction="top" offset={[0, -38]} permanent>
                Você está aqui!
              </Tooltip>
            </Marker>
          )}

          {/* Exibir ícones de escada ou elevador em pontos da rota */}
          {rota.map((ponto, index) => {
            const prevPonto = index > 0 ? rota[index - 1] : null;
            const proximoPonto = index < rota.length - 1 ? rota[index + 1] : null;

            // Verifica se o ponto atual é uma escada ou elevador e se houve mudança de andar
            if (prevPonto && proximoPonto && ponto.andar_id !== prevPonto.andar_id) {
              // Se o tipo do ponto anterior for escadaria, adiciona ícone de escada
              if (prevPonto.tipo === 'Escadaria') {
                return (
                  <Marker key={index} position={[ponto.latitude, ponto.longitude]} icon={stairIcon}>
                    <Tooltip direction="top" offset={[0, -32]} permanent>
                      <strong>Suba/Desça a Escada</strong>
                    </Tooltip>
                  </Marker>
                );
              }

              // Se o tipo do ponto anterior for elevador, adiciona ícone de elevador
              if (prevPonto.tipo === 'Elevador') {
                return (
                  <Marker key={index} position={[ponto.latitude, ponto.longitude]} icon={elevatorIcon}>
                    <Tooltip direction="top" offset={[0, -32]} permanent>
                      <strong>Pegue o Elevador</strong>
                    </Tooltip>
                  </Marker>
                );
              }
            }

            return null; // Nenhum ícone se não houver mudança de andar
          })}
        </MapContainer>
      ) : (
        <p>Carregando mapa...</p>
      )}
    </div>
  );
};

export default MapView;
