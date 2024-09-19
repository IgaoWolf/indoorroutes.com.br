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

    // Verifica se o formato do horário é válido
    const horarioArray = destino.horariofuncionamento.split(' - ');
    if (horarioArray.length !== 2) {
      setStatus('Horário de funcionamento inválido');
      return;
    }

    // Extrai os horários de abertura e fechamento
    const [horarioAbertura, horarioFechamento] = horarioArray;

    const now = new Date();
    const horarioAberturaData = criarDataComHorario(horarioAbertura);
    const horarioFechamentoData = criarDataComHorario(horarioFechamento);

    // Caso o horário de fechamento seja no dia seguinte
    if (horarioFechamentoData < horarioAberturaData) {
      horarioFechamentoData.setDate(horarioFechamentoData.getDate() + 1);
    }

    if (now >= horarioAberturaData && now <= horarioFechamentoData) {
      setStatus('Aberto');
    } else {
      setStatus('Fechado');
    }

    // Atualiza o estado do horário de funcionamento para exibição
    sethorariofuncionamento(`${horarioAbertura} - ${horarioFechamento}`);
  }, [destino]);

  useEffect(() => {
    if (destino && destino.horariofuncionamento) {
      verificarhorariofuncionamento();
    }
  }, [destino, verificarhorariofuncionamento]);

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
