from sqlalchemy import select
from app.db import SessionLocal
from app.models import User
import asyncio
from app.telegram import tg_send_message

def process_text(user_id: int, chat_id: int, text: str):
    # Здесь позже будет:
    # 1) rule-based intent
    # 2) если не распознано -> LLM provider -> tool calls -> ответ
    # Сейчас — простая заглушка
    with SessionLocal() as db:
        user = db.scalar(select(User).where(User.id == user_id))

    reply = f"Ок, понял: {text}"
    asyncio.run(tg_send_message(chat_id, reply))
