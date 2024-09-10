import React from 'react';

const DestinosList = ({ destinos, onSelectDestino }) => {
  return (
    <div className="destinos-list-container">
      <ul className="destinos-list">
        {destinos.map((destino) => (
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
  );
};

export default DestinosList;

