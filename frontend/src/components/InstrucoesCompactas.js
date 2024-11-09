import React from 'react';
import { FaArrowLeft } from 'react-icons/fa';
import '../styles/InstrucoesCompactas.css';

const InstrucoesCompactas = ({ instrucoes, onVoltar }) => {
  return (
    <div className="instrucoes-compactas">
      <div className="header">
        <button className="back-arrow" onClick={onVoltar}>
          <FaArrowLeft />
        </button>
        <h2 className="trajeto-titulo">Ver trajeto</h2>
      </div>
      <div className="linha-separadora" />
      <p className="instrucao-texto">
        {instrucoes.length > 0 ? instrucoes[0] : 'Instruções de navegação'}
      </p>
    </div>
  );
};

export default InstrucoesCompactas;

