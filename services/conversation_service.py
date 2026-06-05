"""
Persist WhatsApp messages for Flutter (Fase 4).

Entrada: wa_id, body, business_id desde webhook.
Salida: filas en conversations + messages (incoming/outgoing).
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import List, Union

from sqlalchemy.orm import Session

from config.settings import DEFAULT_BUSINESS_ID
from models.conversation import Conversation
from models.message import Message

logger = logging.getLogger(__name__)

ReplyText = Union[str, List[str]]


def _preview_text(body: ReplyText, max_len: int = 120) -> str:
    if isinstance(body, list):
        text = " ".join(str(p) for p in body if p)
    else:
        text = str(body or "")
    text = text.strip()
    if len(text) > max_len:
        return text[: max_len - 3] + "..."
    return text


def _normalize_business_id(business_id: str | None) -> str:
    return (business_id or DEFAULT_BUSINESS_ID or "default").strip() or "default"


def get_or_create_conversation(
    db: Session,
    *,
    customer_wa_id: str,
    business_id: str | None = None,
    customer_name: str | None = None,
) -> Conversation:
    bid = _normalize_business_id(business_id)
    wa = customer_wa_id.strip()
    conv = (
        db.query(Conversation)
        .filter(
            Conversation.business_id == bid,
            Conversation.customer_wa_id == wa,
        )
        .one_or_none()
    )
    if conv is None:
        conv = Conversation(
            business_id=bid,
            customer_wa_id=wa,
            customer_name=customer_name or None,
        )
        db.add(conv)
        db.flush()
        logger.debug("Created conversation id=%s wa_id=%s", conv.id, wa)
    elif customer_name and not conv.customer_name:
        conv.customer_name = customer_name
    return conv


def save_incoming_message(
    db: Session,
    *,
    customer_wa_id: str,
    body: str,
    business_id: str | None = None,
    customer_name: str | None = None,
    is_admin: bool = False,
    channel: str = "whatsapp",
    twilio_sid: str | None = None,
) -> Message:
    """Store client (or admin) message received via Twilio webhook."""
    conv = get_or_create_conversation(
        db,
        customer_wa_id=customer_wa_id,
        business_id=business_id,
        customer_name=customer_name,
    )
    now = datetime.now(timezone.utc)
    preview = _preview_text(body)
    msg = Message(
        conversation_id=conv.id,
        direction="incoming",
        body=(body or "").strip(),
        wa_id=customer_wa_id,
        is_admin=is_admin,
        channel=channel,
        twilio_sid=twilio_sid,
        created_at=now,
    )
    db.add(msg)
    conv.last_message_preview = preview
    conv.last_message_at = now
    conv.updated_at = now
    db.flush()
    logger.info(
        "Saved incoming message conv=%s wa_id=%s admin=%s",
        conv.id,
        customer_wa_id,
        is_admin,
    )
    return msg


def save_outgoing_message(
    db: Session,
    *,
    customer_wa_id: str,
    body: ReplyText,
    business_id: str | None = None,
    is_admin: bool = False,
    channel: str = "whatsapp",
    twilio_sid: str | None = None,
) -> list[Message]:
    """Store bot reply (one row per TwiML/REST part)."""
    if not body:
        return []
    parts = body if isinstance(body, list) else [body]
    saved: list[Message] = []
    conv = get_or_create_conversation(
        db,
        customer_wa_id=customer_wa_id,
        business_id=business_id,
    )
    now = datetime.now(timezone.utc)
    for part in parts:
        text = str(part).strip()
        if not text:
            continue
        msg = Message(
            conversation_id=conv.id,
            direction="outgoing",
            body=text,
            wa_id=customer_wa_id,
            is_admin=is_admin,
            channel=channel,
            twilio_sid=twilio_sid,
            created_at=now,
        )
        db.add(msg)
        saved.append(msg)
        conv.last_message_preview = _preview_text(text)
        conv.last_message_at = now
    conv.updated_at = now
    db.flush()
    if saved:
        logger.info(
            "Saved %d outgoing message(s) conv=%s wa_id=%s",
            len(saved),
            conv.id,
            customer_wa_id,
        )
    return saved


def list_conversations(
    db: Session,
    business_id: str,
    *,
    limit: int = 100,
) -> list[Conversation]:
    return (
        db.query(Conversation)
        .filter(Conversation.business_id == _normalize_business_id(business_id))
        .order_by(Conversation.last_message_at.desc().nullslast(), Conversation.updated_at.desc())
        .limit(limit)
        .all()
    )


def get_conversation_for_business(
    db: Session,
    business_id: str,
    conversation_id: int,
) -> Conversation | None:
    return (
        db.query(Conversation)
        .filter(
            Conversation.id == conversation_id,
            Conversation.business_id == _normalize_business_id(business_id),
        )
        .one_or_none()
    )


def list_messages(
    db: Session,
    conversation_id: int,
    *,
    limit: int = 200,
) -> list[Message]:
    return (
        db.query(Message)
        .filter(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.asc())
        .limit(limit)
        .all()
    )
