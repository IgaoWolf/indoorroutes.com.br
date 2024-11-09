import React from 'react';
import { BrowserRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import AppWithGeolocation from './components/AppWithGeolocation';
import AppWithoutGeolocation from './components/AppWithoutGeolocation';
import './styles/Welcome.css';
import indoorRoutesLogo from './styles/img/indoor-routes.png';
import studentWalking from './styles/img/estudante-andando.png';

const App = () => {
  return (
    <Router>
      <Routes>
        {/* Rota para a tela inicial */}
        <Route path="/" element={<Index />} />

        {/* Rotas para navega��o com e sem geolocaliza��o */}
        <Route path="/com-geolocalizacao" element={<AppWithGeolocation />} />
        <Route path="/sem-geolocalizacao" element={<AppWithoutGeolocation />} />
      </Routes>
    </Router>
  );
};

const Index = () => {
  const navigate = useNavigate();
  const [useGeolocation, setUseGeolocation] = React.useState(null);
  const [useGeolocationOpted, setUseGeolocationOpted] = React.useState(false);

  // Fun��o para ativar a localiza��o e navegar para a rota correspondente
  const handleAtivarLocalizacao = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUseGeolocation(true);
          setUseGeolocationOpted(true);
          navigate('/com-geolocalizacao'); // Redireciona para a rota com geolocaliza��o
        },
        (error) => {
          console.error('Erro ao obter geolocaliza��o:', error);
          setUseGeolocation(false);
          setUseGeolocationOpted(true);
          navigate('/sem-geolocalizacao'); // Redireciona para a rota sem geolocaliza��o em caso de erro
        }
      );
    } else {
      setUseGeolocation(false);
      setUseGeolocationOpted(true);
      navigate('/sem-geolocalizacao'); // Redireciona para a rota sem geolocaliza��o caso o navegador n�o suporte geolocaliza��o
    }
  };

  // Fun��o para continuar sem localiza��o e navegar para a rota correspondente
  const handleContinuarSemLocalizacao = () => {
    setUseGeolocation(false);
    setUseGeolocationOpted(true);
    navigate('/sem-geolocalizacao'); // Redireciona para a rota sem geolocaliza��o
  };

  // Quando o usu�rio ainda n�o fez a escolha, mostramos os bot�es
  if (!useGeolocationOpted) {
    return (
      <div className="welcome-container">
        <img src={indoorRoutesLogo} alt="Indoor Routes Logo" className="logo" />
        <h1>Seja bem vindo</h1>
        <p>Encontre a melhor rota interna em nossa plataforma.</p>
        <img src={studentWalking} alt="Estudante Andando" className="student-walking" />
        <div className="button-group">
          <button className="button-ativar" onClick={handleAtivarLocalizacao}>
            <span role="img" aria-label="location">�</span> Ativar Localiza��o
          </button>
          <button className="button-continuar" onClick={handleContinuarSemLocalizacao}>
            <span role="img" aria-label="manual">����</span> Continuar Sem Localiza��o
          </button>
        </div>
        <p className="info-text">
          Voc� pode optar por ativar sua localiza��o para uma navega��o mais precisa ou definir sua origem manualmente.
        </p>
      </div>
    );
  }

  // Tela de carregamento tempor�ria, caso seja necess�rio (pode ser removida se n�o for usada)
  return null;
};

export default App;

