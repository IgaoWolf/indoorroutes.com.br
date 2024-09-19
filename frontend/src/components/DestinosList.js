import React from 'react';

const DestinosList = ({ destinos, waypointAndares, onSelectDestino }) => {
  // Agrupa os destinos por andar com base no mapeamento de waypointAndares
  const destinosPorAndar = destinos.reduce((acc, destino) => {
    const andar = waypointAndares[destino.waypoint_id] || 'Desconhecido'; // Usa o mapeamento de waypointAndares
    if (!acc[andar]) {
      acc[andar] = [];
    }
    acc[andar].push(destino);
    return acc;
  }, {});

  return (
    <div className="destinos-list-container">
      {Object.keys(destinosPorAndar).map((andar) => (
        <div key={andar} className="destino-andar-group">
          {/* Título para o andar */}
          <h3>{andar}</h3>
          <ul className="destinos-list">
            {destinosPorAndar[andar].map((destino) => (
              <li
                key={destino.id}
                className="destino-item"
                onClick={() => onSelectDestino(destino)}
              >
                {destino.nome}
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  );
};

export default DestinosList;

