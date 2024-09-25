import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Tooltip, Polyline, useMap } from 'react-leaflet';
import L from 'leaflet';

// Ícones para o mapa

const userIcon = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
  iconSize: [38, 38],
  iconAnchor: [19, 38],
  popupAnchor: [0, -38],
});

const endIcon = new L.Icon({
  iconUrl: 'https://maps.google.com/mapfiles/ms/icons/red-dot.png',
  iconSize: [32, 32],
  iconAnchor: [16, 32],
  popupAnchor: [0, -32],
});

const stairIcon = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/512/2927/2927067.png',
  iconSize: [32, 32],
  iconAnchor: [16, 32],
  popupAnchor: [0, -32],
});

const elevatorIcon = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/512/2927/2927066.png',
  iconSize: [32, 32],
  iconAnchor: [16, 32],
  popupAnchor: [0, -32],
});

// Coordenadas do waypoint_id 233 (Ponto 2 da Granvia)
const defaultCenter = { lat: -24.982925, lon: -53.442845 };

const MapView = ({ latitude, longitude, rota }) => {
  const [userPosition, setUserPosition] = useState(null);
  const defaultZoom = 18; // Nível de zoom padrão
  const pontoFinal = rota.length > 0 ? rota[rota.length - 1] : null; // Último ponto da rota

  // Atualiza a posição do usuário quando as props latitude e longitude mudam
  useEffect(() => {
    if (latitude != null && longitude != null) {
      setUserPosition({ lat: latitude, lon: longitude });
    } else {
      setUserPosition({ lat: defaultCenter.lat, lon: defaultCenter.lon });
    }
  }, [latitude, longitude]);

  // Componente para ajustar o mapa para caber a rota e a localização do usuário
  const AjustarMapaParaRota = ({ rota, userPosition }) => {
    const map = useMap();

    useEffect(() => {
      const pontos = [];

      if (rota.length > 0) {
        const rotaPontos = rota.map((ponto) => [ponto.latitude, ponto.longitude]);
        pontos.push(...rotaPontos);
      }

      if (userPosition && userPosition.lat && userPosition.lon) {
        pontos.push([userPosition.lat, userPosition.lon]);
      }

      if (pontos.length > 0) {
        map.fitBounds(pontos, { padding: [50, 50] });
      }
    }, [rota, userPosition, map]);

    return null;
  };

  return (
    <div className="map-container">
      {userPosition && (
        <MapContainer
          center={[userPosition.lat, userPosition.lon]}
          zoom={defaultZoom}
          style={{ height: '100%', width: '100%' }}
        >
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution="&copy; OpenStreetMap contributors"
          />

          {/* Linha da rota */}
          {rota.length > 0 && (
            <Polyline
              positions={rota.map((ponto) => [ponto.latitude, ponto.longitude])}
              color="blue"
            />
          )}

          {/* Ajusta o mapa para caber a rota e a posição do usuário */}
          <AjustarMapaParaRota rota={rota} userPosition={userPosition} />

          {/* Marker para o ponto final */}
          {pontoFinal && (
            <Marker position={[pontoFinal.latitude, pontoFinal.longitude]} icon={endIcon}>
              <Tooltip direction="top" offset={[0, -20]} permanent>
                <strong>Ponto de Chegada</strong>
              </Tooltip>
            </Marker>
          )}

          {/* Marker para a localização do usuário (se disponível) */}
          {latitude != null && longitude != null && (
            <Marker position={[userPosition.lat, userPosition.lon]} icon={userIcon}>
              <Tooltip direction="top" offset={[0, -38]} permanent>
                Você está aqui!
              </Tooltip>
            </Marker>
          )}

          {/* Exibir ícones de escada ou elevador em pontos da rota */}
          {rota.map((ponto, index) => {
            const prevPonto = index > 0 ? rota[index - 1] : null;

            if (prevPonto && ponto.andar_id !== prevPonto.andar_id) {
              if (prevPonto.tipo === 'Escadaria') {
                return (
                  <Marker key={index} position={[ponto.latitude, ponto.longitude]} icon={stairIcon}>
                    <Tooltip direction="top" offset={[0, -32]} permanent>
                      <strong>Suba/Desça a Escada</strong>
                    </Tooltip>
                  </Marker>
                );
              }

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

            return null;
          })}
        </MapContainer>
      )}
    </div>
  );
};

export default MapView;
