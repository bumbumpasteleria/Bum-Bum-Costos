
import React, { useState } from 'react';
import { supabase } from './supabase';

export default function Login({ onLogin, onBack }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleLogin(e) {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const { data, error } =
        await supabase.auth.signInWithPassword({
          email: email.trim(),
          password
        });

      if (error) throw error;
      if (!data.session) {
        throw new Error('No se pudo iniciar sesión.');
      }

      onLogin?.(data.session);
    } catch (err) {
      setError(err.message || 'Error al iniciar sesión');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login-screen">
      <form className="login-card" onSubmit={handleLogin}>
        <img src="/logo.jpg" alt="Bum Bum Pastelería" />
        <h1>Bum Bum Costos</h1>
        <p>Administración privada de tu pastelería</p>

        <label>
          Correo electrónico
          <input
            type="email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            autoComplete="username"
            required
          />
        </label>

        <label>
          Contraseña
          <input
            type="password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            autoComplete="current-password"
            required
          />
        </label>

        {error && <p role="alert">{error}</p>}

        <button type="submit" disabled={loading}>
          {loading ? 'Ingresando...' : 'Iniciar sesión'}
        </button>
        {onBack&&<button type="button" className="secondary" onClick={onBack} disabled={loading}>Volver al inicio</button>}
      </form>
    </div>
  );
}
