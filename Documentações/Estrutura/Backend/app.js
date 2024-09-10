import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Polyline } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import axios from 'axios';

const App = () => {
  const [position, setPosition] = useState(null);
  const [destination, setDestination] = useState('');
  const [destinations, setDestinations] = useState([]);
  const [route, setRoute] = useState([]);
  const [instructions, setInstructions] = useState([]);
  const [showSearch, setShowSearch] = useState(false);
  const [showDirections, setShowDirections] = useState(false);

  useEffect(() => {
    // Obter a localização atual do usuário
    navigator.geolocation.getCurrentPosition((pos) => {
      const { latitude, longitude } = pos.coords;
      setPosition([latitude, longitude]);
    });

    // Carregar destinos disponíveis
    fetchDestinations();
  }, []);

  const fetchDestinations = async () => {
    try {
      const response = await axios.get('/api/destinos');
      setDestinations(response.data);
    } catch (error) {
      console.error('Erro ao carregar destinos:', error);
    }
  };

  const handleSearch = async (dest) => {
    if (position) {
      const [latitude, longitude] = position;
      try {
        const response = await axios.post('/api/rota', {
          latitude,
          longitude,
          destino: dest || destination,
        });
        setRoute(response.data.rota);
        generateInstructions(response.data.rota);
        setShowSearch(false);
        setShowDirections(true);
      } catch (error) {
        console.error('Erro ao buscar a rota:', error);
      }
    }
  };

  const generateInstructions = (rota) => {
    const newInstructions = [];
    for (let i = 0; i < rota.length - 1; i++) {
      const current = rota[i];
      const next = rota[i + 1];
      const distance = current.cost;
      let instruction = distance > 0 ? `Ande ${distance.toFixed(1)} metros` : 'Destino alcançado';

      if (next) {
        if (next.latitude > current.latitude) {
          instruction += ' e vire à direita';
        } else if (next.latitude < current.latitude) {
          instruction += ' e vire à esquerda';
        }
      }

      newInstructions.push(instruction);
    }
    setInstructions(newInstructions);
  };

  return (
    <div className="relative w-full h-screen">
      <MapContainer center={position || [-24.946, -53.508]} zoom={18} className="h-screen">
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution="&copy; <a href='https://www.openstreetmap.org/copyright'>OpenStreetMap</a> contributors"
        />
        {position && <Marker position={position} />}
        {route.length > 0 && (
          <Polyline
            positions={route.map((point) => [point.latitude, point.longitude])}
            color="blue"
          />
        )}
      </MapContainer>

      {/* Barra de busca e interface de usuário */}
      {!showDirections && (
        <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white p-4 rounded-t-lg shadow-lg z-50">
          {!showSearch ? (
            <input
              type="text"
              placeholder="Qual seu destino?"
              onFocus={() => setShowSearch(true)}
              className="p-3 border border-gray-300 rounded-md w-full mb-3 focus:outline-none"
            />
          ) : (
            <div>
              <input
                type="text"
                placeholder="Seu destino"
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
                autoFocus
                className="p-3 border border-gray-300 rounded-md w-full mb-3 focus:outline-none"
              />
              <div className="mt-3">
                <h4 className="font-bold mb-2">Destinos Disponíveis</h4>
                <ul className="space-y-1">
                  {destinations.map((dest) => (
                    <li
                      key={dest.id}
                      onClick={() => handleSearch(dest.nome)}
                      className="cursor-pointer text-blue-500 hover:underline"
                    >
                      {dest.nome}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Instruções de navegação */}
      {showDirections && (
        <div className="absolute bottom-0 w-full bg-white p-4 rounded-t-lg shadow-lg z-50">
          <h4 className="font-bold">{destination}</h4>
          <ul className="mt-2 space-y-1">
            {instructions.map((instrucao, index) => (
              <li key={index} className="text-gray-700">
                {instrucao}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

export default App;
