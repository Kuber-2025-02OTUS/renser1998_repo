

1. Деплой кластера с Terraform 
Необходимо изменить переменные terraform.tfvars (yc_token cloud_id folder_id)
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Terraform создать SA и сгенерирует ключ доступа к s3 sa_key.json

2. Устанавливаем csi вручную (файлы с репозитория https://github.com/yandex-cloud/k8s-csi-s3.git)
```bash
kubectl apply -f provisioner.yaml
kubectl apply -f driver.yaml
kubectl apply -f csi-s3.yaml
```

3. Создаем манифесты для теста
Github не дал запушить даже пустой секрет, поэтому демонстрирую тут:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: csi-s3-secret
  namespace: kube-system
stringData:
  accessKeyID: "<YOUR_ACCESS_KEY_ID>"
  secretAccessKey: "<YOUR_SECRET_ACCESS_KEY>"
  endpoint: "https://storage.yandexcloud.net"
```
4. Применяем манифесты

```bash
kubectl apply -f secret.yaml #выписываем секрет
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml #внутри контейнера команда загружает html страницу в pvc на базе s3
```
5. Проверяем хранилище s3