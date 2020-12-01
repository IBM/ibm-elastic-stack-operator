
# ibm-elastic-stack-operator

Operator that installs and manages Elastic Stack logging service instances. 
Each Elastic Stack instance provides visibility to system and application
logs by collecting, transforming, storing, presenting, and archiving logs in a
secure, scalable, and customizable way. 

Filebeat, Logstash, Elasticsearch, Kibana, Curator, and Nginx are the main components.

## Supported platforms

- Red Hat OpenShift Container Platforms 4.x.

## Operator versions

- 3.2.5
- 3.2.4
- 3.2.3
- 3.2.2
- 3.2.0
- 3.1.4
- 3.1.3
- 3.1.2
- 3.1.1
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
# oc describe csv ibm-elastic-stack-operator.v3.2.5
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

# Introduction to Elastic Stack Operands

Contains a fully integrated Elasticsearch solution to securely collect logs in a Kubernetes environment.

## Chart Details

This chart deploys:

  - Elasticsearch with transient or persistent data storage
  - Logstash
  - Kibana
  - Filebeat
  - Curator

Configurable features include:
  - Automated TLS configuration
  - Kibana ingress with authentication and authorization verification
  - UI navigation link to the Kibana ingress

## Configuration

### General

Parameter | Description | Default
----------|-------------|--------
`image.pullPolicy`         | The policy used by Kubernetes for images | `IfNotPresent`
`image.pullSecret.enabled` | If set to true, adds an imagePullSecret annotation to all deployments. This enables the use of private image repositories that require authentication. | `false`
`image.pullSecret.name`    | The name of the image pull secret to specify. The pull secret is a resource created by an authorized user. | `regcred`
`general.environment`      | Describes the target Kubernetes environment to enable the chart to meet specific vendor requirements. Valid values are `IBMCloudPrivate`, `Openshift`, and `Generic`. | `IBMCloudPrivate`
`general.clusterDomain`   | The value that was used during configuration installation of the Kubernetes cluster. | `cluster.local`
`general.ingressPort`      | The secure port number used to access services deployed within the Kubernetes cluster. | `8443`

### Filebeat

Parameter | Description | Default
----------|-------------|--------
`filebeat.name`             | The internal name of the Filebeat pod        | `filebeat-ds`
`filebeat.image.repository` | Full repository and path to image            | `quay.io/opencloudio/icp-filebeat-oss`
`filebeat.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`filebeat.resources.requests.memory` | The minimum memory required per pod | `64Mi`
`filebeat.image.tag`        | The version of Filebeat to deploy            | `6.6.1-build.2`
`filebeat.scope.nodes`      | One or more label key/value pairs that refine [node selection](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) for Filebeat pods| `empty (nil)`
`filebeat.scope.namespaces` | List of log namespaces to monitor upon. Logs from all namespaces will be collected if value is set to empty | `empty (nil)`
`filebeat.tolerations`      | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`filebeat.registryHostPath` | Location to store filebeat registry on the host node | `/var/lib/icp/logging/filebeat-registry/<helm-release-name>`

### Logstash

Parameter | Description | Default
----------|-------------|--------
`logstash.name`                | The internal name of the Logstash cluster    | `logstash`
`logstash.image.repository`    | Full repository and path to image            | `quay.io/opencloudio/icp-logstash-oss`
`logstash.image.tag`           | The version of Logstash to deploy            | `6.6.1-build.2`
`logstash.replicas`            | The initial pod cluster size                 | `1`
`logstash.heapSize`            | The JVM heap size to allocate to Logstash    | `512m`
`logstash.memoryLimit`         | The maximum allowable memory for Logstash. This includes both JVM heap and file system cache    | `1024Mi`
`logstash.port`                | The port on which Logstash listens for beats | `5000`
`logstash.tolerations`      | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`logstash.nodeSelector`      | Kubernetes selector that can restrict the pod to run on certain nodes | `empty (nil)`

### Kibana

Parameter | Description | Default
----------|-------------|--------
`kibana.name`                   | The internal name of the Kibana cluster                                                     | `kibana`
`kibana.image.repository`       | Full repository and path to image                                                           | `quay.io/opencloudio/icp-kibana-oss`
`kibana.image.tag`              | The version of Kibana to deploy                                                             | `6.6.1-build.2`
`kibana.replicas`               | The initial pod cluster size                                                                | `1`
`kibana.internal`               | The port for Kubernetes-internal networking                                                 | `5601`
`kibana.external`               | The port used by external users                                                             | `31601`
`kibana.maxOldSpaceSize`        | Maximum old space size (in MB) of the V8 Javascript engine                                  | `1536`
`kibana.memoryLimit`            | The maximum allowable memory for Kibana                                                     | `2048Mi`
`kibana.initImage.repository`   | Full repository and path to initialization image                                            | `quay.io/opencloudio/curl`
`kibana.initImage.tag`          | The version of the initialization image to deploy                                           | `4.2.0-build.4`
`kibana.routerImage.repository` | Full repository and path to the image used as a secure proxy (only used when `kibana.access` is `ingress`) | `quay.io/opencloudio/icp-management-ingress`
`kibana.routerImage.tag`        | The version of the secure proxy image to deploy                                             | `2.5.3`
`kibana.init.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`kibana.init.resources.requests.memory` | The minimum memory required per pod | `64Mi`
`kibana.routerImage.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`kibana.routerImage.resources.requests.memory` | The minimum memory required per pod | `64Mi`
`kibana.tolerations`       | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`kibana.nodeSelector`      | Kubernetes selector that can restrict the pod to run on certain nodes | `empty (nil)`
`kibana.access`            | How access to kibana is achieved, either `loadBalancer` or `ingress` | `loadBalancer`
`kibana.ingress.path`      | Path used when access is `ingress` | `/tenantA/kibana`
`kibana.ingress.labels.inmenu` | Determines whether a link should be added to the UI navigation menu. | `true`
`kibana.ingress.labels.target` | If provided, the UI navigation link will launch into a new window. | `logging-tenantA`
`kibana.ingress.annotations.name` | The UI navigation link display name. | `Logging - Tenant A`
`kibana.ingress.annotations.id` | The parent navigation menu item. | `add-ons`
`kibana.ingress.annotations.roles` | The roles able to see the UI navigation link. | `ClusterAdministrator,Administrator,Operator,Viewer`
`kibana.ingress.annotations.ui.icp.ibm.com/tenant` | The teams able to see the UI navigation link. | `tenantAdev,tenantAsupport (tenantA examples)`
`kibana.security.authc.enabled` | Determines whether login is required before access is allowed. | `false`
`kibana.security.authz.enabled` | Determines whether namespace access is required before access is allowed (requires `authc.enabled: true`). | `false`
`kibana.security.authz.icp.authorizedNamespaces` | List of namespaces that allow access. | `(tenantA examples)`

### Elasticsearch

Parameter | Description | Default
----------|-------------|--------
`elasticsearch.name`                        | A name to uniquely identify this Elasticsearch deployment                                | `elasticsearch`
`elasticsearch.image.repository`            | Full repository and path to Elasticsearch image                                          | `quay.io/opencloudio/icp-elasticsearch-oss`
`elasticsearch.image.tag`                   | The version of Elasticsearch to deploy                                                   | `6.6.1-build.2`
`elasticsearch.initImage.repository`        | Full repository and path to the image used during bringup                                | `quay.io/opencloudio/icp-initcontainer`
`elasticsearch.initImage.tag`               | The version of init-container image to use                                               | `1.0.0-build.4`
`elasticsearch.pkiInitImage.repository`     | Full repository and path to the image for public key infrastructure (PKI) initialization | `quay.io/opencloudio/logging-pki-init`
`elasticsearch.pkiInitImage.tag`            | Version of the image for public key infrastructure (PKI) initialization                  | `2.3.0-build.3`
`elasticsearch.pkiInitImage.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`elasticsearch.pkiInitImage.resources.requests.memory` | The minimum memory required per pod | `64Mi`
`elasticsearch.routerImage.repository`      | Full repository and path to the image providing proxy support for role-based access control (RBAC) | `quay.io/opencloudio/icp-management-ingress`
`elasticsearch.routerImage.tag`             | Version of the image for providing role-based access control (RBAC) support                        | `2.5.3`
`elasticsearch.routerImage.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`elasticsearch.routerImage.resources.requests.memory` | The minimum memory required per pod | `64Mi`
`elasticsearch.internalPort`                | The port on which the full Elasticsearch cluster will communicate                        | `9300`
`elasticsearch.security.authc.enabled` | Determines whether mutual certificate-based authentication is required before access is allowed. | `true`
`elasticsearch.security.authc.provider` | Elastic stack plugin to provide TLS. Only acceptable value `icp` | `icp`
`elasticsearch.security.authz.enabled` | Determines whether authenticated user query results are filtered by namespace access. | `false`
`elasticsearch.data.name`                 | The internal name of the data node cluster                       | `data`
`elasticsearch.data.replicas`             | The number of initial pods in the data cluster                   | `2`
`elasticsearch.data.heapSize`             | The JVM heap size to allocate to each Elasticsearch data pod     | `4000m`
`elasticsearch.data.memoryLimit`          | The maximum memory (including JVM heap and file system cache) to allocate to each Elasticsearch data pod | `7000Mi`
`elasticsearch.data.antiAffinity`         | Whether Kubernetes "may" (`soft`) or "must not" (`hard`) [deploy data pods onto the same node](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/) | `hard`
`elasticsearch.data.storage.size`         | The minimum [size of the persistent volume](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/scheduling/resources.md#resource-quantities)    | `30Gi`
`elasticsearch.data.storage.accessModes`  | [See official documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)   | `ReadWriteOnce`
`elasticsearch.data.storage.storageClass` | [See official documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#storageclasses) | `""`
`elasticsearch.data.storage.persistent`   | Set to `false` for non-production or trial-only deployment                                                   | `true`
`elasticsearch.data.storage.useDynamicProvisioning` | Set to `true` to use GlusterFS or other dynamic storage provisioner                                | `false`
`elasticsearch.data.storage.selector.label` | A label associated with the target persistent volume (ignored if using dynamic provisioning) | `""`
`elasticsearch.data.storage.selector.value` | The value of the label associated with the target persistent volume (ignored if using dynamic provisioning) | `""`
`elasticsearch.data.tolerations`       | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`elasticsearch.data.nodeSelector`      | Kubernetes selector that can restrict the pod to run on certain nodes | `empty (nil)`

### Security

Parameter | Description | Default
----------|-------------|--------
`security.ca.keystore.password`   | Keystore password for the Certificate Authority (CA)                              | `changeme`
`security.ca.truststore.password` | Truststore password for the CA                                                    | `changeme`
`security.ca.origin`              | Specifies which CA to to use for generating certs. There are two accepted values: <ul><li> `external`: use existing CA stored in a Kubernetes secret under the same namespace as the Helm release</li><li> `internal`: generate and use new self-signed CA as part of the Helm release</li></ul>  | `internal`
`security.ca.external.secretName` | Name of Kubernetes secret that stores the external CA. The secret needs to be under the same namespace as the Helm release  | `cluster-ca-cert`
`security.ca.external.certFieldName` | Field name (key) within the specified Kubernetes secret that stores CA cert. If signing cert is used, the complete trust chain (root CA and signing CA) needs to be included in this file | `tls.crt`
`security.ca.external.keyFieldName` | Field name (key) within the specified Kubernetes secret that stores CA private key | `tls.key`
`security.app.keystore.password`  | Keystore password for logging service components (such as Elasticsearch, Kibana)  | `changeme`
`security.tls.version`  | The version of TLS required, always `TLSv1.2`  | `TLSv1.2`

### Curator

The curator is a tool to clean out old log indices from Elasticsearch. More information is available through [Elastic's official documentation](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/index.html).

Parameter | Description | Default
----------|-------------|--------
`curator.name`              | A name to uniquely identify this curator deployment     | `curator`
`curator.image.repository`  | Full repository and path to image                       | `quay.io/opencloudio/indices-cleaner`
`curator.image.tag`         | The version of curator image to deploy                  | `1.2.0-build.3`
`curator.schedule`          | A [Linux cron schedule](https://en.wikipedia.org/wiki/Cron#CRON_expression), identifying when the curator process should be launched. The default schedule runs at midnight. | `59 23 * * *`
`curator.log.unit`          | The [age unit type](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/filtertype_age.html) to retain application logs | `days`
`curator.log.count`         | The number of `curator.log.unit`s to retain application logs | `1`
`curator.va.unit`      | The [age unit type](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/filtertype_age.html) to retain Vulnerability Advisor logs. | `days`
`curator.va.count`     | The number of `curator.va.unit`s to retain Vulnerability Advisor logs. | `90`
`curator.auditLog.unit`      | The [age unit type](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/filtertype_age.html) to retain audit logs. | `days`
`curator.auditLog.count`     | The number of `curator.auditLog.unit`s to retain audit logs. | `1`
`curator.tolerations`       | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`curator.nodeSelector`      | Kubernetes selector that can restrict the pod to run on certain nodes | `empty (nil)`
`curator.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`curator.resources.requests.memory` | The minimum memory required per pod | `64Mi`

## Installing and Removing the Chart

### Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release stable/ibm-icplogging
```

The command deploys ibm-icplogging on the Kubernetes cluster with default values. The configuration section lists the parameters that can be configured during installation.

### Uninstalling the Chart

To uninstall/delete the my-release deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

# Limitations

## Prerequisites

* Kubernetes 1.9 or higher
* Tiller 2.7.2 or higher
* PV provisioner support in the underlying infrastructure

### Resources Required

* Elasticsearch resource needs can vary widely based on your cluster and workload details. Please read the capacity planning guide in the [IBM Cloud Platform Common Services documentation](http://ibm.biz/cpcsdocs) for helpful information to plan the necessary resources.
* See [Storage](#storage)

# PodSecurityPolicy Requirements
# SecurityContextConstraints Requirements

## Storage

### Static Persistent Volumes
A persistent volume is required if no dynamic provisioning has been set up. An example is below. See [official Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) for more.


>```yaml
>kind: PersistentVolume
>apiVersion: v1
>metadata:
>  name: es-data-1
>  labels:
>    type: local
>spec:
>  storageClassName: logging-storage-datanode
>  capacity:
>    storage: 150Gi
>  accessModes:
>    - ReadWriteOnce
>  hostPath:
>    path: "/nfsdata/logging/1"
>  persistentVolumeReclaimPolicy: Recycle
>```

### Dynamicly Provisioned Persistent Volumes
Please see documents of the underlying container platform (such as Redhat Openshift). If `elasticsearch.data.storage.storageClass` not specified, default storage provisioner configured for the cluster will be used .
