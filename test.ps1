# ============ DELETE RESOURCES ================
#kubectl delete deployment lugx-gaming-frontend-deployment
#
#kubectl delete deployment lugx-gaming-database-deployment
#kubectl delete secret lugx-gaming-database-credentials-secret
#kubectl delete pvc lugx-gaming-database-pvc
#
#kubectl delete deployment lugx-gaming-clickhouse-deployment
#kubectl delete secret lugx-gaming-clickhouse-credentials-secret
#kubectl delete configmap lugx-gaming-clickhouse-init-configmap
#kubectl delete pvc lugx-gaming-clickhouse-pvc
#
#kubectl delete deployment lugx-gaming-games-service-api-deployment
#kubectl delete deployment lugx-gaming-order-service-api-deployment
#kubectl delete deployment lugx-gaming-analytics-service-api-deployment

# ============ CREATE RESOURCES ================
kubectl apply -f .\storage\storage.yml

kubectl apply -f .\database\lugx-gaming-database-secret.yml
kubectl apply -f .\database\lugx-gaming-database.yml

kubectl apply -f .\clickhouse\lugx-gaming-clickhouse-secret.yml
kubectl apply -f .\clickhouse\lugx-gaming-clickhouse-init-configmap.yml
kubectl apply -f .\clickhouse\lugx-gaming-clickhouse.yml

kubectl apply -f .\lugx-gaming-games-service-api.yml
kubectl apply -f .\lugx-gaming-order-service-api.yml
kubectl apply -f .\lugx-gaming-analytics-service-api.yml

kubectl apply -f .\lugx-gaming-frontend.yml

kubectl apply -f .\datadog\datadog-agent.yml

kubectl apply -f .\ingress\ingress-class.yml
kubectl apply -f .\ingress\ingress.yml
