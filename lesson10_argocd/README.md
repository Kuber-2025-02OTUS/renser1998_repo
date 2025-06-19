# Дз GitOps

1. Установил ingress nginx контроллер кластер через яндекс marketplace

Добавил метку homework у ноды (infra), чтобы деплоя подов
```bash
kubectl label nodes cl147k3q74mcsd3utlmr-usel homework=true 
```

2. Установил в кластер ArgoCD с помощью Helm-чарта
```bash
helm pull oci://cr.yandex/yc-marketplace/yandex-cloud/argo/chart/argo-cd \
  --version 7.3.11-2 \
  --untar 
```
3. Отредакировал файл values.yaml для argocd
```yaml
    tolerations: 
        - key: "node-role"
          operator: "Equal"
          value: "infra"
          effect: "NoSchedule"
    affinity: 
        nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                    - key: "node-role"
                      operator: In
                      values:
```
4. Установил argocd чарт
```bash
helm install \
  --namespace argo-cd \
  --create-namespace  -f ./argo-cd/values.yaml \
  argo-cd ./argo-cd/
```
5. Получаю пароль от админки
```bash
kubectl --namespace argo-cd get secret argocd-initial-admin-secret \
  --output jsonpath="{.data.password}" | base64 -d
```
6. Пробросил порт через k9s для сервиса argocd server

7. Запустил проект otus (project.yaml)
Запустил деплой 2 приложение из репозитория (app_network.yaml+app_templates.yaml согласно требованиям ДЗ)

Для приложение templates указал след.параметры, так как в процессе деплоя возникает попытка пачтить PVC, что кластер не дает сделать. 

```yaml
spec:
  ignoreDifferences:
  - kind: PersistentVolumeClaim
    jsonPointers:
    - /spec/volumeName
    - /spec/storageClassName
```
8. Заходим на вебку и смотри деплой приложений.