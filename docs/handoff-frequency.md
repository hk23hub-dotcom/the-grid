# Handoff Spec: FREQUENCY UNIVERSE — universo de inquilino

## Overview

Universo personal de un inquilino (usuario invitado) que vive **dentro** del universo madre HK23 y se alcanza **solo a través de él**. El inquilino entra con su código, ve su mundo y lo construye; sus agentes son los agentes reales de la página madre, nunca copias.

Tiene tres caras que comparten lenguaje visual:

| Cara | Ruta | Quién la ve |
|---|---|---|
| **Portal** — la colisión | dentro de `#iu` | cualquiera que abra su universo |
| **La red** — mapa de rutas con seis planetas | `#iu-world` | quien pasó el portal |
| **Landing pública** | `?g=<slug>` · `/g/<slug>` · `/frequency` | cualquiera con el link |

Estado actual: implementado y verificado en `hk23-universe.html`. No hay Figma — **los valores de esta hoja salen del código, son exactos**.

---

## Layout

Todo el universo es un overlay `position:fixed; inset:0` sobre el universo madre.

| Capa | id | z-index | Notas |
|---|---|---|---|
| Universo del inquilino | `#iu` | 776 | contenedor raíz, `display:flex; flex-direction:column` al abrir |
| Panel de planeta | `#pl-panel` | 8 | `position:absolute` dentro de `#iu` |
| Galaxia (vista previa) | `#inq` | 775 | queda por debajo de `#iu` |
| Landing pública | `#inq-land` | 960 | scrollea |
| Panel del dueño | `#inq-admin` | 965 | el más alto: siempre gana |

**Estructura de `#iu`:** `#iu-top` (barra, `flex:none`) + `#iu-world` (`flex:1; min-height:0`) con el canvas a pantalla completa. El portal `#iu-portal` cubre `inset:0` hasta que se entra, y ahí recibe `.gone`.

**Regla de layout crítica:** las barras miden lo que miden y el cuerpo toma el resto. **No usar offsets fijos** — la versión anterior tenía `inset:110px 0 0 0` y a 390 px los chips tapaban 52 px del mapa.

---

## Design Tokens

### Paleta del mapa — `D`

| Token | Valor | Uso |
|---|---|---|
| `vd` | `#05070E` | fondo del campo (ultramar, sesgo azul deliberado) |
| `grid` | `#0A1018` | retícula de fondo |
| `hair` | `#17202F` | filetes, separadores, bordes de panel |
| `ice` | `#E6E4DE` | tipografía principal (hueso cálido, contrapesa el frío) |
| `cy` | `#5FA8D3` | acento estructural, hover |
| `hot` | `#FF6B00` | **reservado**: solo estado activo/seleccionado |
| `gold` | `#C9A227` | latón — planeta RELEASES |
| `dim` | `#46566E` | texto terciario, etiquetas apagadas |
| `soft` | `#8894A8` | texto secundario |

> **Regla dura:** `hot` no se usa en ningún otro lugar. Es el único elemento saturado de la interfaz; si aparece en dos sitios a la vez, pierde su función.

### Paleta del cielo — `SKY`

| Token | Valor | Uso |
|---|---|---|
| `deep` | `#050A1E` | cielo de la red |
| `neb` | `#7A5A2E` | nebulosa dorada (superior izquierda) |
| `neb2` | `#1E3A6E` | nebulosa azul (centro) |
| `band` | `#9FC4CE` | cuerpo de las cintas, `rgba(…,.13–.20)` |
| `core` | `#C6E84B` | línea que corre dentro de la cinta |
| `star` | `#DDE8FF` | estrellas |

Portal (colisión): fondo `#03040E`; bandas del disco `#8A3AE8` violeta · `#E03EC4` magenta · `#2878FF` azul · `#38E8F6` cian.

### Los seis planetas — `ORB`

| key | Etiqueta | Glifo | Color | Descripción | Nota (Hz) |
|---|---|---|---|---|---|
| `sets` | SETS | ◐ | `#5FA8D3` | sus sets grabados | 220 |
| `photos` | PHOTOS | ▣ | `#B9B4A9` | su archivo de fotos | 330 |
| `releases` | RELEASES | ◉ | `#C9A227` | la música que sacó | 165 |
| `clubs` | CLUBS | ⬢ | `#C1543A` | donde pinchó | 110 |
| `plugins` | PLUGINS | ⌘ | `#8C7AB6` | lo que programó él | 82.5 |
| `sellos` | SELLOS | ✦ | `#5E9E7E` | sellos que lo editaron | 55 |

Metales envejecidos de **valor equiparado** a propósito: ninguno debe dominar. Las notas son la serie armónica de una fundamental de 55 Hz.

### Tipografía

Una sola familia — `"Space Mono", ui-monospace, monospace` — con **contraste de escala extremo** como recurso principal.

| Rol | Tamaño | Tracking | Peso | Color |
|---|---|---|---|---|
| Título de planeta (canvas) | `S*1.15` | — | 700 | `ice` / `dim` si vacío |
| Contador de items | `S*0.84` | — | 500 | color del planeta |
| Nombre del universo (portal) | `clamp(40px,9vw,86px)` | −2.5px | 300 | `#DCE8F0` |
| Título de panel | 30px | −1px | 700 | `ice` |
| Etiqueta / eyebrow | 8px | 4px | 500 | color del planeta |
| Dato de registro | `S*1.0` | — | 500 | `ice` |
| Bajada | `S*0.80` | — | 500 | `dim` |

`S = max(10, W*0.0070)` donde `W` es el ancho del canvas en píxeles de dispositivo (canvas a 2×). **El tipo escala con el canvas, no con el viewport.**

Usar `font-variant-numeric: tabular-nums` en toda columna de cifras.

---

## Components

| Componente | id | Props / estado | Notas |
|---|---|---|---|
| Portal | `#iu-portal` | `.gone` al entrar | canvas `#iu-pcv` de fondo; el rAF se detiene al entrar (`stopPortalFx`) |
| Canvas de la red | `#iu-cv` | — | backing store a 2×; **re-fit ante cambio de ancho O alto** |
| Barra superior | `#iu-top` | — | ✎ EDITAR y ◌/◉ SONIDO solo si `canEdit()` / siempre |
| Panel lateral | `#iu-panel` | — | bio, agentes prestados, productos |
| Panel de planeta | `#pl-panel` | `--pc` = color del planeta | `.open`; cierra por ✕, click en el fondo, X o ESC |
| Chips de órbita | `.iu-orbchip` | `.on` | `--oc` = color; se pintan al entrar en edición |
| Registro lateral | canvas | — | seis filas con glifo, nombre, contador y bajada |

### Props del inquilino (`universe_galaxies`)

| Campo | Tipo | Notas |
|---|---|---|
| `slug` | text PK | usado en `?g=` y `/g/:slug` |
| `name` `sub` `bio` | text | identidad |
| `code` | text | código de entrada; se chequea **antes** que los códigos normales |
| `color` `skin` | text | `skin:'espectro'` activa este lenguaje visual |
| `tier` | text | tier que otorga su código |
| `active` | boolean | `false` cierra el acceso al instante |
| `agents` `links` `nodes` | text (JSON) | parseo defensivo obligatorio |

### Props de un item (`nodes[]`)

| Campo | Límite | Notas |
|---|---|---|
| `label` | 22 chars, uppercase | se trunca a 24 en canvas |
| `sub` | 40 chars | |
| `link` | url | saneada: solo `http(s)`, `encodeURI` |
| `cat` | enum de `ORB` | fallback a `sets` si es inválida |

---

## States and Interactions

| Elemento | Estado | Comportamiento |
|---|---|---|
| Planeta | default | esfera con luz propia, terminador y atmósfera |
| Planeta | vacío | `globalAlpha .5`, etiqueta `dim`, contador **VACÍO** |
| Planeta | hover | anillo `rgba(221,232,255,.55)` a `r*1.85`; cursor `pointer` |
| Planeta | click (lectura) | abre `#pl-panel` + suena su nota |
| Planeta | click (edición) | selecciona esa órbita para el próximo objeto |
| Campo | click | lanza frente de onda; los objetos que cruza resuenan |
| Chip de órbita | `.on` | fondo del color, texto `#05070E`, peso 700 |
| Botón sonido | off / on | `◌ SONIDO` / `◉ SONIDO` + clase `.on` |
| ✎ EDITAR | sin permiso | **oculto**, no deshabilitado |
| Guardar nodo | sin selección | mensaje en `hot`, no falla en silencio |

### Permisos

`canEdit()` = el inquilino entró con su propio código (`hk23_inq_me`) **o** el visitante es tier `socio`. `TIER_RANK = {visita:0, referido:1, obsesionado:2, socio:3}`. Un desconocido ve el universo completo en **solo lectura**, sin el control de edición.

---

## Responsive Behavior

| Breakpoint | Cambios |
|---|---|
| Desktop (>860px) | mapa y panel lateral lado a lado |
| Tablet/móvil (≤860px) | `#iu-body` pasa a columna; el mapa toma 32–34vh; el panel pierde `max-width` |
| ≤820px | mismo tratamiento en la vista de galaxia |
| ≤768px / ≤640px | ajustes del universo madre |

Las cintas de la red están acotadas al **70% izquierdo** del canvas para que nunca corran bajo el registro lateral.

En táctil: `touchstart` es `{passive:true}`, `touchmove` es `{passive:false}` porque hace `preventDefault` al arrastrar.

---

## Edge Cases

- **Universo vacío** — los seis planetas se dibujan igual, apagados y marcados VACÍO. La forma de su mundo se entiende antes de que cargue nada. El registro lateral muestra `00`.
- **Planeta vacío** — el panel dice "Este planeta está vacío" y, solo si puede editar, "Tocá ✎ EDITAR y sumale lo tuyo".
- **Item sin link** — se lista sin botón ABRIR; no se renderiza un enlace muerto.
- **Texto largo** — `label` se corta a 24 en canvas y a 22 al guardar; las etiquetas de planeta se **reposicionan** si colisionan (se ordenan por `y` y se empujan `LS*4.4`).
- **Sin Supabase** — todo funciona igual contra `localStorage`; lo guardado se marca **LOCAL** y el mensaje dice la verdad ("guardado en este dispositivo"). Nunca se afirma que se guardó globalmente si no fue así.
- **JSON corrupto** en `nodes`/`agents`/`links` — parseo en `try/catch` con fallback a `[]`.
- **`cat` inválida o ausente** — cae a `sets` en vez de desaparecer del mapa.
- **Redimensionar en vertical** — el canvas re-ajusta su backing store ante **cualquier** dimensión; comparar solo el ancho desincroniza los planetas de sus zonas de toque.
- **Objeto al fondo del campo** — el factor de perspectiva `p.s` se acota a `≥0.15`: sin eso, los radios se van a negativo y el canvas lanza excepción.

---

## Animation / Motion

| Elemento | Disparador | Animación | Duración | Curva |
|---|---|---|---|---|
| Cintas | continuo | ancho por coseno; al pasar por cero la cinta se retuerce | `t*0.00016` | — |
| Línea interior | continuo | se teje de borde a borde y fluye | `t*0.00042` | — |
| Planetas | continuo | recorren su cinta entre `u=0.10` y `0.90` | `t*0.0000042` | lineal |
| Lunas de PHOTOS | continuo | orbitan el planeta | `t*0.0006*(k+1.4)` | lineal |
| Estrellas | continuo | parpadeo | `sin(t/700)` | — |
| Frente de onda | tacto | expande a `max(W,H)*0.62`, se desvanece | 1500 ms | lineal |
| Anillos propios | continuo | dos anillos por objeto a su período | según `w` | — |
| Disco del portal | continuo | cuatro bandas rotando a distinta velocidad | `t*0.000045` | — |
| Marcas de anillo | continuo | contra-rotan anillo por anillo | `t*0.00004` | — |
| Filamentos | continuo | 26 curvas latiendo desde el choque | `t*0.00022` | — |
| Voz | tacto / cruce | seno con pasabajos; ataque 12 ms, cola larga | 2200–3400 ms | exponencial |

**`prefers-reduced-motion`**: el universo madre ya lo respeta en su capa FX. **Pendiente en este módulo** — ver Pendientes.

---

## Audio

| Aspecto | Decisión |
|---|---|
| Estado inicial | **apagado**. Audio que arranca solo es hostil. |
| Activación | solo por gesto real (los navegadores lo exigen); `AudioContext` se crea recién ahí |
| Persistencia | `hk23_freq_audio` |
| Ganancia master | 0.16, con `setTargetAtTime` para evitar clicks |
| Voz | `sine` → `biquad lowpass` a `min(8000, hz*7)`, Q 0.8 |
| Envolvente | ataque 12 ms → cola 2.2–3.4 s, rampas exponenciales |

---

## Accessibility

**Implementado**
- Cierre por teclado en todos los overlays: `X` y `Escape`.
- Los handlers de tecla ignoran eventos con foco en `INPUT`/`TEXTAREA`/`SELECT`.
- El handler base de `Escape` cede cuando hay un mundo abierto: cerrar un mundo ya no navega la pantalla de fondo.
- Todo dato externo pasa por `esc()` antes de entrar al DOM; los `href` se arman con partes saneadas.
- `rel="noopener noreferrer"` en todo enlace externo.

**Pendiente — recomendado antes de considerarlo terminado**

| Tema | Qué falta |
|---|---|
| Navegación por teclado del mapa | los planetas solo responden a puntero. Añadir una lista `role="list"` visualmente oculta, o hacer el canvas `tabindex="0"` con flechas para ciclar planetas y Enter para entrar |
| Anuncio a lector de pantalla | el canvas es opaco. Espejar el registro lateral en DOM real con `aria-live="polite"` al cambiar de planeta |
| Foco visible | los `.iu-b` y `.iu-orbchip` no declaran `:focus-visible`; heredan el default del navegador sobre fondo oscuro |
| Orden de foco | al abrir `#pl-panel` el foco no se mueve al panel ni se atrapa; al cerrar no vuelve al origen |
| `prefers-reduced-motion` | este módulo anima siempre. Debería congelar cintas y planetas y quedarse en un fotograma estable |
| Contraste | `dim` `#46566E` sobre `#05070E` da ~4.0:1 — suficiente para texto grande, **por debajo de AA para 12px o menos**. Subir a ~`#6E7E96` en las bajadas del registro |

---

## Implementation Notes

Stack real: **HTML autocontenido, sin build, sin framework.** Canvas 2D para todo el render; el DOM solo para paneles y formularios.

- Cada bloque es su propio IIFE y se comunica por `window.*` (`window.Inquilinos`, `window.InqUniverse`, `window.FreqAudio`).
- El canvas usa backing store a 2× y **todas las medidas de tipo derivan de `W`**, no de píxeles CSS.
- Persistencia: Supabase REST con `Prefer: resolution=merge-duplicates`, más `localStorage` como respaldo que **sí se lee de vuelta** (fue un bug real: se escribía y nunca se mostraba).
- Tablas: `universe_galaxies`, `universe_products`, `universe_events`, `universe_sellers`, `universe_presence` — todas con RLS en `supabase-schema.sql`.

---

## Pendientes

1. Accesibilidad de teclado y lector de pantalla en el mapa (tabla de arriba).
2. `prefers-reduced-motion` en este módulo.
3. Contraste de `dim` en tamaños pequeños.
4. La landing pública todavía usa el espectrograma anterior; falta llevarla al lenguaje de la red.
