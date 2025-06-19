namespace=$1
sa=$2
duration=$3
if [ -z "$namespace" ] || [ -z "$sa" ]; then
  echo "Usage: $0 <namespace> <service-account-name> [duration]"
  exit 1
fi
if [ -z "$duration" ]; then
  duration=1440m #one day
fi

context=$(kubectl config current-context)
cluster=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
ca=$(cat ~/.minikube/ca.crt |base64| tr -d '\n')
token=$(kubectl create token -n homework --duration=10m $sa)
if [ $? -ne 0 ]; then
  echo "Failed to create token for service account $sa in namespace $namespace"
  exit 1
fi
echo "
apiVersion: v1
kind: Config
clusters:
- name: ${cluster}
  cluster:
    certificate-authority-data: ${ca}
    server: ${server}
contexts:
- name: $sa-context
  context:
    cluster: ${cluster}
    namespace: $namespace
    user: $sa
current-context: $sa-context
users:
- name: $sa
  user:
    token: ${token}
" > $sa.config
echo "${token}" > token