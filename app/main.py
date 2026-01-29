from fastapi import FastAPI
from app.router_health import router as health_router
from app.router_tg import router as tg_router
from app.router_admin import router as admin_router

app = FastAPI(title="Coach Bot API", version="0.1.0")

app.include_router(health_router, prefix="/health", tags=["health"])
app.include_router(tg_router, prefix="/tg", tags=["telegram"])
app.include_router(admin_router, prefix="/admin", tags=["admin"])
