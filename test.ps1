kubectl delete deployment lugx-gaming-frontend-deployment
kubectl delete secret lugx-gaming-database-credentials-secret
kubectl delete deployment lugx-gaming-games-service-api-deployment
kubectl delete deployment lugx-gaming-database-deployment
kubectl delete pvc lugx-gaming-database-pvc

kubectl apply -f .\database\lugx-gaming-database-secret.yml
kubectl apply -f .\database\lugx-gaming-database.yml
kubectl apply -f .\lugx-gaming-games-service-api.yml
kubectl apply -f .\lugx-gaming-frontend.yml