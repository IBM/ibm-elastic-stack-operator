kubectl delete -f deploy/operator.yaml -n ibm-elastic-stack-operator
kubectl delete -f deploy/role_binding.yaml -n ibm-elastic-stack-operator
kubectl delete -f deploy/role.yaml -n ibm-elastic-stack-operator
kubectl delete -f deploy/service_account.yaml -n ibm-elastic-stack-operator
