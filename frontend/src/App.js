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

  React.useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        () => setUseGeolocation(true),
        () => setUseGeolocation(false)
      );
    } else {
      setUseGeolocation(false);
    }
  }, []);

  if (useGeolocation === null) {
    return <div>Carregando...</div>;
  }

  return useGeolocation ? <AppWithGeolocation /> : <AppWithoutGeolocation />;
};

export default App;
