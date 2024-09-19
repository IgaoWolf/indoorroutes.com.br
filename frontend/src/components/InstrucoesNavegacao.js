import React from 'react';
import '../App.css'; // Certifique-se de que o CSS correto está sendo importado

const InstrucoesNavegacao = ({ instrucoes }) => {
  return (
    <div className="instrucoes-navegacao">
      <h3>Instruções de Navegação</h3>
      <ul>
        {instrucoes.map((instrucao, index) => (
          <li key={index}>{instrucao}</li>
        ))}
      </ul>
    </div>
  );
};

export default InstrucoesNavegacao;

