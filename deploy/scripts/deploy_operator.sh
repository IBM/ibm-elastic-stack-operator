# operator-sdk build quay.io/opencloudio/ibm-elastic-stack-operator:latest
# docker push quay.io/opencloudio/ibm-elastic-stack-operator:latest
kubectl apply -f deploy/crds/elasticstack.ibm.com_elasticstack_crd.yaml  --validate=false
kubectl apply -f deploy/service_account.yaml -n ibm-elastic-stack-operator
kubectl apply -f deploy/role.yaml -n ibm-elastic-stack-operator
kubectl apply -f deploy/role_binding.yaml -n ibm-elastic-stack-operator
kubectl delete deployment.apps/elastic-stack-operator -n ibm-elastic-stack-operator
kubectl apply -f deploy/operator.yaml -n ibm-elastic-stack-operator
