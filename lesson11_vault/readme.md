# Хранилище секретов для приложения (Vault)

## Шаги по развертыванию

### 1. Установка Consul
1. Клон репозитория consul:
    ```bash
    git clone https://github.com/hashicorp/consul-k8s.git
    ```
2. Меняем число реплик в consul-values.yaml и устанавливаем
    ```bash
    helm install consul --set global.name=consul --create-namespace -n consul -f consul-values.yaml consul/
    ```
### 2. Установка Vault
1. Клон репозитория vault:
    ```bash
    git clone https://github.com/hashicorp/vault-helm.git
    ```
2. Устанавливаем HA, прописываем число реплик в vault-values.yaml, а также адрес в секции storage "consul" = consul-server.consul.svc.cluster.local:8500 и устанавливаем vault
    ```bash
    helm install vault -n vault --create-namespace -f vault-values.yaml  vault/
    ```
3. Инициализируем Vault:
    ```bash
    vault operator init --key-shares=3 --key-threshold=2
    ```
4. Распечатываем ключи unseal в каждой реплике сервера:
    ```bash
    vault operator unseal
    ```
5. Добавляем секрет в вебке vault /otus/cred

6. Прописываем политику otus-policy
    ```hcl
    path "/otus/cred" {
        capabilities = ["read", "list"]
    }
    ```
7. Входим в Vault:
    ```bash
    vault login
    Token (will be hidden): 
    Success! You are now authenticated.
    ```


### 3. Настройка интеграции Vault с Kubernetes
1. Включаем аутентификацию kuber'a
    ```bash
    vault auth enable kubernetes
    Success! Enabled kubernetes auth method at: kubernetes/
    ```
2. Создаем SA для Secret Storage, чтобы тот мог забирать секреты с vault. Копируем его токен и серт
    ```bash
    kubectl apply -f sa-vault-auth.yaml
    kubectl get secret -n vault | grep vault-auth
    kubectl get secret secret-vault-auth -n vault -o jsonpath='{.data.token}' | base64 -d 
    kubectl get secret secret-vault-auth -n vault -o jsonpath='{.data.ca\.crt}' | base64 -d
    ```
3. Сохраняем токен и серт на сервере vault /tmp/{token,ca}

4. Настраиваем Kubernetes Auth Method:
    ```bash
    vault write auth/kubernetes/config \
    kubernetes_host=https://kubernetes.default.svc \
    kubernetes_ca_cert=@/tmp/ca \  
    token_reviewer_jwt="$(cat /tmp/token)" - скопировали из kubectl
    ```
5. Удаляем временные файлы /tmp/{token,ca}

6. Создаем роль для доступа к Vault:
    ```bash
        vault write auth/kubernetes/role/otus \
        bound_service_account_names=vault-auth \
        bound_service_account_namespaces=vault \
        policies=otus-policy \
        ttl=1h
    ```

### 4. Установка External Secrets Operator
1. Устанавливаем External Secrets Operator:
    ```bash
    helm repo add external-secrets https://charts.external-secrets.io
    helm install external-secrets external-secrets/external-secrets -n vault
    ```

2. Примените настройки из файла `secret-store.yaml`:
    ```bash
        kubectl apply -f secret-store.yaml
    ```

3. Примените настройки External Secrets:
    ```bash
        kubectl apply -f ext-secret.yaml
    ```
4. Проверяем, создался ли секрет otus-cred:
    ```bash
        kubectl get secrets -n vault
    ```
