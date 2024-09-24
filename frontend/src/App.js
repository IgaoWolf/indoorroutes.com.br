import React, { useEffect, useState } from 'react';
import ReactDOM from 'react-dom';
import AppWithGeolocation from './components/AppWithGeolocation';
import AppWithoutGeolocation from './components/AppWithoutGeolocation';

const App = () => {
  const [useGeolocation, setUseGeolocation] = useState(null);

  useEffect(() => {
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
    return <div>Carregando...</div>; // Exibe um estado de carregamento
  }

  return useGeolocation ? <AppWithGeolocation /> : <AppWithoutGeolocation />;
};

export default App;
