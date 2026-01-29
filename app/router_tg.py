from fastapi import APIRouter, Header, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.config import settings
from app.deps import get_db
from fastapi import Depends
from app.models import User
from app.telegram import tg_send_message
from app.tasks import enqueue_text_intent

router = APIRouter()

# Простейшая таблица дедупа — можно потом вынести в отдельную модель.
# Для v0 сделаем дедуп в Redis (быстрее) — но пока покажу простой подход: только в Redis.
import redis
from app.config import settings as st

rds = redis.Redis.from_url(st.REDIS_URL, decode_responses=True)

@router.post("/webhook")
async def telegram_webhook(
    update: dict,
    x_telegram_bot_api_secret_token: str | None = Header(default=None),
    db: Session = Depends(get_db),
):
    if x_telegram_bot_api_secret_token != settings.TELEGRAM_WEBHOOK_SECRET:
        raise HTTPException(status_code=401, detail="Bad secret token")

    update_id = update.get("update_id")
    if update_id is None:
        return {"ok": True}

    # Дедуп: если уже видели update_id — игнор
    key = f"tg:update:{update_id}"
    if rds.get(key):
        return {"ok": True}
    rds.setex(key, 60 * 60, "1")

    message = update.get("message") or update.get("edited_message")
    if not message:
        return {"ok": True}

    chat = message.get("chat", {})
    chat_id = chat.get("id")
    text = (message.get("text") or "").strip()

    if not chat_id:
        return {"ok": True}

    # ensure user
    user = db.scalar(select(User).where(User.tg_chat_id == chat_id))
    if not user:
        user = User(tg_chat_id=chat_id, display_name=chat.get("username") or chat.get("first_name"))
        db.add(user)
        db.commit()
        db.refresh(user)

    # Команды — обрабатываем сразу
    if text.startswith("/start"):
        await tg_send_message(chat_id, "Ок. Я твой тренер. Команды: /status /now /wake /sleep /food /train")
        return {"ok": True}

    if text.startswith("/status"):
        await tg_send_message(chat_id, "Status: (заглушка) — подключим DB-агрегацию на следующем шаге.")
        return {"ok": True}

    # Свободный текст — в очередь (LLM/intent)
    enqueue_text_intent(user_id=user.id, chat_id=chat_id, text=text)
    await tg_send_message(chat_id, "Принял. Обрабатываю…")
    return {"ok": True}
