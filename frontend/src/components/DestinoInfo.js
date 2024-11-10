import '../styles/DestinoInfo.css';

import React, { useEffect, useState, useCallback } from 'react';

const DestinoInfo = ({ destino, onClose, onConfirm, tempoEstimado }) => {
  const [status, setStatus] = useState(''); // Estado para o status "Aberto" ou "Fechado"
  const [horariofuncionamento, setHorarioFuncionamento] = useState(''); // Estado para exibir o horário de funcionamento

  // Função para verificar o horário de funcionamento
  const verificarHorarioFuncionamento = useCallback(() => {
    if (!destino || !destino.horariofuncionamento) {
      setStatus('Horário de funcionamento não disponível');
      return;
    }

    const horarioArray = destino.horariofuncionamento.split(' - ');
    if (horarioArray.length !== 2) {
      setStatus('Horário de funcionamento inválido');
      return;
    }

    const [horarioAbertura, horarioFechamento] = horarioArray;
    const now = new Date();
    const horarioAberturaData = criarDataComHorario(horarioAbertura);
    const horarioFechamentoData = criarDataComHorario(horarioFechamento);

    if (horarioFechamentoData < horarioAberturaData) {
      horarioFechamentoData.setDate(horarioFechamentoData.getDate() + 1);
    }

    if (now >= horarioAberturaData && now <= horarioFechamentoData) {
      setStatus('Aberto');
    } else {
      setStatus('Fechado');
    }

    setHorarioFuncionamento(`${horarioAbertura} - ${horarioFechamento}`);
  }, [destino]);

  useEffect(() => {
    if (destino && destino.horariofuncionamento) {
      verificarHorarioFuncionamento();
    }
  }, [destino, verificarHorarioFuncionamento]);

  const criarDataComHorario = (horario) => {
    const [horas, minutos] = horario.split(':');
    const dataAtual = new Date();
    dataAtual.setHours(horas, minutos, 0, 0);
    return dataAtual;
  };

  return (
    <div className="destino-info">
      <div className="header">
        <h2>{destino.destino_nome}</h2>
        {/* Removemos o <p>{destino.tipo}</p> para não exibir "sala" ou o tipo do destino */}
        <button className="close-button" onClick={onClose}>
          ✕
        </button>
      </div>

      {tempoEstimado && (
        <p>
          <strong>Tempo estimado: </strong>
          {tempoEstimado}
        </p>
      )}

      <button className="confirm-button" onClick={onConfirm}>
        Iniciar Rota
      </button>

      {destino.horariofuncionamento ? (
        <div className="horario-info">
          <p>
            <strong>Horário de Funcionamento:</strong>
          </p>
          <p>{horariofuncionamento}</p>
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

