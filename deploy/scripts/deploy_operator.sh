kubectl apply -f deploy/crds/elasticstack.cloud.ibm.com_elasticstacks_crd.yaml  --validate=false
kubectl apply -f deploy/service_account.yaml
kubectl apply -f deploy/role.yaml
kubectl apply -f deploy/role_binding.yaml
kubectl apply -f deploy/operator.yaml
