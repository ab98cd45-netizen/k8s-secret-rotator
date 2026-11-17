import base64
import secrets
import string
from datetime import datetime, timezone
from kubernetes import client, config

def generate_password(length=16):
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def main():
    # 1. Подключаемся к кластеру (изнутри пода)
    config.load_incluster_config()
    
    v1 = client.CoreV1Api()          # Для Secret
    apps_v1 = client.AppsV1Api()     # Для Deployment

    # 2. Генерируем новый пароль и кодируем в base64
    new_password = generate_password()
    encoded_pw = base64.b64encode(new_password.encode()).decode()

    # 3. Патчим Secret
    secret_patch = {"data": {"BD_PASSWORD": encoded_pw}}
    v1.patch_namespaced_secret(
        name="db-secret",
        namespace="default",
        body=secret_patch
    )

    # 4. Патчим Deployment, чтобы перезапустить поды с новой аннотацией
    now = datetime.now(timezone.utc).isoformat()
    deployment_patch = {
        "spec": {
            "template": {
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/restartedAt": now
                    }
                }
            }
        }
    }
    apps_v1.patch_namespaced_deployment(
        name="victim-app",
        namespace="default",
        body=deployment_patch
    )

if __name__ == "__main__":
    main()