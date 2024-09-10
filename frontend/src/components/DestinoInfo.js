import React from 'react';

const DestinoInfo = ({ destino, tempoEstimado, onClose }) => {
  return (
    <div className="destino-info">
      <button className="close-button" onClick={onClose}>✕</button>
      <h2>{destino.nome}</h2>
      <p><strong>Tipo:</strong> {destino.tipo}</p> {/* Mostra o tipo de destino */}
      <p><strong>Tempo estimado:</strong> {tempoEstimado}</p> {/* Mostra o tempo estimado de caminhada */}
      <p><strong>Horário de Funcionamento:</strong> {destino.horarioFuncionamento}</p> {/* Mostra o horário de funcionamento */}
    </div>
  );
};

export default DestinoInfo;
