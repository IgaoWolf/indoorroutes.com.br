import React, { useState } from 'react';
import { FaArrowDown, FaArrowUp } from 'react-icons/fa';
import '../styles/InstrucoesCompactas.css';

const InstrucoesCompactas = ({ instrucoes }) => {
  const [isExpanded, setIsExpanded] = useState(false);

  const toggleExpand = () => {
    setIsExpanded(!isExpanded);
  };

  return (
    <div className="instrucoes-compactas">
      <div className="instrucao-principal">
        <span>{instrucoes[0]}</span>
        <button className="toggle-expand" onClick={toggleExpand}>
          {isExpanded ? <FaArrowUp /> : <FaArrowDown />}
        </button>
      </div>
      
      {isExpanded && (
        <div className="instrucao-extra">
          {instrucoes.slice(1).map((instrucao, index) => (
            <div key={index} className="instrucao-item">
              {instrucao}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default InstrucoesCompactas;

