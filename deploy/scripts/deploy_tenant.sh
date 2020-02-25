label node/ip-10-0-132-247.ec2.internal tenant=a

kubectl create ns tenant-a-elasticstack
oc adm policy add-scc-to-user ibm-privileged-scc system:serviceaccounttenant-a-elasticstack:default
oc adm policy add-scc-to-user privileged system:serviceaccounttenant-a-elasticstack:default
oc policy add-role-to-user ibm-privileged-clusterrole system:serviceaccount:tenant-a-elasticstack:default
kt clusterrolebinding ibm-privileged-psp-users

kubectl get secret infra-registry-key -o yaml -n kube-system > infra-registry-key.yaml

sed -i '' '/^[[:space:]]*kubectl/d' infra-registry-key.yaml
sed -i '' '/^[[:space:]]*{"apiVersion/d' infra-registry-key.yaml
sed -i '' '/^[[:space:]]*creationTimestamp/d' infra-registry-key.yaml
sed -i '' '/^[[:space:]]*namespace/d' infra-registry-key.yaml
sed -i '' '/^[[:space:]]*resourceVersion/d' infra-registry-key.yaml
sed -i '' '/^[[:space:]]*selfLink/d' infra-registry-key.yaml
sed -i ''  '/^[[:space:]]*uid/d' infra-registry-key.yaml

kubectl apply -f infra-registry-key.yaml -n tenant-a-elasticstack
rm -f infra-registry-key.yaml

kubectl get secret platform-oidc-credentials -o yaml -n kube-system > platform-oidc-credentials.yaml

sed -i '' '/^[[:space:]]*creationTimestamp/d' platform-oidc-credentials.yaml
sed -i '' '/^[[:space:]]*namespace/d' platform-oidc-credentials.yaml
sed -i '' '/^[[:space:]]*resourceVersion/d' platform-oidc-credentials.yaml
sed -i '' '/^[[:space:]]*selfLink/d' platform-oidc-credentials.yaml
sed -i '' '/^[[:space:]]*uid/d' platform-oidc-credentials.yaml

kubectl apply -f platform-oidc-credentials.yaml -n tenant-a-elasticstack

rm -f platform-oidc-credentials.yaml

kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "infra-registry-key"}]}'  -n tenant-a-elasticstack


kubectl apply -f deploy/crds/tenant-a.sample.yaml  --validate=false

