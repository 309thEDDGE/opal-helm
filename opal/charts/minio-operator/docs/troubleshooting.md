# Troubleshooting

## General

The MinIO operator consists of a single Pod in the `minio-operator` namespace. The Pod has unique labels and can be targeted for troubleshooting commands directly through them as such:

### Get Pod status

`kubectl get pod -l app.kubernetes.io/name=minio-operator -n minio-operator`

`kubectl describe pod -l app.kubernetes.io/name=minio-operator -n minio-operator`

### Get Pod logs

`kubectl logs -l app.kubernetes.io/name=minio-operator -n minio-operator`
