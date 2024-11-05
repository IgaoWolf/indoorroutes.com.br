import React, { useState } from 'react';

const DestinosList = ({ destinos, onSelectDestino }) => {
  // Estado para controlar o bloco e o andar selecionados
  const [blocoSelecionado, setBlocoSelecionado] = useState(null);
  const [andarSelecionado, setAndarSelecionado] = useState(null);

  // Agrupa os destinos por bloco e andar
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

  // Lista dos blocos disponíveis (exibirá os botões "Bloco 1" e "Bloco 4" inicialmente)
  const blocosDisponiveis = ['Bloco 1', 'Bloco 4'];

  return (
    <div className="destinos-list-container">
      {/* Etapa 1: Seleção de bloco */}
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
        // Etapa 2: Seleção de andar para o bloco selecionado
        <div className="andares-disponiveis">
          <h2>{blocoSelecionado}</h2>
          {Object.keys(destinosPorBlocoEAndar[blocoSelecionado] || {}).map((andar) => (
            <button
              key={andar}
              className="andar-button"
              onClick={() => setAndarSelecionado(andar)}
            >
              {andar}
            </button>
          ))}
          {/* Botão para voltar à seleção de blocos */}
          <button onClick={() => setBlocoSelecionado(null)} className="voltar-button">
            Voltar
          </button>
        </div>
      ) : (
        // Etapa 3: Exibição dos destinos para o bloco e andar selecionados
        <div className="destino-bloco-group">
          <h2>{blocoSelecionado} - {andarSelecionado}</h2>
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
          {/* Botão para voltar à seleção de andares */}
          <button onClick={() => setAndarSelecionado(null)} className="voltar-button">
            Voltar
          </button>
        </div>
      )}
    </div>
  );
};

export default DestinosList;
