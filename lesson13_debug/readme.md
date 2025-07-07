# Диагностика и отладка в Kubernetes


1. Создал deployment с образом kyos0109/nginx-distroless

2. Создал эфемерный контейнер для отладки
```bash
     kubectl debug -it  webserver-deployment-6dd98db854-cgsq2 -n homework --image=nicolaka/netshoot --target nginx-distroless-container

```
3. Запускаем tcpdump
```bash
    webserver-pod  ~  tcpdump -nn -i any -e port 80
    tcpdump: WARNING: any: That device doesn't support promiscuous mode
    (Promiscuous mode not supported on the "any" device)
    tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
    listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
    13:04:48.321041 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 80: 127.0.0.1.44530 > 127.0.0.1.80: Flags [S], seq 4048599713, win 65495, options [mss 65495,sackOK,TS val 1475424436 ecr 0,nop,wscale 7], length 0
```
4.  Запускаем дебаг для ноды
```bash
    kubectl debug  node/cl13ahc7ddknedo2npnh-elod -it --image=nicolaka/netshoot
```
На нем выполняем

```bash
    chroot /host
    cat   var/log/pods/homework_webserver-pod_dc6f0565-b98f-4cd7-b07d-969148a30db4/nginx-distroless-container/0.log
```
5. Смотрим логи (В данном случае идет обращение к 443 порту. \x16\x03\x01\ - признак TLS)
```bash
    2025-07-07T12:49:22.947172704Z stdout F 127.0.0.1 - - [07/Jul/2025:20:49:22 +0800] "\x16\x03\x01\x02\x8C\x01\x00\x02\x88\x03\x03%\x7F\xB8\xF9\xBC\xEAG\xBCS\xDF>\xDE\xF14\xF7!F\x8A\x0B:\xBBb\xF1TD[\xF5\x01U\xC8u} \x7F\xFE\xB6\xAFkU\x9CX\xAB\x8A\xC8\xA6\x97\xCB\xC2\xE3)\xB3\xBE\xF8\xB3\x15\x06Z\x9E\xF9\xEE\xEFD\x0C\x81\xFE\x00\x22\x13\x01\x13\x03\x13\x02\xC0+\xC0/\xCC\xA9\xCC\xA8\xC0,\xC00\xC0" 400 157 "-" "-" "-"
```
6. Задание со * Запускаем strace с профилем --profile=sysadmin
```bash
    kubectl debug -it  webserver-pod -n homework --image=nicolaka/netshoot --target nginx-distroless-container --profile=sysadmin
```
```bash
    webserver-pod  ~  strace -p 13
    strace: Process 13 attached
    epoll_wait(8, [{events=EPOLLIN, data=0x7fb7dec22010}], 512, -1) = 1
    accept4(6, {sa_family=AF_INET, sin_port=htons(36220), sin_addr=inet_addr("127.0.0.1")}, [112 => 16], SOCK_NONBLOCK) = 3
    epoll_ctl(8, EPOLL_CTL_ADD, 3, {events=EPOLLIN|EPOLLRDHUP|EPOLLET, data=0x7fb7dec222c8}) = 0
    epoll_wait(8, [{events=EPOLLIN, data=0x7fb7dec222c8}], 512, 60000) = 1
```