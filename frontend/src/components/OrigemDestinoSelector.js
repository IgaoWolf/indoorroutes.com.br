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
  showSearchContainer, // Condicional para exibir o search-container
  searchContainer,     // Conteúdo do search-container (busca)
}) => {
  return (
    <div className="origem-destino-selector">
      {/* Renderiza o campo de busca quando necessário */}
      {showSearchContainer && (
        <div className="search-section">
          {searchContainer}
        </div>
      )}

      {/* Painel principal do selector */}
      {!showSearchContainer && (
        <>
          <div className="header">
            <button className="back-button" onClick={onBack}>
              ←
            </button>
          </div>

          <div className="info-panel">
            {/* Origem */}
            <div className="info-item">
              <FaCircle className="icon origem-icon" />
              <span>
                <strong>Origem:</strong> {origem ? origem.destino_nome : 'Não selecionada'}
              </span>
              <button className="change-button" onClick={onSelectOrigem}>
                Escolher Origem
              </button>
            </div>

            {/* Destino */}
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
        </>
      )}
    </div>
  );
};

export default OrigemDestinoSelector;

