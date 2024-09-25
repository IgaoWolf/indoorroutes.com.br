import React from 'react';

const DestinosList = ({ destinos, onSelectDestino }) => {
  // Agrupa os destinos por andar
  const destinosPorAndar = destinos.reduce((acc, destino) => {
    const andar = destino.andar_nome || 'Desconhecido';
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
          <h3>{andar}</h3>
          <ul className="destinos-list">
            {destinosPorAndar[andar].map((destino) => (
              <li
                key={destino.destino_id}
                className="destino-item"
                onClick={() => onSelectDestino(destino)}
              >
                {destino.destino_nome}
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  );
};

export default DestinosList;
