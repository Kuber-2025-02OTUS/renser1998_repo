# Настройка кластера и установка мониторинга в Yandex Cloud

## Создание кластера

1. Создаем кластер в Yandex Cloud через веб-интерфейс:
   - 1 мастер-нода
   - 1 рабочая нода
   - 1 нода для инфраструктуры (с taint политикой `node-role=infra:NoSchedule`).
   - Добавляем метку для ноды инфраструктуры: `node-role=infra`.
   - Создаем также s3 хранилище

2. Устанавливаем Yandex CLI и настраиваем его:
   ```bash
   curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
   yc init
   ```

3. Получаем учетные данные для кластера:
   ```bash
   yc managed-kubernetes cluster get-credentials otus-cluster --external
   ```

4. Проверяем создание бакета для хранения данных:
   ```bash
   yc storage bucket list
   ```
   Ожидаемый вывод:
   ```
   +-------------------------+----------------------+------------+-----------------------+---------------------+
   |          NAME           |      FOLDER ID       |  MAX SIZE  | DEFAULT STORAGE CLASS |     CREATED AT      |
   +-------------------------+----------------------+------------+-----------------------+---------------------+
   | otus-cluster-storage-s3 | b1g***************65 | 5368709120 | STANDARD              | 2025-06-04 20:00:25 |
   +-------------------------+----------------------+------------+-----------------------+---------------------+
   ```

## Установка мониторинга

1. Пуллим Helm чарты Loki и kube-prometheus-stack:
   ```bash
   helm pull oci://cr.yandex/yc-marketplace/yandex-cloud/grafana/loki/chart/loki \
     --version 1.2.0-7 \  
     --untar 

   helm pull prometheus-community/kube-prometheus-stack --untar
   ```

2. Создаем файл `sa-key.json` с ключами доступа к сервисному аккаунту, который мы создали в Yandex Cloud:
   ```bash
   yc iam access-key create \                                                     
     --service-account-name=otus-cluster-storage-s3 \
     --format=json > sa-key.json
   ```

3. Устанавливаем Loki с помощью Helm, указывая имя бакета и файл с ключами доступа к сервисному аккаунту 
   и файлы с настройками `values.yaml` и `loki-stack-affinity.yaml`:
   ```bash
   helm install \                                                                                                    
     --namespace default \ 
     --set global.bucketname=otus-cluster-storage-s3 \
     --set-file global.serviceaccountawskeyvalue=sa-key.json \
     loki ./loki/ -f loki/values.yaml -f loki/loki-stack-affinity.yaml
   ```

4. Устанавливаем kube-prometheus-stack с помощью Helm, указывая файл с настройками `values.yaml` и `prom-stack-affinity.yaml`:
   ```bash
   helm install \                                              
     --namespace default  \        
     prom-stack ./kube-prometheus-stack/ -f kube-prometheus-stack/values.yaml -f kube-prometheus-stack/prom-stack-affinity.yaml
   ```