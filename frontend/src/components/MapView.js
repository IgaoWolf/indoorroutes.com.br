import React, { useEffect, useRef, useState } from 'react';
import { MapContainer, TileLayer, Marker, Tooltip, Polyline, useMap } from 'react-leaflet';
import L from 'leaflet';
import '../styles/mapview.css';

// Ícones para o mapa
const userIcon = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/128/3237/3237472.png',
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
  const initialFitDone = useRef(false); // Flag para controlar ajuste inicial

  // Atualiza a posição do usuário ou usa o centro padrão
  useEffect(() => {
    if (latitude != null && longitude != null) {
      setUserPosition({ lat: latitude, lon: longitude });
    } else {
      setUserPosition(defaultCenter); // Usa as coordenadas padrão
    }
  }, [latitude, longitude]);

  // Componente para ajustar o mapa para caber a rota e a localização do usuário apenas no início
  const AjustarMapaParaRota = ({ rota, userPosition }) => {
    const map = useMap();

    useEffect(() => {
      if (!initialFitDone.current) { // Ajusta o mapa apenas uma vez
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

        initialFitDone.current = true; // Marca que o ajuste inicial foi feito
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
          zoomControl={false} // Desativa o controle de zoom padrão
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

          {/* Ajusta o mapa para caber a rota e a posição do usuário uma única vez */}
          <AjustarMapaParaRota rota={rota} userPosition={userPosition} />

          {/* Exibir o marcador apenas se a localização não for padrão */}
          {latitude != null && longitude != null && (
            <Marker position={[userPosition.lat, userPosition.lon]} icon={userIcon}>
              <Tooltip direction="top" offset={[0, -38]} permanent>
                Você está aqui!
              </Tooltip>
            </Marker>
          )}

          {/* Exibir o marcador do ponto padrão com texto "FAG" */}
          {latitude == null && longitude == null && (
            <Tooltip
              direction="top"
              permanent
              offset={[0, -20]}
              position={[defaultCenter.lat, defaultCenter.lon]}
            >
              FAG
            </Tooltip>
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

