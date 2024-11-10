import React, { useState } from 'react';
import { FaArrowLeft } from 'react-icons/fa';
import '../styles/InstrucoesCompactas.css';

const InstrucoesCompactas = ({ instrucoes, onBack }) => {
  const [isExpanded, setIsExpanded] = useState(false);

  const handleBackClick = () => {
    if (isExpanded) {
      setIsExpanded(false); // Fecha as instruções antes de voltar
    } else {
      onBack(); // Executa a navegação para a tela inicial
    }
  };

  return (
    <div className="instrucoes-compactas">
      <div className="header">
        <button className="back-arrow" onClick={handleBackClick}>
          <FaArrowLeft />
        </button>
        <p className="trajeto-titulo">Ver trajeto</p>
      </div>
      <div className="linha-separadora"></div>
      <div className="instrucao-texto-principal">
        <span>{instrucoes[0]}</span>
        <span className="seta-expandir" onClick={() => setIsExpanded(!isExpanded)}>
          {isExpanded ? "▲" : "▼"}
        </span>
      </div>
      {isExpanded && (
        <div className="instrucao-extra">
          {instrucoes.slice(1).map((instrucao, index) => (
            <p key={index} className="instrucao-item">{instrucao}</p>
          ))}
        </div>
      )}
    </div>
  );
};

export default InstrucoesCompactas;

