helm install mysql oci://registry-1.docker.io/bitnamicharts/mysql --values mysql.yaml

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx ingress-nginx/ingress-nginx