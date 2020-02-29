kubectl delete elasticstack.elasticstack.cloud.ibm.com/logging
sleep 30
kubectl apply -f deploy/crds/managed-stack.yaml  --validate=false