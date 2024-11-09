import React, { useState } from 'react';
import { FaArrowLeft } from 'react-icons/fa';
import '../styles/InstrucoesCompactas.css';

const InstrucoesCompactas = ({ instrucoes, onBack }) => {
  const [isExpanded, setIsExpanded] = useState(false);

  // Alterna a expansão das instruções
  const toggleExpand = () => {
    setIsExpanded(!isExpanded);
  };

  return (
    <div className="instrucoes-compactas">
      <div className="header">
        <button className="back-arrow" onClick={onBack}>
          <FaArrowLeft />
        </button>
        <p className="trajeto-titulo">Ver trajeto</p>
      </div>
      <div className="linha-separadora"></div>

      {/* Primeira instrução */}
      <div className="instrucao-texto-principal">
        <span>{instrucoes[0]}</span>
        <span className="seta-expandir" onClick={toggleExpand}>
          {isExpanded ? "▲" : "▼"}
        </span>
      </div>

      {/* Instruções extras */}
      {isExpanded && (
        <div className="instrucao-extra">
          {instrucoes.slice(1).map((instrucao, index) => (
            <p key={index} className="instrucao-item">
              {instrucao}
            </p>
          ))}
        </div>
      )}
    </div>
  );
};

export default InstrucoesCompactas;

