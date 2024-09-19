import React, { useEffect, useState, useCallback } from 'react';

const DestinoInfo = ({ destino, onClose, onConfirm }) => {
  const [status, setStatus] = useState(''); // Estado para o status "Aberto" ou "Fechado"

  // Função para verificar o horário de funcionamento (usando useCallback para evitar a recriação da função)
  const verificarHorarioFuncionamento = useCallback(() => {
    if (!destino.horarioFuncionamento) {
      setStatus('Horário de funcionamento não disponível');
      return;
    }

    const now = new Date();
    const horarioAbertura = criarDataComHorario(destino.horarioFuncionamento.abertura);
    const horarioFechamento = criarDataComHorario(destino.horarioFuncionamento.fechamento);

    if (now >= horarioAbertura && now <= horarioFechamento) {
      setStatus('Aberto');
    } else {
      setStatus('Fechado');
    }
  }, [destino]);

  useEffect(() => {
    if (destino && destino.horarioFuncionamento) {
      verificarHorarioFuncionamento();
    }
  }, [destino, verificarHorarioFuncionamento]); // Adicionada a função como dependência

  // Função auxiliar para criar uma data com a hora correta
  const criarDataComHorario = (horario) => {
    const [horas, minutos] = horario.split(':');
    const dataAtual = new Date();
    dataAtual.setHours(horas, minutos, 0, 0); // Define horas e minutos, ignorando segundos e milissegundos
    return dataAtual;
  };

  return (
    <div className="destino-info">
      <div className="header">
        <h2>{destino.nome}</h2>
        <p>{destino.tipo}</p>
        <button className="close-button" onClick={onClose}>✕</button>
      </div>

      <button className="confirm-button" onClick={onConfirm}>
        {destino.tempoEstimado} {/* Exibe o tempo estimado de chegada */}
      </button>

      {destino.horarioFuncionamento ? (
        <div className="horario-info">
          <p><strong>Horário de Funcionamento:</strong></p>
          <p>{destino.horarioFuncionamento.abertura} - {destino.horarioFuncionamento.fechamento}</p>
          <p className={status === 'Aberto' ? 'status-aberto' : 'status-fechado'}>
            {status === 'Aberto' ? 'Aberto agora' : 'Fechado agora'}
          </p>
        </div>
      ) : (
        <div className="horario-info">
          <p>Horário de funcionamento não disponível</p>
        </div>
      )}
    </div>
  );
};

export default DestinoInfo;

