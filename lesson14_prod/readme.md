# Диагностика и отладка в Kubernetes

## 1. Подготавливаем виртуалки и устанавливаем kubelet kubeadm kubectl v 1.32

### Будем работать с containerd в качестве рантайма

1.1. Запускаем скрипт на всех виртуалках 
```bash
./script.sh
```
1.2. Только на мастер ноде
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16   --cri-socket unix:///run/containerd/containerd.sock
```
1.3. На мастер ноде копируем конфиг для работы с kubectl
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
1.4. На мастер ноде устанавливаем CNI Flunnel
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
1.5 На воркер нодах выполняем подключение к мастеру
```bash
kubeadm join 192.168.0.10:6443 --token <token> \
        --discovery-token-ca-cert-hash sha256:0cebba3b96f26355d29759d5165c0b52b7a5540ab15852cb245039c3e989196c
```

## 2. Обновление с 1.32 до 1.33

2.1. Обновляем репу на всех тачках
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /
EOF
```

2.2. Выводим мастера в drain
```bash
user@compute-master:~$ kubectl drain compute-master  --ignore-daemonsets
node/compute-master cordoned
Warning: ignoring DaemonSet-managed Pods: kube-flannel/kube-flannel-ds-tgdjs, kube-system/kube-proxy-2zqmv
evicting pod kube-system/coredns-668d6bf9bc-xmm4n
evicting pod kube-system/coredns-668d6bf9bc-tgg4w
pod/coredns-668d6bf9bc-xmm4n evicted
pod/coredns-668d6bf9bc-tgg4w evicted
node/compute-master drained
```
2.3. Обновляем на мастере kubelet kubeadm kubectl
```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl --allow-change-held-packages
```
2.4. Обновляемся на мастер ноде и вводим в работу
```bash
sudo kubeadm upgrade apply v1.33.2
kubectl uncordon compute-master 
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```
2.5. Выводим воркер 1 в drain (производится на мастере)
```bash
kubectl drain compute-worker1 --ignore-daemonsets
node/compute-worker1 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-flannel/kube-flannel-ds-dc4jf, kube-system/kube-proxy-rs5c6
evicting pod kube-system/coredns-674b8bbfcf-dgv72
pod/coredns-674b8bbfcf-dgv72 evicted
node/compute-worker1 drained
```
2.6. Обновляем на воркере 1 kubelet kubeadm kubectl
```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl --allow-change-held-packages
```
2.7. Обновляемся на воркере 1
```bash
user@compute-worker1:~$ sudo kubeadm upgrade node
[upgrade] Backing up kubelet config file to /etc/kubernetes/tmp/kubeadm-kubelet-config3553929514/config.yaml
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade/kubelet-config] The kubelet configuration for this node was successfully upgraded!
```
2.8. На воркере 1 рестартуем кублет
```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```
2.9 На мастере вводим воркера 1 в работу
```bash
kubectl uncordon compute-worker1
```
## Аналогично для воркера 2