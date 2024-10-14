import React, { useState, useEffect } from 'react';
import '../styles/App.css';

const InstrucoesNavegacao = ({ instrucoes, instrucoesConcluidas }) => {
  const [showAll, setShowAll] = useState(false);
  const [remainingInstructions, setRemainingInstructions] = useState([]);

  useEffect(() => {
    // Filtrar as instruções para remover as já concluídas
    const instrucoesRestantes = instrucoes.filter(
      (instrucao) => !instrucoesConcluidas.includes(instrucao)
    );
    setRemainingInstructions(instrucoesRestantes);
  }, [instrucoes, instrucoesConcluidas]);

  const handleToggleInstructions = () => {
    setShowAll(!showAll);
  };

  if (!remainingInstructions || remainingInstructions.length === 0) {
    return null; // Não renderiza nada se não houver instruções restantes
  }

  return (
    <div className="instrucoes-navegacao">
      <h3>Instruções de Navegação</h3>
      <div onClick={handleToggleInstructions} className="instructions-header" style={{ cursor: 'pointer', fontWeight: 'bold', marginBottom: '5px' }}>
        {showAll ? 'Ocultar Instruções' : 'Mostrar Instruções'}
      </div>
      {showAll ? (
        <ul>
          {remainingInstructions.map((instrucao, index) => (
            <li key={index}>{instrucao}</li>
          ))}
        </ul>
      ) : (
        <div className="next-instruction">
          Próxima instrução: {remainingInstructions[0]}
        </div>
      )}
    </div>
  );
};

export default InstrucoesNavegacao;
