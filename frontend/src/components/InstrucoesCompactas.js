import React from 'react';
import { FaArrowUp } from 'react-icons/fa';
import '../styles/InstrucoesCompactas.css';

const InstrucoesCompactas = ({ instrucao }) => {
  return (
    <div className="instruction-panel">
      <FaArrowUp className="instruction-arrow" />
      <div className="instruction-text">
        {instrucao ? instrucao : 'Nenhuma instrução disponível'}
      </div>
    </div>
  );
};

export default InstrucoesCompactas;

