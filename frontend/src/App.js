import React from 'react';
import { BrowserRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import AppWithGeolocation from './components/AppWithGeolocation';
import AppWithoutGeolocation from './components/AppWithoutGeolocation';
import './styles/Welcome.css';
import indoorRoutesLogo from './styles/img/indoor-routes.png';
import studentWalking from './styles/img/estudante-andando.png';
import comGeolocalizacaoIcon from './styles/img/com-geolocalizao.png';
import semGeolocalizacaoIcon from './styles/img/sem-geolocalizacao.png';

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

  const handleAtivarLocalizacao = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUseGeolocation(true);
          setUseGeolocationOpted(true);
          navigate('/com-geolocalizacao');
        },
        (error) => {
          console.error('Erro ao obter geolocaliza��o:', error);
          setUseGeolocation(false);
          setUseGeolocationOpted(true);
          navigate('/sem-geolocalizacao');
        }
      );
    } else {
      setUseGeolocation(false);
      setUseGeolocationOpted(true);
      navigate('/sem-geolocalizacao');
    }
  };

  const handleContinuarSemLocalizacao = () => {
    setUseGeolocation(false);
    setUseGeolocationOpted(true);
    navigate('/sem-geolocalizacao');
  };

  if (!useGeolocationOpted) {
    return (
      <div className="welcome-container">
        <img src={indoorRoutesLogo} alt="Indoor Routes Logo" className="logo" />
        <h1>Seja bem vindo</h1>
        <p>Encontre a melhor rota interna em nossa plataforma.</p>
        <img src={studentWalking} alt="Estudante Andando" className="student-walking" />
        <div className="button-group">
          <button className="button-ativar" onClick={handleAtivarLocalizacao}>
            <img src={comGeolocalizacaoIcon} alt="Ativar Localiza��o" className="button-icon" />
            Ativar Localiza��o
          </button>
          <button className="button-continuar" onClick={handleContinuarSemLocalizacao}>
            <img src={semGeolocalizacaoIcon} alt="Continuar sem Localiza��o" className="button-icon" />
            Continuar Sem Localiza��o
          </button>
        </div>
        <p className="info-text">
          Voc� pode optar por ativar sua localiza��o para uma navega��o mais precisa ou definir sua origem manualmente.
        </p>
      </div>
    );
  }

  return null;
};

export default App;