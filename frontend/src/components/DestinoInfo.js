import React, { useEffect, useState, useCallback } from 'react';

const DestinoInfo = ({ destino, onClose, onConfirm }) => {
  const [status, setStatus] = useState(''); // Estado para o status "Aberto" ou "Fechado"
  const [horariofuncionamento, sethorariofuncionamento] = useState(''); // Estado para exibir o horário de funcionamento

  // Função para verificar o horário de funcionamento
  const verificarhorariofuncionamento = useCallback(() => {
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

    sethorariofuncionamento(`${horarioAbertura} - ${horarioFechamento}`);
  }, [destino]);

  useEffect(() => {
    if (destino && destino.horariofuncionamento) {
      verificarhorariofuncionamento();
    }
  }, [destino, verificarhorariofuncionamento]);

  const criarDataComHorario = (horario) => {
    const [horas, minutos] = horario.split(':');
    const dataAtual = new Date();
    dataAtual.setHours(horas, minutos, 0, 0);
    return dataAtual;
  };

  return (
    <div className="destino-info">
      <div className="header">
        <h2>{destino.destino_nome}</h2> {/* Ajuste para refletir o nome correto do destino */}
        <p>{destino.tipo}</p> {/* Ajuste para refletir o tipo do destino */}
        <button className="close-button" onClick={onClose}>✕</button>
      </div>

      <button className="confirm-button" onClick={onConfirm}>
        Iniciar Rota
      </button>

      {destino.horariofuncionamento ? (
        <div className="horario-info">
          <p><strong>Horário de Funcionamento:</strong></p>
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

