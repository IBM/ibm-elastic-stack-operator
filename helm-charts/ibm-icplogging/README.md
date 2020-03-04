## Introduction

Contains a fully integrated Elasticsearch solution to securely collect logs in a Kubernetes environment.

## Chart Details

This chart deploys:
  - Elasticsearch data, client and master workloads
  - Elasticsearch data node StatefulSet, requiring a persistent volume
  - Logstash workload
  - Kibana workload
  - Filebeat daemonset

It optionally deploys:
  - Automated TLS configuration
  - Kibana ingress with authentication and authorization verification
  - UI navigation link to the Kibana ingress

## Resources Required

* Elasticsearch resource needs can vary widely based on your cluster and workload details. Please read the capacity planning guide in the [Knowledge Center](https://www.ibm.com/support/knowledgecenter/en/SSBS6K/product_welcome_cloud_private.html) for helpful information to plan the necessary resources.
* See [Storage](#storage)


## Prerequisites

* Kubernetes 1.9 or higher
* Tiller 2.7.2 or higher
* PV provisioner support in the underlying infrastructure


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


## Configuration

### General

Parameter | Description | Default
----------|-------------|--------
`image.pullPolicy`         | The policy used by Kubernetes for images | `IfNotPresent`
`image.pullSecret.enabled` | If set to true, adds an imagePullSecret annotation to all deployments. This enables the use of private image repositories that require authentication. | `false`
`image.pullSecret.name`    | The name of the image pull secret to specify. The pull secret is a resource created by an authorized user. | `regcred`
`general.environment`      | Describes the target Kubernetes environment to enable the chart to meet specific vendor requirements. Valid values are `IBMCloudPrivate`, `Openshift`, and `Generic`. | `IBMCloudPrivate`
`general.clusterDomain`   | The value that was used during configuration installation of IBM Cloud Private. The chart default corresponds to IBM Cloud Private default. | `cluster.local`
`general.ingressPort`      | The secure port number used to access services deployed within the IBM Cloud Private cluster. | `8443`

### Filebeat

Parameter | Description | Default
----------|-------------|--------
`filebeat.name`             | The internal name of the Filebeat pod        | `filebeat-ds`
`filebeat.image.repository` | Full repository and path to image            | `ibmcom/icp-filebeat`
`filebeat.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`filebeat.resources.requests.memory` | The minimum memory required per pod | `64Mi`
`filebeat.image.tag`        | The version of Filebeat to deploy            | `6.6.1`
`filebeat.scope.nodes`      | One or more label key/value pairs that refine [node selection](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) for Filebeat pods| `empty (nil)`
`filebeat.scope.namespaces` | List of log namespaces to monitor upon. Logs from all namespaces will be collected if value is set to empty | `empty (nil)`
`filebeat.tolerations`      | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`filebeat.registryHostPath` | Location to store filebeat registry on the host node | `/var/lib/icp/logging/filebeat-registry/<helm-release-name>`

### Logstash

Parameter | Description | Default
----------|-------------|--------
`logstash.name`                | The internal name of the Logstash cluster    | `logstash`
`logstash.image.repository`    | Full repository and path to image            | `ibmcom/icp-logstash`
`logstash.image.tag`           | The version of Logstash to deploy            | `6.6.1`
`logstash.replicas`            | The initial pod cluster size                 | `1`
`logstash.heapSize`            | The JVM heap size to allocate to Logstash    | `512m`
`logstash.memoryLimit`         | The maximum allowable memory for Logstash. This includes both JVM heap and file system cache    | `1024Mi`
`logstash.port`                | The port on which Logstash listens for beats | `5000`
`logstash.probe.enabled`       | Enables the [liveness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) for Logstash. Logstash instance is considered not alive when: <ul><li>logstash endpoint is not available for  `logstash.probe.periodSeconds` * `logstash.probe.maxUnavailablePeriod`, or</li><li> processed event count is smaller than `logstash.probe.minEventsPerPeriod` within `logstash.probe.periodSeconds`</li></ul> | `false`
`logstash.probe.periodSeconds` | Seconds probe will wait before calling Logstash endpoint for status again | `60`
`logstash.probe.minEventsPerPeriod`   | Logstash instance is considered healthy if number of log events processed is greater than `logstash.probe.minEventsPerPeriod` within `logstash.probe.periodSeconds` | `1`
`logstash.probe.maxUnavailablePeriod` | Logstash instance is considered unhealthy after API endpoint is unavailable for `logstash.probe.periodSeconds` * `logstash.probe.maxUnavailablePeriod` seconds | `5`
`logstash.probe.image.repository`     | Full repository and path to image | `ibmcom/logstash-liveness-probe`
`logstash.probe.image.tag`            | Image version                     | `1.0.0`
`logstash.probe.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`logstash.probe.resources.requests.memory` | The minimum memory required per pod | `64Mi`
`logstash.tolerations`      | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`logstash.nodeSelector`      | Kubernetes selector that can restrict the pod to run on certain nodes | `empty (nil)`

### Kibana

Parameter | Description | Default
----------|-------------|--------
`kibana.name`                   | The internal name of the Kibana cluster                                                     | `kibana`
`kibana.image.repository`       | Full repository and path to image                                                           | `ibmcom/icp-kibana`
`kibana.image.tag`              | The version of Kibana to deploy                                                             | `6.6.1`
`kibana.replicas`               | The initial pod cluster size                                                                | `1`
`kibana.internal`               | The port for Kubernetes-internal networking                                                 | `5601`
`kibana.external`               | The port used by external users                                                             | `31601`
`kibana.maxOldSpaceSize`        | Maximum old space size (in MB) of the V8 Javascript engine                                  | `1024`
`kibana.memoryLimit`            | The maximum allowable memory for Kibana                                                     | `1536Mi`
`kibana.initImage.repository`   | Full repository and path to initialization image                                            | `ibmcom/curl`
`kibana.initImage.tag`          | The version of the initialization image to deploy                                           | `4.2.0-build.2`
`kibana.routerImage.repository` | Full repository and path to the image used as a secure proxy (only used when `kibana.access` is `ingress`) | `ibmcom/icp-management-ingress`
`kibana.routerImage.tag`        | The version of the secure proxy image to deploy                                             | `2.2.1`
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
`kibana.security.authc.enabled` | Determines whether IBM Cloud Private login is required before access is allowed. | `false`
`kibana.security.authz.enabled` | Determines whether namespace access is required before access is allowed (requires `authc.enabled: true`). | `false`
`kibana.security.authz.icp.authorizedNamespaces` | List of namespaces that allow access. | `(tenantA examples)`

### Elasticsearch&mdash;General settings

Parameter | Description | Default
----------|-------------|--------
`elasticsearch.name`                        | A name to uniquely identify this Elasticsearch deployment                                | `elasticsearch`
`elasticsearch.image.repository`            | Full repository and path to Elasticsearch image                                          | `ibmcom/icp-elasticsearch`
`elasticsearch.image.tag`                   | The version of Elasticsearch to deploy                                                   | `6.6.1`
`elasticsearch.initImage.repository`        | Full repository and path to the image used during bringup                                | `ibmcom/icp-initcontainer`
`elasticsearch.initImage.tag`               | The version of init-container image to use                                               | `1.0.0-f3`
`elasticsearch.pkiInitImage.repository`     | Full repository and path to the image for public key infrastructure (PKI) initialization | `ibmcom/logging-pki-init`
`elasticsearch.pkiInitImage.tag`            | Version of the image for public key infrastructure (PKI) initialization                  | `2.3.0`
`elasticsearch.pkiInitImage.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`elasticsearch.pkiInitImage.resources.requests.memory` | The minimum memory required per pod | `64Mi`
`elasticsearch.routerImage.repository`      | Full repository and path to the image providing proxy support for role-based access control (RBAC) | `ibmcom/icp-management-ingress`
`elasticsearch.routerImage.tag`             | Version of the image for providing role-based access control (RBAC) support                        | `2.4.0`
`elasticsearch.routerImage.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`elasticsearch.routerImage.resources.requests.memory` | The minimum memory required per pod | `64Mi`
`elasticsearch.internalPort`                | The port on which the full Elasticsearch cluster will communicate                        | `9300`
`elasticsearch.security.authc.enabled` | Determines whether mutual certificate-based authentication is required before access is allowed. | `true`
`elasticsearch.security.authc.provider` | Elastic stack plugin to provide TLS. Acceptable values are `searchguard-tls` or `xpack`: <ul><li>`xpack` requires an Elastic license; see [official documentation](https://www.elastic.co/guide/en/kibana/)</li><li> `searchguard-tls` leverages the community-edition features of SearchGuard; see [official documentation](https://github.com/floragunncom/search-guard-ssl)</li></ul> | `searchguard-tls`
`elasticsearch.security.authz.enabled` | Determines whether authenticated user query results are filtered by namespace access. | `false`

### Elasticsearch&mdash;Client node

Parameter | Description | Default
----------|-------------|--------
`elasticsearch.client.name`         | The internal name of the client node cluster                       | `client`
`elasticsearch.client.replicas`     | The number of initial pods in the client cluster                   | `1`
`elasticsearch.client.serviceType`  | The way in which the client service should be published. [See official documentation.](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services---service-types) | `ClusterIP`
`elasticsearch.client.heapSize`     | The JVM heap size to allocate to each Elasticsearch client pod     | `1024m`
`elasticsearch.client.memoryLimit`  | The maximum memory (including JVM heap and file system cache) to allocate to each Elasticsearch client pod | `1536Mi`
`elasticsearch.client.restPort`     | The port to which the client node will bind the REST APIs          | `9200`
`elasticsearch.client.antiAffinity` | Whether Kubernetes "may" (`soft`) or "must not" (`hard`) [deploy client pods onto the same node](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/) | `soft`
`elasticsearch.client.tolerations`       | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`elasticsearch.client.nodeSelector`      | Kubernetes selector that can restrict the pod to run on certain nodes | `empty (nil)`

### Elasticsearch&mdash;Master node

Parameter | Description | Default
----------|-------------|--------
`elasticsearch.master.name`         | The internal name of the master node cluster                       | `master`
`elasticsearch.master.replicas`     | The number of initial pods in the master cluster                   | `1`
`elasticsearch.master.heapSize`     | The JVM heap size to allocate to each Elasticsearch master pod     | `1024`
`elasticsearch.master.memoryLimit`  | The maximum memory (including JVM heap and file system cache) to allocate to each Elasticsearch master pod | `1536Mi`
`elasticsearch.master.antiAffinity` | Whether Kubernetes "may" (`soft`) or "must not" (`hard`) [deploy master pods onto the same node](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/) | `soft`
`elasticsearch.master.tolerations`       | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`elasticsearch.master.nodeSelector`      | Kubernetes selector that can restrict the pod to run on certain nodes | `empty (nil)`

### Elasticsearch&mdash;Data node

Parameter | Description | Default
----------|-------------|--------
`elasticsearch.data.name`                 | The internal name of the data node cluster                       | `data`
`elasticsearch.data.replicas`             | The number of initial pods in the data cluster                   | `2`
`elasticsearch.data.heapSize`             | The JVM heap size to allocate to each Elasticsearch data pod     | `2048m`
`elasticsearch.data.memoryLimit`          | The maximum memory (including JVM heap and file system cache) to allocate to each Elasticsearch data pod | `4096Mi`
`elasticsearch.data.antiAffinity`         | Whether Kubernetes "may" (`soft`) or "must not" (`hard`) [deploy data pods onto the same node](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/) | `hard`
`elasticsearch.data.storage.size`         | The minimum [size of the persistent volume](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/scheduling/resources.md#resource-quantities)    | `10Gi`
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

### XPack

XPack is a [separately-licensed feature](https://www.elastic.co/products/x-pack) of Elastic products. Please see official documentation for more information. Without a license the features are only enabled for a trial basis, and by default the XPack features are disabled in this chart.

_Note: All X-Pack features&mdash;including security and authentication services&mdash;are standalone. There is no integration with other authentication services._

Parameter | Description | Default
----------|-------------|--------
`xpack.monitoring` | [Link to official documentation](https://www.elastic.co/guide/en/kibana/6.6/xpack-monitoring.html)     | `true`
`xpack.graph`      | [Link to official documentation](https://www.elastic.co/guide/en/kibana/6.6/xpack-graph.html)          | `false`
`xpack.reporting`  | [Link to official documentation](https://www.elastic.co/guide/en/kibana/6.6/xpack-reporting.html)      | `false`
`xpack.ml`         | [Link to official documentation](https://www.elastic.co/guide/en/kibana/6.6/xpack-ml.html)             | `false`
`xpack.watcher`    | [Link to official documentation](https://www.elastic.co/guide/en/x-pack/6.6/how-watcher-works.html)    | `false`
`xpack.license.source`              | Determines which xpack license will be used. The chart release will generate a license if set to `selfGenerated`. Existing licenses will be loaded from secret if set to `secret` | `selfGenerated`
`xpack.license.selfGenerated.type`  | Only effective if `xpack.license.source` set to `selfGenerated`. A `trial` or `basic` license will be generated. Refer to [official documentation](https://www.elastic.co/guide/en/elastic-stack-overview/6.6/license-management.html) | `basic`
`xpack.license.secret.secretName`  | Name of the secret from which Elastic license file will be loaded. The secret need to be in the same namespace as the chart release. Only effective if `xpack.license.source` set to `secret` | `empty (nil)`
`xpack.license.secret.fieldName`  | Name of the secret field (key) from which Elastic license file will be loaded. Only effective if `xpack.license.source` set to `secret` | `empty (nil)`

### Curator

The curator is a tool to clean out old log indices from Elasticsearch. More information is available through [Elastic's official documentation](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/index.html).

Parameter | Description | Default
----------|-------------|--------
`curator.name`              | A name to uniquely identify this curator deployment     | `curator`
`curator.image.repository`  | Full repository and path to image                       | `ibmcom/indices-cleaner`
`curator.image.tag`         | The version of curator image to deploy                  | `1.2.0`
`curator.schedule`          | A [Linux cron schedule](https://en.wikipedia.org/wiki/Cron#CRON_expression), identifying when the curator process should be launched. The default schedule runs at midnight. | `59 23 * * *`
`curator.log.unit`          | The [age unit type](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/filtertype_age.html) to retain application logs | `days`
`curator.log.count`         | The number of `curator.log.unit`s to retain application logs | `1`
`curator.monitoring.unit`   | The [age unit type](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/filtertype_age.html) to retain monitoring logs | `days`
`curator.monitoring.count`  | The number of `curator.monitoring.unit`s to retain monitoring logs | `7`
`curator.watcher.unit`      | The [age unit type](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/filtertype_age.html) to retain watcher logs | `days`
`curator.watcher.count`     | The number of `curator.watcher.unit`s to retain watcher logs | `1`
`curator.va.unit`      | The [age unit type](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/filtertype_age.html) to retain Vulnerability Advisor logs. This setting only applies to the instance of Logging installed with IBM Cloud Private and used by Vunlerability Advisor. | `days`
`curator.va.count`     | The number of `curator.va.unit`s to retain Vulnerability Advisor logs. This setting only applies to the instance of Logging installed with IBM Cloud Private and used by Vunlerability Advisor. | `90`
`curator.auditLog.unit`      | The [age unit type](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/filtertype_age.html) to retain audit logs. This setting only applies to the instance of Logging installed with IBM Cloud Private and used by Audit Logging. | `days`
`curator.auditLog.count`     | The number of `curator.auditLog.unit`s to retain audit logs. This setting only applies to the instance of Logging installed with IBM Cloud Private and used by Audit Logging. | `1`
`curator.tolerations`       | Kubernetes tolerations that can allow the pod to run on certain nodes | `empty (nil)`
`curator.nodeSelector`      | Kubernetes selector that can restrict the pod to run on certain nodes | `empty (nil)`
`curator.resources.limits.memory` | The maximum memory allowed per pod    | `256Mi`
`curator.resources.requests.memory` | The minimum memory required per pod | `64Mi`

## Storage

A persistent volume is required if no dynamic provisioning has been set up. See product documentation on this [Setting up dynamic provisioning](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.2/manage_cluster/cluster_storage.html). An example is below. See [official Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) for more.

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

## Limitations

* All X-Pack features&mdash;including security and authentication services&mdash;are standalone. There is no integration with other authentication services.

Please refer to the knowledge center for more information about the features and limitations.

## Troubleshooting

### Security Policies

**Symptom:** After deploying the helm chart, none of the pods are in ready state. After running the command `kubectl describe pod <pod_name>` the "Events" section contains text such as `unable to validate against any pod security policy`, `Privileged containers are not allowed`, or `Invalid value: "IPC_LOCK": capability may not be added`.

**Cause:** The error indicates that the Kubernetes service account is not permitted to deploy into the target namespace any pods requiring the `IPC_LOCK` privilege.

**Explanation:** Some deployment types in Kubernetes are queued and fulfilled asynchronously. When Kubernetes executes the queued deployment, however, it does so in the context of its internal _service account_ instead of using the security context of the user that invoked the deployment originally. (See [Kubernetes issue 55973](https://github.com/kubernetes/kubernetes/issues/55973) for the public discussion.)

**Resolution:** Depending on your environment, one of the following may resolve the problem.

1. If you do not have permission to change privileges yourself, ask an administrator to add the `IPC_LOCK` privilege for the target namespace to the _service account's_ `PodSecurityPolicy`.
2. If you are able to modify security policies, the steps below describe one way to enable the deployment. Your environment may require more fine-grained policy changes.
   1. Run `kubectl edit clusterrolebindings ibm-privileged-psp-users`. This will open the contents of the file in a `vi` editor.
   2. Append your namespace to the list. For example, if your namespace is named `test`, then it might look like the following:
      ```
      - apiGroup: rbac.authorization.k8s.io
        kind: Group
        name: system:serviceaccounts:test
      ```
   3. Save the change and close the editor. Kubernetes will automatically apply the updated configuration.

### Invalid DNS

**Symptom:** The Kibana status page reports `Elasticsearch plugin status is red`, and when you run `kubectl describe deploy <deployment_name>` you see an error message that contains `spec.hostname: Invalid value`.

**Cause:** The user specified an invalid value for one or more of the `name` keys (e.g. `kibana.name`) in the Helm chart.

**Explanation:** The deployment name for a Kubernetes pod also resolves as its hostname within the network. As such, the deployment name must conform to DNS rules, described by Kubernetes this way: `a DNS-1123 label must consist of lower case alphanumeric characters or '-', and must start and end with an alphanumeric character (e.g. 'my-name', or '123-abc', regex used for validation is 'a-z0-9?')`.

**Resolution:** Delete the deployment, and reinstall with name values that conform to the rules as required by Kubernetes.

### PodSecurityPolicy Requirements
