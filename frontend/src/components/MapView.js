import React, { useEffect, useRef, useState } from 'react';
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

// Coordenadas padrão quando a geolocalização não é permitida
const defaultCenter = { lat: -24.94667548, lon: -53.50780993 };

const MapView = ({ latitude, longitude, rota, mapRef }) => {
  const [userPosition, setUserPosition] = useState(null);
  const defaultZoom = 18;

  // Atualiza a posição do usuário ou usa o centro padrão
  useEffect(() => {
    if (latitude != null && longitude != null) {
      setUserPosition({ lat: latitude, lon: longitude });
    } else {
      setUserPosition(defaultCenter); // Usa as coordenadas padrão
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
          ref={mapRef}
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

          {/* Marker para a localização do usuário ou centro padrão */}
          {userPosition && (
            <Marker position={[userPosition.lat, userPosition.lon]} icon={userIcon}>
              <Tooltip direction="top" offset={[0, -38]} permanent>
                {latitude && longitude ? 'Você está aqui!' : 'Localização padrão'}
              </Tooltip>
            </Marker>
          )}

          {/* Marker para o ponto final */}
          {rota.length > 0 && (
            <Marker
              position={[rota[rota.length - 1].latitude, rota[rota.length - 1].longitude]}
              icon={endIcon}
            >
              <Tooltip direction="top" offset={[0, -20]} permanent>
                <strong>Ponto de Chegada</strong>
              </Tooltip>
            </Marker>
          )}
        </MapContainer>
      )}
    </div>
  );
};

export default MapView;

