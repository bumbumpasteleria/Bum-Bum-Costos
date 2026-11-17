import {AuthLayout} from './features/layout/Brand';

import React, { useState,useEffect } from 'react';
import { supabase } from './supabase';
import {registerPlugin} from '@capacitor/core';
import {nativeAuthRedirect} from './features/native/googleAuth.mjs';

export default function Login({ onLogin, onBack }) {
  const [googleReady,setGoogleReady]=useState(false);
  useEffect(()=>{let active=true;const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),8000);fetch(import.meta.env.VITE_SUPABASE_URL+'/auth/v1/settings',{headers:{apikey:import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY},signal:controller.signal}).then(r=>r.ok?r.json():null).then(d=>{if(active)setGoogleReady(d?.external?.google===true)}).catch(()=>{}).finally(()=>clearTimeout(timeout));const fail=()=>setError('No se completó el acceso con Google. Intenta de nuevo o usa tu contraseña.');window.addEventListener('bum-auth-error',fail);return()=>{active=false;controller.abort();clearTimeout(timeout);window.removeEventListener('bum-auth-error',fail)}},[]);
  async function googleLogin(){setLoading(true);setError('');try{const native=Boolean(window.Capacitor?.isNativePlatform?.());const {data,error}=await supabase.auth.signInWithOAuth({provider:'google',options:{redirectTo:native?nativeAuthRedirect:'https://bum-bum-costos.bumbumpasteleria.workers.dev/',skipBrowserRedirect:native,queryParams:{prompt:'select_account'}}});if(error)throw error;if(native){if(!data.url)throw Error('No se pudo abrir Google.');await registerPlugin('BumDevice').openExternal({url:data.url});}}catch{setError('No se pudo abrir el acceso con Google. Intenta nuevamente o usa tu contraseña.');}finally{setLoading(false)}}
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
    <AuthLayout>
      <form className="login-card" autoComplete="on" onSubmit={handleLogin}>
        <p className="eyebrow">BIENVENIDA A TU ESPACIO</p>
        <h1>Qué bueno verte.</h1>
        <p>Entra y sigue dando forma a tu negocio.</p>

        <label>
          Correo electrónico
          <input
            type="email" id="login-email" name="username" inputMode="email" autoCapitalize="none" autoCorrect="off"
            value={email}
            onChange={e => setEmail(e.target.value)}
            autoComplete="username"
            required
          />
        </label>

        <label>
          Contraseña
          <input
            type="password" id="login-password" name="password"
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
        {googleReady&&<><button type="button" className="secondary google-login" disabled={loading} onClick={googleLogin}>Continuar con Google</button><small>Usa el correo de tu cuenta aprobada. Google no reemplaza la autorización de acceso.</small></>}{onBack&&<button type="button" className="secondary" onClick={onBack} disabled={loading}>Volver al inicio</button>}
      </form>
    </AuthLayout>
  );
}
