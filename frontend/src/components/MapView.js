import React from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline } from 'react-leaflet';

const MapView = ({ latitude, longitude, rota }) => {
  const defaultZoom = 18; // Aumentando o zoom padrão

  return (
    <div className="map-container">
      {latitude && longitude ? (
        <MapContainer center={[latitude, longitude]} zoom={defaultZoom} style={{ height: '100%', width: '100%' }}>
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          />
          <Marker position={[latitude, longitude]}>
            <Popup>Você está aqui</Popup>
          </Marker>

          {rota.length > 0 && (
            <Polyline
              positions={rota.map((ponto) => [ponto.latitude, ponto.longitude])}
              color="blue"
            />
          )}

          {rota.map((ponto, index) => (
            <Marker key={index} position={[ponto.latitude, ponto.longitude]}>
              <Popup>
                Ponto {index + 1}: Latitude {ponto.latitude}, Longitude {ponto.longitude}
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      ) : (
        <p>Carregando mapa...</p>
      )}
    </div>
  );
};

export default MapView;

