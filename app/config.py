from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_ENV: str = "dev"
    LOG_LEVEL: str = "INFO"

    TELEGRAM_BOT_TOKEN: str
    TELEGRAM_WEBHOOK_SECRET: str
    PUBLIC_BASE_URL: str | None = None

    DATABASE_URL: str
    REDIS_URL: str
    RQ_QUEUE_NAME: str = "default"

    class Config:
        env_file = ".env"

settings = Settings()
