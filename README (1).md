# Bum Bum Costos — v0.3

Aplicación de costos y cotizaciones para Bum Bum Pastelería. Proyecto React + Vite, listo para evolucionar a PWA con Supabase.

## Qué funciona hoy
- Ingredientes y costos según última compra, con conversiones compatibles de masa, volumen y unidades.
- Recetas fijas y escalables, cotizaciones con decoraciones, mano de obra y gastos.
- Registro manual de ventas, respaldo y restauración JSON del prototipo v1.
- Diseño con el logo oficial, manifiesto instalable y iconos.

## Lo que aún NO funciona
- Persistencia en Supabase, autenticación privada, sincronización entre dispositivos, inventario automático, importación CSV/Excel de ventas y lectura PDF/Word/imagen de recetas.
- La aplicación usa `localStorage`; **no introduzcas datos definitivos sin hacer respaldos**.
- El manifiesto está preparado, pero aún falta configurar un service worker para capacidades offline completas.
- La unidad `lb comercial` de rendimiento de recetas no se convierte automáticamente a masa: se trata como rendimiento de receta.

## Ejecutar localmente
Instalar Node.js 20+, ejecutar `npm install`, después `npm run dev`. Para producción: `npm run build`, publicar la carpeta `dist`.

## Cloudflare Pages
Conectar el repositorio privado a Pages, framework `Vite`, build command `npm run build`, output directory `dist`. La publicación no convierte automáticamente el almacenamiento local en una base de datos en la nube.

## Migración segura
1. En el prototipo original, pestaña **Respaldo**, descargar JSON.
2. Guardar ese JSON en lugar seguro. No subirlo a GitHub.
3. En la nueva app, pestaña **Respaldo**, restaurar JSON.
4. Verificar conteos y costos antes de usar la nueva app.
5. Conservar el HTML antiguo y el respaldo hasta completar la migración a Supabase.

## Próximos hitos
1. Supabase Auth y políticas RLS para un solo usuario.
2. Tablas SQL con migraciones versionadas y carga de JSON con validación.
3. Inventario por movimientos de producción (no duplicar descuentos en ventas).
4. Importación asistida de reportes CSV/Excel y recetas PDF/Word/imágenes.
5. Service worker, actualizaciones y pruebas de respaldo.

Nunca colocar contraseñas ni claves `service_role` en el código cliente.
