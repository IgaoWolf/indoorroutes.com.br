import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import AppWithGeolocation from './components/AppWithGeolocation';
import AppWithoutGeolocation from './components/AppWithoutGeolocation';
import Admin from './components/admin/Admin';
import './styles/App.css';

const App = () => {
  return (
    <Router>
      <Routes>
        {/* Rota para a interface administrativa */}
        <Route path="/admin" element={<Admin />} />

        {/* Rota para a aplicação principal */}
        <Route path="/" element={<Index />} />
      </Routes>
    </Router>
  );
};

const Index = () => {
  const [useGeolocation, setUseGeolocation] = React.useState(null);
  const [useGeolocationOpted, setUseGeolocationOpted] = React.useState(false);

  // Função para ativar a localização
  const handleAtivarLocalizacao = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUseGeolocation(true);
          setUseGeolocationOpted(true);
        },
        (error) => {
          console.error('Erro ao obter geolocalização:', error);
          setUseGeolocation(false);
          setUseGeolocationOpted(true);
        }
      );
    } else {
      setUseGeolocation(false);
      setUseGeolocationOpted(true);
    }
  };

  // Função para continuar sem localização
  const handleContinuarSemLocalizacao = () => {
    setUseGeolocation(false);
    setUseGeolocationOpted(true);
  };

  // Quando o usuário ainda não fez a escolha, mostramos os botões
  if (!useGeolocationOpted) {
    return (
	    <div className="welcome-container">
  <h1>Bem-vindo ao Indoor Routes</h1>
  <p>Encontre a melhor rota interna em nossa plataforma. Voc&ecirc; pode optar por ativar sua localiza&ccedil;&atilde;o para uma navega&ccedil;&atilde;o mais precisa ou definir sua origem manualmente.</p>
  <div className="button-group">
    <button className="button-ativar" onClick={handleAtivarLocalizacao}>
      <span role="img" aria-label="location">📍</span> Ativar Localiza&ccedil;&atilde;o
    </button>
    <button className="button-continuar" onClick={handleContinuarSemLocalizacao}>
      <span role="img" aria-label="manual">🚶‍♂️</span> Continuar Sem Localiza&ccedil;&atilde;o
    </button>
  </div>
</div>

    );
  }

  // Quando a escolha foi feita, mostramos a interface correta
  if (useGeolocation === null) {
    return <div>Carregando...</div>;
  }

  return useGeolocation ? <AppWithGeolocation /> : <AppWithoutGeolocation />;
};

export default App;

