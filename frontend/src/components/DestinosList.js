import React, { useState } from 'react';
import { FaArrowLeft } from 'react-icons/fa';
import '../styles/DestinosList.css'; // Importa o CSS personalizado

const DestinosList = ({ destinos, searchQuery, onSelectDestino }) => {
  const [blocoSelecionado, setBlocoSelecionado] = useState(null);
  const [andarSelecionado, setAndarSelecionado] = useState(null);

  const destinosPorBlocoEAndar = destinos.reduce((acc, destino) => {
    const bloco = destino.bloco_nome || 'Bloco Desconhecido';
    const andar = destino.andar_nome || 'Andar Desconhecido';

    if (!acc[bloco]) {
      acc[bloco] = {};
    }
    if (!acc[bloco][andar]) {
      acc[bloco][andar] = [];
    }

    acc[bloco][andar].push(destino);
    return acc;
  }, {});

  const blocosDisponiveis = ['Bloco 1', 'Bloco 4'];

  if (searchQuery) {
    return (
      <div className="destinos-list-container">
        {destinos
          .filter((destino) => destino.destino_nome.toLowerCase().includes(searchQuery.toLowerCase()))
          .map((destino) => (
            <button
              key={destino.destino_id}
              onClick={() => onSelectDestino(destino)}
              className="destino-button"
            >
              {destino.destino_nome}
            </button>
          ))}
      </div>
    );
  }

  return (
    <div className="destinos-list-container">
      {!blocoSelecionado ? (
        <div className="blocos-disponiveis">
          {blocosDisponiveis.map((bloco) => (
            <button
              key={bloco}
              className="bloco-button"
              onClick={() => setBlocoSelecionado(bloco)}
            >
              {bloco}
            </button>
          ))}
        </div>
      ) : !andarSelecionado ? (
        <div className="andares-disponiveis">
          <h2>{blocoSelecionado}</h2>
          <button onClick={() => setBlocoSelecionado(null)} className="voltar-seta">
            <FaArrowLeft /> {/* Ícone de seta para voltar */}
          </button>
          {Object.keys(destinosPorBlocoEAndar[blocoSelecionado] || {}).map((andar) => (
            <button
              key={andar}
              className="andar-button"
              onClick={() => setAndarSelecionado(andar)}
            >
              {andar}
            </button>
          ))}
        </div>
      ) : (
        <div className="destino-bloco-group">
          <h2>{blocoSelecionado} - {andarSelecionado}</h2>
          <button onClick={() => setAndarSelecionado(null)} className="voltar-seta">
            <FaArrowLeft /> {/* Ícone de seta para voltar */}
          </button>
          <ul className="destinos-list">
            {(destinosPorBlocoEAndar[blocoSelecionado][andarSelecionado] || []).map((destino) => (
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
      )}
    </div>
  );
};

export default DestinosList;

