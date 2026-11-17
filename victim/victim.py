from dotenv import load_dotenv
import os
import time
import logging

load_dotenv()

BD_PASSWORD=os.getenv("BD_PASSWORD")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)

logging.info(f"[START] Подключение к БД с паролем {BD_PASSWORD}")

while(True):
    time.sleep(60)