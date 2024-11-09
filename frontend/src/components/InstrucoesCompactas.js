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
      <div className="instrucao-texto" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <span>{instrucoes[0]}</span>
        <button className="toggle-expand" onClick={toggleExpand}>
          {isExpanded ? "▲" : "▼"}
        </button>
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

