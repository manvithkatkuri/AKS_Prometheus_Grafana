az aks get-credentials --resource-group aks-rg-manvith --name manvith-aks --overwrite-existing

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/resourcequota.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/postgres-statefulset.yaml
kubectl apply -f k8s/services.yaml
kubectl apply -f k8s/backend-a-deployment.yaml
kubectl apply -f k8s/backend-b-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/networkpolicy-*.yaml
kubectl apply -f k8s/hpa-*.yaml
