"""
REST API for Flutter WhatsBot — Fase 7.

Todas las rutas requieren JWT (claim business_id) salvo que se indique lo contrario.
Sin UI web — solo JSON para la app móvil.

Rutas:
  GET  /whatsbot/conversations
  GET  /whatsbot/conversations/{id}/messages
  POST /whatsbot/messages              — dueño envía al cliente (Twilio línea del bot)
  GET  /whatsbot/orders/pending
  POST /whatsbot/orders/{id}/approve
  POST /whatsbot/orders/{id}/reject
  GET  /whatsbot/business/me
  GET/PUT /whatsbot/business/menu
  GET/PUT /whatsbot/business/intents
  GET/PUT /whatsbot/business/prompts
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from api.middleware.auth import get_current_business_id
from api.schemas import (
    BusinessMeOut,
    ConversationOut,
    IntentsConfigOut,
    IntentsConfigUpdate,
    MenuAppOut,
    MenuAppUpdate,
    MessageOut,
    OrderActionResponse,
    OrderOut,
    OwnerMessageCreate,
    PromptsConfigOut,
    PromptsConfigUpdate,
)
from chatbot.runtime import get_bot_context
from infrastructure.database import get_db
from infrastructure.twilio_client import send_whatsapp_message
from services import business_service as biz_svc
from services import conversation_service as conv_svc
from services import menu_service as menu_svc
from services import notification_service as notify_svc
from services import order_service as order_svc
from services import sheets_sync_service as sheets_svc

router = APIRouter(prefix="/whatsbot", tags=["whatsbot"])

BusinessId = Annotated[str, Depends(get_current_business_id)]


def _require_business(db: Session, business_id: str):
    biz = biz_svc.get_business(db, business_id)
    if not biz:
        raise HTTPException(404, detail="Negocio no encontrado")
    return biz


@router.get("/conversations", response_model=list[ConversationOut])
def list_conversations(
    business_id: BusinessId,
    limit: int = 100,
    db: Session = Depends(get_db),
) -> list[ConversationOut]:
    """Lista chats del negocio (estilo WhatsApp)."""
    _require_business(db, business_id)
    return conv_svc.list_conversations(db, business_id, limit=limit)


@router.get("/conversations/{conversation_id}/messages", response_model=list[MessageOut])
def list_conversation_messages(
    conversation_id: int,
    business_id: BusinessId,
    limit: int = 200,
    db: Session = Depends(get_db),
) -> list[MessageOut]:
    """Historial de un chat."""
    _require_business(db, business_id)
    conv = conv_svc.get_conversation_for_business(db, business_id, conversation_id)
    if not conv:
        raise HTTPException(404, detail="Conversación no encontrada")
    return conv_svc.list_messages(db, conv.id, limit=limit)


@router.post("/messages", response_model=MessageOut, status_code=201)
def send_owner_message(
    body: OwnerMessageCreate,
    business_id: BusinessId,
    db: Session = Depends(get_db),
) -> MessageOut:
    """
    Dueño responde manualmente desde la app.

    Entrada: customer_wa_id + body.
    Salida: mensaje guardado en BD; envío Twilio vía línea del bot (TWILIO_WHATSAPP_FROM).
    """
    _require_business(db, business_id)
    ctx = get_bot_context(start_background=False)
    wa_id = ctx.admin_service.canonical_wa_id(body.customer_wa_id, "") or body.customer_wa_id
    send_whatsapp_message(wa_id, body.body)
    saved = conv_svc.save_outgoing_message(
        db,
        customer_wa_id=wa_id,
        body=body.body,
        business_id=business_id,
        is_admin=True,
    )
    db.commit()
    if not saved:
        raise HTTPException(500, detail="No se pudo guardar el mensaje")
    return saved[-1]


@router.get("/orders/pending", response_model=list[OrderOut])
def list_pending_orders(
    business_id: BusinessId,
    limit: int = 100,
    db: Session = Depends(get_db),
) -> list[OrderOut]:
    """Pedidos pendientes de aprobación."""
    _require_business(db, business_id)
    return order_svc.list_orders(db, business_id, status="pending", limit=limit)


@router.post("/orders/{order_id}/approve", response_model=OrderActionResponse)
def approve_order(
    order_id: str,
    business_id: BusinessId,
) -> OrderActionResponse:
    """Aprueba pedido y notifica al cliente (legacy Sheets + Twilio)."""
    result = notify_svc.approve_order_from_app(order_id, business_id=business_id)
    return OrderActionResponse(ok=result.get("ok", False), message=result.get("message", ""))


@router.post("/orders/{order_id}/reject", response_model=OrderActionResponse)
def reject_order(
    order_id: str,
    business_id: BusinessId,
    reason: str = "",
) -> OrderActionResponse:
    """Rechaza pedido y avisa al cliente."""
    result = notify_svc.reject_order_from_app(
        order_id,
        business_id=business_id,
        reason=reason,
    )
    return OrderActionResponse(ok=result.get("ok", False), message=result.get("message", ""))


@router.get("/business/me", response_model=BusinessMeOut)
def get_business_me(
    business_id: BusinessId,
    db: Session = Depends(get_db),
) -> BusinessMeOut:
    """Perfil del negocio autenticado."""
    return _require_business(db, business_id)


@router.get("/business/menu", response_model=MenuAppOut)
def get_business_menu(
    business_id: BusinessId,
    db: Session = Depends(get_db),
) -> MenuAppOut:
    """Menú del negocio (fuente: BD)."""
    _require_business(db, business_id)
    items = menu_svc.list_menu_items(db, business_id)
    return MenuAppOut(items=items)


@router.put("/business/menu", response_model=MenuAppOut)
def put_business_menu(
    body: MenuAppUpdate,
    business_id: BusinessId,
    db: Session = Depends(get_db),
) -> MenuAppOut:
    """Reemplaza menú completo desde la app."""
    _require_business(db, business_id)
    items = menu_svc.replace_menu_items(db, business_id, body.items)
    db.commit()
    sheets_svc.maybe_sync_menu_after_update(db, business_id)
    return MenuAppOut(items=items)


@router.get("/business/intents", response_model=IntentsConfigOut)
def get_business_intents(
    business_id: BusinessId,
    db: Session = Depends(get_db),
) -> IntentsConfigOut:
    _require_business(db, business_id)
    return IntentsConfigOut(config=biz_svc.get_business_intents(db, business_id))


@router.put("/business/intents", response_model=IntentsConfigOut)
def put_business_intents(
    body: IntentsConfigUpdate,
    business_id: BusinessId,
    db: Session = Depends(get_db),
) -> IntentsConfigOut:
    _require_business(db, business_id)
    config = biz_svc.set_business_intents(db, business_id, body.config)
    db.commit()
    return IntentsConfigOut(config=config)


@router.get("/business/prompts", response_model=PromptsConfigOut)
def get_business_prompts(
    business_id: BusinessId,
    db: Session = Depends(get_db),
) -> PromptsConfigOut:
    _require_business(db, business_id)
    return PromptsConfigOut(config=biz_svc.get_business_prompts(db, business_id))


@router.put("/business/prompts", response_model=PromptsConfigOut)
def put_business_prompts(
    body: PromptsConfigUpdate,
    business_id: BusinessId,
    db: Session = Depends(get_db),
) -> PromptsConfigOut:
    _require_business(db, business_id)
    config = biz_svc.set_business_prompts(db, business_id, body.config)
    db.commit()
    return PromptsConfigOut(config=config)
