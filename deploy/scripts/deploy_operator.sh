operator-sdk build quay.io/opencloudio/ibm-elastic-stack-operator:latest
docker push quay.io/opencloudio/ibm-elastic-stack-operator:latest
kubectl apply -f deploy/crds/elasticstack.ibm.com_elasticstacks_crd.yaml  --validate=false
kubectl apply -f deploy/service_account.yaml
kubectl apply -f deploy/role.yaml
kubectl apply -f deploy/role_binding.yaml
kubectl delete deployment.apps/elastic-stack-operator
kubectl apply -f deploy/operator.yaml
