import redis
from rq import Queue
from app.config import settings

redis_conn = redis.Redis.from_url(settings.REDIS_URL)
queue = Queue(settings.RQ_QUEUE_NAME, connection=redis_conn)

def enqueue_text_intent(user_id: int, chat_id: int, text: str):
    # job: обработать текст (пока без LLM — просто echo/route)
    return queue.enqueue("app.tasks_jobs.process_text", user_id, chat_id, text, job_timeout=60)
