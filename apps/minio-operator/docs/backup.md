# Backups and Disaster Recovery

## MinIO Operator

All operators simply watch the Kubernetes API for changes to state of the objects they manage; they do not store any state themselves. As the relevant state is stored by the Kubernetes API and not in the operator Pod itself, there is no need to perform backups of operator Pods.
