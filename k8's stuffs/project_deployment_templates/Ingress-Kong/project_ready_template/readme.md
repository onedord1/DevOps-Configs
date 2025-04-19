Commads to install kong 

helm repo add kong https://charts.konghq.com

helm repo update

helm install kong kong/kong -n kong --create-namespace --version 2.48.0 --set proxy.type=LoadBalancer --set env.database=off