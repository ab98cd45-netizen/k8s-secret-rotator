set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Начинаем развертывание K8s Secret Rotator${NC}"

echo -e "\n[1/6] Проверка зависимостей..."
for cmd in docker minikube kubectl; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ Ошибка: утилита $cmd не установлена."
        exit 1
    fi
done
echo -e "${GREEN}Все зависимости на месте.${NC}"

echo -e "\n[2/6] Проверка статуса Minikube..."
if ! minikube status | grep -q "host: Running"; then
    echo "Запускаем Minikube (это может занять пару минут)..."
    minikube start --driver=docker
else
    echo -e "${GREEN}Minikube уже запущен.${NC}"
fi

echo -e "\n[3/6] Сборка Docker-образов..."
echo "Собираем образ Victim..."
docker build -t victim-app:v1 ./victim

echo "Собираем образ Rotator..."
docker build -t rotator-app:v1 ./rotator
echo -e "${GREEN}Образы собраны.${NC}"

echo -e "\n[4/6] Загрузка образов в Minikube..."
minikube image load victim-app:v1
minikube image load rotator-app:v1
echo -e "${GREEN}✔ Образы загружены в кластер.${NC}"

echo -e "\n[5/6] Применение манифестов Kubernetes..."
kubectl apply -f manifests/
echo -e "${GREEN}✔ Манифесты применены.${NC}"

echo -e "\n[6/6] Проверка состояния подов..."
sleep 3
kubectl get pods

echo -e "\n${GREEN}Развертывание успешно завершено!${NC}"
echo -e "Что делать дальше:"
echo -e "1. Чтобы посмотреть, как жертва прочитала пароль, выполните:"
echo -e "   kubectl logs -l app=victim"
echo -e "2. Чтобы вручную запустить ротатор, не дожидаясь CronJob, выполните:"
echo -e "   kubectl create job --from=cronjob/rotator-cronjob manual-rotation-1"
echo -e "3. Чтобы увидеть новый пароль в секрете:"
echo -e "   kubectl get secret db-secret -o jsonpath='{.data.BD_PASSWORD}' | base64 -d"
echo ""