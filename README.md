#
# ibm-elastic-stack-operator

Operator that installs and manages Elastic Stack logging service instances. 
Each Elastic Stack instance provides visibility to system and application
logs by collecting, transforming, storing, presenting, and archiving logs in a
secure, scalable, and customizable way. 

Filebeat, Logstash, Elasticsearch, Kibana, Curator, and Nginx are the main components.

## Supported platforms

- Red Hat OpenShift Container Platforms 4.x.

## Operator versions

- 3.0.5

## Prerequisites

1. Red Hat OpenShift Container Platform 4.x must be installed.
1. Cluster Admin role for installation.
1. [IBM IAM Operator](https://github.com/IBM/ibm-iam-operator)
1. [IBM Management Ingress Operator](https://github.com/IBM/ibm-management-ingress-operator)

## Documentation

For installation and configuration, see the [IBM Cloud Platform Common Services documentation](http://ibm.biz/cpcsdocs).

### Developer guide

Information about building and testing the operator.

#### Cloning the operator repository
```
# git clone git@github.com:IBM/ibm-elastic-stack-operator.git
# cd ibm-elastic-stack-operator
```

#### Building the operator image
```
# make build
```

#### Installing the operator 
```
# make install
```

#### Uninstalling the operator
```
# make uninstall
```

#### Debugging the operator

Check the Cluster Service Version (CSV) installation status.
```
# oc get csv
# oc describe csv ibm-elastic-stack-operator.v3.0.5
```

Check the custom resource status.
```
# oc describe elasticstack logging
# oc get elasticstack logging -o yaml
```

Check the operator status and log.
```
# oc describe po -l name=ibm-elastic-stack-operator
# oc logs -f $(oc get po -l name=ibm-elastic-stack-operator -o name)
```

#### End-to-End testing that uses Operand Deployment Lifecycle Manager

For more information, see the [ODLM guide](https://github.com/IBM/operand-deployment-lifecycle-manager/blob/master/docs/install/common-service-integration.md#end-to-end-test).
