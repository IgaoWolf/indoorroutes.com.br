import React from 'react';
import { FaMapMarkerAlt, FaCircle } from 'react-icons/fa';
import '../styles/OrigemDestinoSelector.css';

const OrigemDestinoSelector = ({
  origem,
  destino,
  onSelectOrigem,
  onSelectDestino,
  onGenerateRoute,
  onBack,
  isGenerateRouteDisabled,
  showSearchContainer, // Novo prop para condicionalmente renderizar
  searchContainer,     // Novo prop para injetar o search-container
}) => {
  return (
    <>
      {/* Renderiza o search-container se estiver ativo */}
      {showSearchContainer && searchContainer}

      {/* OrigemDestinoSelector */}
      <div className="origem-destino-selector">
        {/* Botão de voltar */}
        <div className="header">
          <button className="back-button" onClick={onBack}>
            ←
          </button>
        </div>

        {/* Informações de origem e destino */}
        <div className="info-panel">
          <div className="info-item">
            <FaCircle className="icon origem-icon" />
            <span>
              <strong>Origem:</strong> {origem ? origem.destino_nome : 'Não selecionada'}
            </span>
            <button className="change-button" onClick={onSelectOrigem}>
              Escolher Origem
            </button>
          </div>
          <div className="info-item">
            <FaMapMarkerAlt className="icon destino-icon" />
            <span>
              <strong>Destino:</strong> {destino ? destino.destino_nome : 'Não selecionado'}
            </span>
            <button className="change-button" onClick={onSelectDestino}>
              Escolher Destino
            </button>
          </div>
        </div>

        {/* Botão para gerar rota */}
        <button
          className="generate-route-button"
          onClick={onGenerateRoute}
          disabled={isGenerateRouteDisabled}
        >
          Gerar Rota
        </button>
      </div>
    </>
  );
};

export default OrigemDestinoSelector;

