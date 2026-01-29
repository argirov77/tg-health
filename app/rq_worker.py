import redis
from rq import Worker, Queue, Connection
from app.config import settings

listen = [settings.RQ_QUEUE_NAME]

def main():
    redis_conn = redis.Redis.from_url(settings.REDIS_URL)
    with Connection(redis_conn):
        worker = Worker([Queue(name) for name in listen])
        worker.work(with_scheduler=False)

if __name__ == "__main__":
    main()
