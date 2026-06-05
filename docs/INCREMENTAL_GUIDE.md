# Guía incremental — registro por fase

> Una nota breve al cerrar cada fase. El bot en **raíz** no debe regresar hasta validar.

## Fase 0 — Análisis ✅

- Inventario completo del bot en raíz.
- Mapa de credenciales legacy → `final_system/.env`.
- Diagramas flujo cliente + admin.
- **Sin código** en `final_system/`.

## Fase 1 — Scaffold ✅

**Hecho:**

- Árbol `final_system/` según prompt maestro.
- `config/settings.py`, `bot_config.py`, `intents.py`, `prompts.py`, `sheets_config.py` (con GUÍA RÁPIDA).
- `.env.example` con todas las variables del mapa Fase 0.
- `.env` con valores **copiados** del bot en raíz (Twilio, Admin, Sheets, cachés, JWT desde `SECRET_KEY`).
- `credentials/google-service-account.json` copiado desde raíz.
- `docs/ARCHITECTURE.md`, `INCREMENTAL_GUIDE.md` (este archivo).
- `requirements.txt`, `.gitignore`, `README.md`.
- `whatsbot_app/README.md` — placeholder Fase 9.
- Stubs en `api/`, `services/`, `models/`, `infrastructure/`, `scripts/`, `tests/`, `chatbot/`.

**No hecho (intencional):**

- Copiar chatbot / `gateway.py` → Fase 2.
- FastAPI webhook operativo → Fase 4.
- PostgreSQL migraciones → Fase 5.
- Flutter UI → Fase 9.

**Validación:** el bot en raíz (`python run.py`) sigue sin cambios.

**Variables migradas (nombres):** ver lista en `README.md` sección “Variables migradas”.

---

## Fase 2 — Gateway ✅

- [x] Copiar `app/` → `final_system/chatbot/app/` (raíz intacta)
- [x] `chatbot/gateway.py` → `handle_incoming_message()` (misma lógica que `POST /bot`)
- [x] `business_id` opcional en payload (passthrough)
- [x] `chatbot/runtime.py` — singleton servicios
- [x] `scripts/validate_chatbot.py`
- [x] Rutas `DATA_DIR` / `FLOWS_PATH` / `REPO_ROOT` apuntan solo a `final_system/`

**Validar:** `python scripts/validate_chatbot.py` desde `final_system/`.

---

## Fase 3 — Config ✅

- [x] Secrets y URLs solo en `final_system/.env` (sin sobrescribir valores Fase 1)
- [x] `config/settings.py` — Twilio, admin, JWT, paths, API
- [x] `config/sheets_config.py` — Sheets TTL, credenciales (alias legacy)
- [x] `config/bot_config.py` — FLOWS_PATH, NAV_HINT, branding
- [x] `config/intents.py` — GLOBAL_COMMAND_INTENTS + GREETING_PHRASES (parser legacy)
- [x] `config/prompts.py` — 21 textos desde `flows/restaurant_flow.json` + gateway
- [x] `chatbot/app/config.py` — shim hacia `config/*`
- [x] `validate_chatbot.py` → 0 fallos

---

## Fase 4 — API webhook ✅

- [x] `api/main.py` (FastAPI + CORS + `/health`)
- [x] `api/routes/whatsapp.py` → gateway + persistencia BD
- [x] `infrastructure/twilio_client.py` (TwiML + REST)
- [x] `models/conversation.py`, `models/message.py`
- [x] `services/conversation_service.py` (incoming + outgoing)
- [x] `scripts/migrate_db.py`, `scripts/validate_api.py`
- [x] `validate_chatbot.py` → 0 fallos

**Arranque:** `cd final_system && python -m api.main`  
**Webhook Twilio:** `{API_PUBLIC_URL}/webhook` (o `/bot`)

---

## Fase 5 — Multi-negocio ✅

- [x] Models: `business`, `business_intents`, `business_prompts`, `menu`, `order`, `customer`
- [x] Services: `business_service`, `menu_service`, `order_service`
- [x] API: `/businesses`, `/businesses/{id}/menu`, `/businesses/{id}/orders`
- [x] Webhook: `To` (Twilio) → `business_id` vía `twilio_whatsapp_from`
- [x] Negocio `default` sembrado desde `.env` + `config/intents` + `config/prompts`
- [x] `scripts/migrate_db.py`, `scripts/onboard_business.py`
- [x] `validate_chatbot.py` → 0 fallos

---

## Fase 6 — Pedidos + admin ✅

- [x] `services/notification_service.py` — fachada sobre `AdminService` legacy (notify, confirm, espejo BD)
- [x] `flow_engine` → `on_order_pending()` tras pedido pendiente
- [x] `gateway.py` — admin vía `notification_service` (mismo flujo: cliente → admin → CONFIRMAR → cliente)
- [x] `tests/test_order_confirmation_flow.py` — 3 tests OK
- [x] `validate_chatbot.py` → 0 fallos

```bash
python -m pytest tests/test_order_confirmation_flow.py -v
python scripts/validate_chatbot.py
```

---

## Fase 7 — API WhatsBot ✅

- [x] `api/routes/auth.py` — `POST /auth/login` (JWT + `business_id`)
- [x] `api/middleware/auth.py` — Bearer obligatorio en `/whatsbot/*`
- [x] `api/routes/whatsbot.py` — chats, mensajes, pedidos, menú/intents/prompts por negocio
- [x] `chatbot/gateway.py` + `business_context.py` — menú/intents/prompts desde BD (fallback `config/*`)
- [x] CORS ya en `api/main.py` (`CORS_ORIGINS`)
- [x] `tests/test_whatsbot_api.py` — PUT menu/intents/prompts + gateway BD
- [x] `docs/FLUTTER_APP.md`, `docs/GUIA_EDICION_APP.md` (borradores)

```bash
cd final_system
python -m pytest tests/test_whatsbot_api.py -v
python scripts/validate_chatbot.py
```

Variable nueva: `WHATSBOT_OWNER_PIN` (login app; no exponer en chat).

---

## Fase 8 — Google Sheets opcional ✅

- [x] `services/sheets_sync_service.py` — espejo BD→Sheets; `GOOGLE_SHEETS_ENABLED=false` por defecto
- [x] `api/routes/sheets.py` — status, settings, sync (JWT)
- [x] `GoogleSheetsClient.replace_menu_mirror` / `upsert_order_mirror` (legacy extendido)
- [x] Hooks no bloqueantes: PUT menú app + pedido en BD
- [x] `tests/test_sheets_api.py`
- [x] `validate_chatbot.py` → 0 fallos

```bash
cd final_system
python -m pytest tests/test_sheets_api.py -v
python scripts/validate_chatbot.py
```

Con Sheets apagado el sistema funciona igual (PostgreSQL + chatbot con caché/demo).

---

## Fase 9 — Flutter WhatsBot ✅

- [x] `whatsbot_app/` — proyecto Flutter Android/iOS (sin Flutter Web como producto)
- [x] UI tipo WhatsApp: header `#075E54`, chat `#ECE5DD`, burbujas `#DCF8C6` / blanco
- [x] Pantallas: login, chats, chat, order approve/reject, ajustes
- [x] Editores: menú, intents, mensajes (`GET/PUT /whatsbot/business/*`)
- [x] `lib/services/api_client.dart` + `lib/config/api_config.dart` (`API_PUBLIC_URL` del `.env`)
- [x] Polling chat 4 s / lista 8 s
- [x] `docs/FLUTTER_APP.md`, `docs/GUIA_EDICION_APP.md` completos

```bash
cd final_system/whatsbot_app
flutter pub get
flutter analyze
# No issues found!
```

Prueba manual: login → chat → enviar → aprobar pedido; Menú → guardar; Mensajes → bienvenida → guardar.

---

## Fase 10 — Validación + documentación ✅

**Hecho:**

- [x] `scripts/validate_system.py` — gateway + API + flujo pedido + edición BD
- [x] `validate_chatbot.py`, `validate_api.py`, `validate_system.py` → 0 fallos
- [x] `pytest tests/` → 15 passed
- [x] `README.md` completo (guía 15 líneas, credenciales, backend, Flutter, E2E)
- [x] `docs/GUIA_NEGOCIOS.md` — alta de negocio paso a paso
- [x] `docs/GUIA_EDICION_APP.md` — dueño edita menú/intents/mensajes solo desde app
- [x] `docs/INCREMENTAL_GUIDE.md` (este archivo)
- [x] `docs/FLUTTER_APP.md` — app documentada
- [x] API arranca con `DATABASE_URL=sqlite:///data/whatsbot.db` (dev local sin PostgreSQL)
- [x] `flutter analyze` → No issues found

**Checklist E2E (prompt maestro):**

| Ítem | Automatizado | Manual (Twilio real) |
|------|--------------|----------------------|
| Cliente → bot responde | `validate_system` gateway | Probar WhatsApp |
| Mensaje en app Flutter | webhook + `/whatsbot/conversations` | `flutter run` |
| Dueño responde desde app | API `/whatsbot/messages` | App + teléfono |
| Pedido → admin legacy | `validate_system` notify | ADMIN_WHATSAPP |
| Aprobar desde Flutter | `validate_system` approve | App |
| Aprobar desde ADMIN | `test_order_confirmation_flow` | WhatsApp admin |
| Sheets deshabilitado OK | `test_sheets_api` | — |
| Editar menú en app | `validate_system` menu BD | App → Menú |
| Editar intent en app | `test_whatsbot_api` intents | App → Intents |
| Editar bienvenida/mensajes | `validate_system` prompts BD | App → Mensajes |

```bash
cd final_system
python scripts/validate_chatbot.py
python scripts/validate_api.py
python scripts/validate_system.py
python -m pytest tests/ -v
cd whatsbot_app && flutter analyze
python -m api.main   # con .env y migrate_db
```

**Métrica de éxito:** junior arranca API + app con README, ve chats, responde, confirma pedidos, da de alta negocio y edita bot solo desde Flutter — sin UI web.

---

## Mejora incremental — Alertas tipo WhatsApp ✅

**Hecho (solo Flutter `whatsbot_app/`):**

- [x] `lib/services/message_alerts_service.dart` — sonido + vibración + notificaciones locales al llegar mensajes entrantes
- [x] Sonido corto en primer plano (`audioplayers`) y en canal Android (`res/raw/incoming_message.wav`)
- [x] Notificación del sistema si la app está en segundo plano o en otro chat (como WhatsApp)
- [x] Sin banner si el dueño ya está viendo ese chat; con sonido igualmente
- [x] Lista de chats: preview en negrita, hora verde y punto de no leído
- [x] Tap en notificación abre el chat correspondiente
- [x] Permisos Android `POST_NOTIFICATIONS` + `VIBRATE`; iOS delegado en `AppDelegate`

```bash
cd final_system/whatsbot_app
flutter pub get
flutter analyze
cd ..
python scripts/validate_chatbot.py
```

**Probar:** login → dejar app abierta en lista de chats → enviar WhatsApp al bot → suena y aparece notificación; abrir el chat → nuevo mensaje suena sin banner; minimizar app → notificación en bandeja del sistema.
