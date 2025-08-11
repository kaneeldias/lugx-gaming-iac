# ============ DELETE RESOURCES ================
kubectl delete deployment lugx-gaming-frontend-deployment

kubectl delete deployment lugx-gaming-database-deployment
kubectl delete secret lugx-gaming-database-credentials-secret
kubectl delete pvc lugx-gaming-database-pvc

kubectl delete deployment lugx-gaming-clickhouse-deployment
kubectl delete secret lugx-gaming-clickhouse-credentials-secret
kubectl delete configmap lugx-gaming-clickhouse-init-configmap
kubectl delete pvc lugx-gaming-clickhouse-pvc

kubectl delete deployment lugx-gaming-games-service-api-deployment
kubectl delete deployment lugx-gaming-order-service-api-deployment
kubectl delete deployment lugx-gaming-analytics-service-api-deployment

# ============ PRE-CONFIG ================
aws eks update-kubeconfig --region eu-west-1 --name lugx-gaming-cluster
./eksctl.exe utils associate-iam-oidc-provider --region eu-west-1 --cluster lugx-gaming-cluster --approve
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json
./eksctl.exe create iamserviceaccount --cluster=lugx-gaming-cluster --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::996835183634:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --region eu-west-1 --approve --aws-region=eu-west-1 --vpc-id=vpc-09a5162f6389a4ebf
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# replace VPC ID below
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=lugx-gaming-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=eu-west-1 --set vpcId=vpc-09a5162f6389a4ebf

# ============ CREATE RESOURCES ================
kubectl apply -f .\storage\storage.yml

kubectl apply -f .\database\lugx-gaming-database-secret.yml
kubectl apply -f .\database\lugx-gaming-database.yml

kubectl apply -f .\clickhouse\lugx-gaming-clickhouse-secret.yml
kubectl apply -f .\clickhouse\lugx-gaming-clickhouse-init-configmap.yml
kubectl apply -f .\clickhouse\lugx-gaming-clickhouse-mysql-interface-configmap.yml
kubectl apply -f .\clickhouse\lugx-gaming-clickhouse-mysql-user-configmap.yml
kubectl apply -f .\clickhouse\lugx-gaming-clickhouse.yml

kubectl apply -f .\lugx-gaming-games-service-api.yml
kubectl apply -f .\lugx-gaming-order-service-api.yml
kubectl apply -f .\lugx-gaming-analytics-service-api.yml

kubectl apply -f .\lugx-gaming-frontend.yml

kubectl apply -f .\ingress\ingress.yml

# =================== DATADOG ====================
helm repo add datadog https://helm.datadoghq.com
helm repo update
helm install datadog-operator datadog/datadog-operator
kubectl create secret generic datadog-secret --from-literal api-key=<api-key> #https://app.datadoghq.eu/fleet/install-agent/latest?platform=kubernetes
kubectl apply -f .\datadog\datadog-agent.yml