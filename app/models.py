from sqlalchemy import String, DateTime, func, BigInteger
from sqlalchemy.orm import Mapped, mapped_column
from app.db import Base

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    tg_chat_id: Mapped[int] = mapped_column(BigInteger, unique=True, index=True, nullable=False)
    display_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    timezone: Mapped[str] = mapped_column(String(64), default="Europe/Sofia", nullable=False)

    created_at: Mapped[object] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[object] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
