# What's new
* End-to-end TLS is now supported on both `amd64` and `ppc64le` architectures.
* Support for private image repositories that require authentication via imagePullSecrets.
* Support for deployment onto Openshift.
* Role-based access proxy for managed deployment.
* More options for data storage.


# Fixes
* Fixed bug when enabling TLS with a non-default Elasticsearch internal port number.
* All images migrated to CentOS 7 with latest packages.


# Prerequisites
1. Kubernetes 1.9 or higher, with Tiller 2.9.1 or higher.
1. Persistent volumes for each of the Elasticsearch data pods, or dynamic provisioning.


# Known issues
1. When attempting to reach a TLS-enabled Kibana over unsecured HTTP it will redirect the browser to `https://0.0.0.0`. To avoid this, specify `https` when connecting to a TLS-enabled Kibana.


# Version history
| Chart | Date     | Details                           |
| ----- | -------- | --------------------------------- |
| 1.0.0 | May 2018 | First full release                |
| 1.0.1 | Jun 2018 | Bug fix                           |
| 2.0.0 | Aug 2018 | New release for ICP 3.1           |

# Documentation

# Breaking Changes
