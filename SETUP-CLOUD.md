# Command Center en la nube (Supabase) — 5 minutos

Hace que tus **notas, agenda e ideas** vivan en la nube: las ves desde el celular, en cualquier
navegador, y el **agente las puede leer** para actuar. Gratis.

## 1. Crear el proyecto (2 min)
1. Entrá a https://supabase.com → **Start your project** → creá uno (gratis).
2. Cuando cargue, andá a **SQL Editor → New query**.
3. Pegá TODO el contenido de `supabase-schema.sql` y apretá **Run**. (Crea la tabla y los permisos.)

## 2. Copiar tus 2 valores (1 min)
En Supabase → **Project Settings → API**:
- **Project URL** → ej. `https://abcdxyz.supabase.co`
- **anon public** key → una cadena larga que empieza con `eyJ...`

> La `anon` key es segura para el navegador: la tabla está protegida por RLS y solo permite leer/editar esa fila.

## 3. Pegarlos en el dashboard (1 min)
Abrí `command.html`, arriba del `<script>` hay un bloque **CLOUD CONFIG**:

```js
const CLOUD={
  url:"https://abcdxyz.supabase.co",   // ← tu Project URL
  key:"eyJ...tu_anon_key..."           // ← tu anon public key
};
```

Guardá y redeployá. Listo: el indicador arriba a la derecha pasa de `● local` a `● nube`.
A partir de ahí todo se sincroniza solo (sube al guardar, baja cada 45s).

## 4. Que el AGENTE lea tus datos (opcional, 1 min)
En el repo de THE GRID → **Settings → Secrets → Actions**, agregá:
- `SUPABASE_URL` = tu Project URL
- `SUPABASE_KEY` = la **service_role** key (Settings → API → `service_role`, secreta — NO la pongas en el HTML)

El agente entonces, en cada corrida, lee tus notas/ideas y detecta las **ejecuciones programadas
vencidas** (las imprime en el log; el hook para dispararlas está marcado en `grid-agent.mjs`).

## Notas
- Sin configurar nada, el dashboard sigue funcionando **solo-local** (este navegador). La nube es opt-in.
- El artifact dentro de Cowork no puede salir a internet (sandbox), así que la nube aplica a la
  versión desplegada (`command.html`). Para sincronizar el artifact con la nube hace falta un puente
  vía MCP — decime si lo querés y lo armo.
