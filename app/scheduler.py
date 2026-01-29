import time
from apscheduler.schedulers.blocking import BlockingScheduler

# Позже: читать пользователей из БД и отправлять напоминания по правилам.
# Сейчас — пинг раз в день/час как проверка.

from app.telegram import tg_send_message
import asyncio
from app.db import SessionLocal
from sqlalchemy import select
from app.models import User

sched = BlockingScheduler(timezone="Europe/Sofia")

@sched.scheduled_job("interval", minutes=60)
def hourly_check():
    with SessionLocal() as db:
        users = db.scalars(select(User)).all()
    # Заглушка: раз в час всем "жив?"
    for u in users:
        asyncio.run(tg_send_message(u.tg_chat_id, "Чек: ты на связи? (заглушка scheduler)"))

def main():
    sched.start()

if __name__ == "__main__":
    main()
