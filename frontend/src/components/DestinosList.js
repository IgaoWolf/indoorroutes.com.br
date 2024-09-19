import React from 'react';

const DestinosList = ({ destinos, onSelectDestino }) => {
  // Agrupa os destinos por andar
  const destinosPorAndar = destinos.reduce((acc, destino) => {
    const andar = destino.andar || 'Desconhecido'; // Assume "Desconhecido" se o andar não for informado
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

