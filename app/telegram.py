import httpx
from app.config import settings

TG_API = f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}"

async def tg_send_message(chat_id: int, text: str):
    async with httpx.AsyncClient(timeout=20) as client:
        r = await client.post(f"{TG_API}/sendMessage", json={"chat_id": chat_id, "text": text})
        r.raise_for_status()
