# Prompts listos — copiar y pegar en Cursor

> **Fuente de verdad:** `@PROMPT_EVOLUCION_SAAS_WHATSBOT.md`  
> **WhatsBot = app móvil Flutter (Android/iOS), UI tipo WhatsApp. PROHIBIDO UI web.**

---

## Cómo usarlo

| Paso | Acción |
|------|--------|
| 1 | Pega el proyecto del bot en esta carpeta (raíz) **con su `.env` y credenciales Google si las usa** |
| 2 | Un chat por fase (recomendado) |
| 3 | Cada mensaje empieza con `@PROMPT_EVOLUCION_SAAS_WHATSBOT.md` |
| 4 | Un prompt = una fase. No combines fases. |
| 5 | Tras cada fase: `Sí, continúa con la Fase N` o pega el siguiente prompt |

## Orden de fases (10 fases + validación)

| Prompt | Fase | Contenido |
|--------|------|-----------|
| 0 (opc.) | — | Verificar que el proyecto llegó |
| 1 | 0 | Análisis sin código |
| 2 | 1 | Scaffold `final_system/` |
| 3 | 2 | Gateway + chatbot copiado |
| 4 | 3 | Config centralizada |
| 5 | 4 | API + webhook + guardar mensajes en BD |
| 6 | 5 | Multi-negocio + modelos |
| 7 | 6 | Pedidos + ADMIN WhatsApp legacy |
| 8 | 7 | API REST + menú/intents/prompts por negocio (BD) |
| 9 | 8 | Google Sheets opcional |
| 10 | 9 | **App Flutter** + editores Menú/Intents/Mensajes |
| 11 | 10 | Validación final + README |

---

## Prompt 0 — Verificación al pegar el proyecto (opcional)

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Acabo de pegar el proyecto del chatbot en la raíz.

Solo verifica:
1. Hay código Python del bot
2. Lista 10 archivos clave
3. ¿Existe .env o equivalente? ¿JSON de Google? Lista nombres de variables (sin valores en el chat)

NO modifiques nada.
Di: "Listo para Prompt 1 (Fase 0)".
```

---

## Prompt 1 — Fase 0: Análisis (SIN tocar código)

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 0.

- Lee TODOS los archivos del bot en la raíz.
- NO modifiques, NO crees final_system/.

ENTREGABLES:
1. Tabla: Archivo | Propósito | ¿Chatbot? | Destino final_system | Acción
2. Mermaid: flujo cliente + flujo confirmación ADMIN_WHATSAPP_NUMBER
3. MAPA DE CREDENCIALES del bot original (sección 1.b del maestro):
   - Por cada variable: nombre legacy | archivo donde está | variable en final_system/.env | obligatoria/opcional
   - Incluir: Twilio, ADMIN_WHATSAPP_NUMBER, BD, JWT si aplica, Sheets, URL pública/ngrok, puerto
   - En el chat: NO pegar valores secretos (usar ***)
4. Riesgos: RIESGO | IMPACTO | MITIGACIÓN
5. Entry points (archivo + función)
6. Ubicación de intents, textos, Twilio, Sheets
7. Grafo de dependencias (15 nodos clave)

RECORDATORIO: WhatsBot final = Flutter móvil UI WhatsApp, NO web.

Pregunta: "¿Procedo con la Fase 1?" — NO avances sin mi Sí.
```

---

## Prompt 2 — Fase 1: Scaffold

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 1.

CREAR en final_system/:
- Árbol completo del prompt maestro (incluye whatsbot_app/ vacío con README.md: "App Flutter — se implementa en Fase 9")
- .env.example con TODAS las variables del mapa de credenciales (Fase 0)
- final_system/.env → COPIAR y ADAPTAR valores REALES desde el .env (o config) del bot en la raíz. Mapear nombres viejos → nuevos. NO dejar vacío si el legacy tenía datos. NO inventar credenciales.
- Si el legacy usa Google: copiar JSON de service account a ruta en final_system/ y referenciar en .env
- config/*.py con GUÍA RÁPIDA al final de cada archivo
- docs/ARCHITECTURE.md, INCREMENTAL_GUIDE.md (borrador)
- requirements.txt, .gitignore

NO mover el chatbot aún. NO crear gateway.

El bot en la raíz debe seguir igual.

Pregunta: "¿Procedo con la Fase 2?"
```

---

## Prompt 3 — Fase 2: Gateway

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 2.

1. COPIAR chatbot a final_system/chatbot/ (no borrar raíz aún)
2. Crear chatbot/gateway.py → handle_incoming_message() sin cambiar lógica
3. business_id opcional en payload
4. scripts/validate_chatbot.py

EJECUTAR validate_chatbot.py y pegar salida.

Pregunta: "¿Procedo con la Fase 3?"
```

---

## Prompt 4 — Fase 3: Config centralizada

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 3.

Mover hardcoded → config/* y .env (solo secrets en .env).
Valores tomados del proyecto del bot en la raíz — NO inventar.
Si un valor ya está en final_system/.env (Fase 1), no duplicar ni sobrescribir con placeholders.
Mismos textos e intents, solo nueva ubicación.

validate_chatbot.py → OK obligatorio.

Tabla: Antes en X → Ahora en Y (15 ítems).

NOTA: config/intents.py y config/prompts.py quedan como DEFAULTS globales; la edición del dueño será en BD vía app (Fases 5–9).

Pregunta: "¿Procedo con la Fase 4?"
```

---

## Prompt 5 — Fase 4: API + webhook + persistencia mensajes

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 4.

1. api/main.py (FastAPI)
2. api/routes/whatsapp.py → gateway + comentarios integración
3. infrastructure/twilio_client.py
4. models/conversation.py + message.py (mínimo viable)
5. conversation_service: cada mensaje entrante del webhook se GUARDA en BD (para Flutter Fase 9)

PROHIBIDO: UI web, Flutter en esta fase.

validate_chatbot.py → OK.

Diagrama: Twilio → whatsapp.py → gateway + save message → BD.

Pregunta: "¿Procedo con la Fase 5?"
```

---

## Prompt 6 — Fase 5: Multi-negocio

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 5.

1. models: business, menu, order, customer (+ conversation/message si falta)
2. Tablas o JSON para config por negocio: business_intents, business_prompts (semilla desde config/* al crear negocio)
3. infrastructure/database.py + migraciones
4. services: business, menu, order
5. api/routes: businesses, menus, orders
6. Mapeo TWILIO_WHATSAPP_FROM → business_id en webhook
7. Negocio "default" = comportamiento legacy; copiar intents/prompts del legacy a BD del default

validate_chatbot.py → OK.

Pregunta: "¿Procedo con la Fase 6?"
```

---

## Prompt 7 — Fase 6: Pedidos + ADMIN WhatsApp (crítico)

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 6.

PRESERVAR flujo exacto:
Cliente pide → bot → ADMIN_WHATSAPP_NUMBER → dueño confirma → bot responde al cliente

1. Localizar código legacy de confirmación y mantenerlo
2. notification_service.py
3. tests/test_order_confirmation_flow.py → ejecutar y pegar resultado

NO crear Flutter aún. NO eliminar confirmación por WhatsApp personal.

validate_chatbot.py → OK.

Pregunta: "¿Procedo con la Fase 7?"
```

---

## Prompt 8 — Fase 7: API REST para app Flutter

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 7.

Backend JSON para la app móvil (SIN UI web):

api/routes/whatsbot.py con comentarios entrada/salida:
- POST /auth/login (o usar auth.py)
- GET /whatsbot/conversations
- GET /whatsbot/conversations/{id}/messages
- POST /whatsbot/messages (dueño envía → Twilio TWILIO_WHATSAPP_FROM)
- GET /whatsbot/orders/pending
- POST /whatsbot/orders/{id}/approve
- POST /whatsbot/orders/{id}/reject
- GET /whatsbot/business/me
- GET/PUT /whatsbot/business/menu      ← edición menú por negocio (desde app)
- GET/PUT /whatsbot/business/intents   ← edición intents por negocio
- GET/PUT /whatsbot/business/prompts   ← edición textos del bot por negocio

chatbot/gateway.py: cargar menú + intents + prompts desde BD por business_id (fallback config/*).

middleware/auth.py JWT con business_id.

CORS habilitado para app móvil.

tests/test_whatsbot_api.py → incluir test PUT menu/intents y que gateway use BD.

docs/FLUTTER_APP.md (borrador: rutas y auth).
docs/GUIA_EDICION_APP.md (borrador: qué pantallas tendrá el dueño).

PROHIBIDO: HTML, React, panel web.
PROHIBIDO: decir al dueño que edite config/*.py para su negocio.

Pregunta: "¿Procedo con la Fase 8?"
```

---

## Prompt 9 — Fase 8: Google Sheets opcional

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 8.

1. sheets_sync_service.py — GOOGLE_SHEETS_ENABLED=false por defecto
2. api/routes/sheets.py
3. Migrar lógica Sheets del legacy si existe

Sistema debe funcionar con Sheets deshabilitado.

Pregunta: "¿Procedo con la Fase 9?"
```

---

## Prompt 10 — Fase 9: App Flutter WhatsBot (UI WhatsApp)

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 9.

CREAR final_system/whatsbot_app/ — proyecto Flutter completo.

OBLIGATORIO:
- Solo móvil (Android/iOS). NO Flutter Web como producto.
- UI lo más parecida a WhatsApp posible:
  - Lista de chats (header verde #075E54)
  - Pantalla chat: burbujas, fondo #ECE5DD, input abajo
  - Colores según whatsapp_theme.dart del prompt maestro
- Pantallas: login, chats_list, chat, order approve/reject en chat, settings
- OBLIGATORIO — editores (UI simple, formularios claros):
  - menu_editor_screen.dart → GET/PUT /whatsbot/business/menu
  - intents_editor_screen.dart → GET/PUT /whatsbot/business/intents
  - prompts_editor_screen.dart → GET/PUT /whatsbot/business/prompts
  - Acceso desde Ajustes (iconos o lista: Menú | Intents | Mensajes)
- lib/services/api_client.dart → consume API Fase 7
- lib/config/api_config.dart → apiBaseUrl = API_PUBLIC_URL del .env migrado (del bot original; no inventar URL)
- Polling o refresh para nuevos mensajes en chat activo

PROHIBIDO:
- Cualquier UI web para WhatsBot
- Twilio secrets en la app

VALIDACIÓN:
- flutter pub get && flutter analyze (pegar resultado)
- Prueba manual obligatoria:
  1. login → ver conversación → enviar mensaje → aprobar pedido
  2. Menú → editar un producto → guardar → describir que el bot usaría el menú nuevo
  3. Mensajes → cambiar bienvenida → guardar

Completar docs/FLUTTER_APP.md y docs/GUIA_EDICION_APP.md (tutorial para el dueño, español simple).

Pregunta: "¿Procedo con la Fase 10?"
```

---

## Prompt 11 — Fase 10: Validación final + guías

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Ejecuta ÚNICAMENTE la Fase 10 — cierre.

1. scripts/validate_system.py (gateway + API + flujo pedido)
2. Ejecutar todos los validate_* y tests; pegar salidas
3. README.md completo:
   - Sección "Credenciales": listar qué se migró desde el bot original (solo nombres de variables)
   - Sección A: arrancar backend (5-8 pasos)
   - Sección B: arrancar Flutter (whatsbot_app)
   - Alta de nuevo NEGOCIO (onboard_business.py); negocio default con Twilio/ADMIN del .env legacy
   - Probar: cliente, app Flutter, confirmación admin WhatsApp
4. docs/GUIA_NEGOCIOS.md — alta de negocio fácil
5. docs/GUIA_EDICION_APP.md — cómo el dueño edita menú/intents/mensajes SOLO desde la app
6. docs/INCREMENTAL_GUIDE.md (desarrolladores)
7. Checklist E2E del prompt maestro (incluye edición desde app)

NO TERMINAR sin app Flutter documentada y API corriendo.
NO pedir al usuario credenciales que ya estaban en el bot original sin haberlas migrado antes.

Guía súper fácil (15 líneas) al inicio del README.
```

---

## Prompt 11b — Solo si faltan credenciales tras Fase 1

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Revisé final_system/.env y faltan variables obligatorias que no encontraste en el bot original.

Lista SOLO:
1. Variable que falta
2. Dónde buscaste en el repo (archivos revisados)
3. Qué necesitas que yo proporcione (si realmente no está en el proyecto)

NO pidas de nuevo Twilio/ADMIN/BD si ya existen en el .env del bot en la raíz.
```

---

## Prompt 12 — Corrección (si una fase falló)

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

STOP. Fase [N] falló:
[error / qué dejó de funcionar]

Arregla SOLO lo necesario. NO reescribir intents.
NO crear UI web si el fallo es de Flutter — arreglar Flutter.

validate_chatbot.py → pegar salida.
¿Reintentamos la misma fase?
```

---

## Prompt 13 — Mejora incremental (post-proyecto)

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Sistema en final_system/ funcionando.

MEJORA: [una frase]

REGLAS:
- Cambio mínimo
- Si es UI → solo Flutter (whatsbot_app/)
- Si es un cambio solo de la app flutter -> solo flutter (whatsbot_app/)
- Actualizar docs/INCREMENTAL_GUIDE.md
- validate_chatbot.py al final
```

---

## Prompt 14 — Alta de negocio en producción

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Alta de NEGOCIO en producción (sin tocar chatbot):

Nombre: [ ]
TWILIO_WHATSAPP_FROM: [ ]
ADMIN_WHATSAPP_NUMBER: [ ]

Comandos copy-paste + cómo vincular dueño en app Flutter + pruebas.
```

---

## Continuar en chat nuevo

```
@PROMPT_EVOLUCION_SAAS_WHATSBOT.md

Continúa desde Fase [N]. Lee final_system/.
WhatsBot = Flutter móvil, NO web.
Resumen previo: [pega aquí]
Ejecuta solo esta fase según PROMPTS_LISTOS.md Prompt [N+1].
```

---

## Resumen visual del flujo

```
F0 Análisis
 → F1 Scaffold (+ carpeta whatsbot_app/)
 → F2 Gateway
 → F3 Config
 → F4 Webhook + mensajes en BD
 → F5 Multi-negocio
 → F6 Pedidos + ADMIN legacy
 → F7 API JSON (para Flutter)
 → F8 Sheets opcional
 → F9 App Flutter UI WhatsApp  ← la app del dueño
 → F10 Validación + README
```
