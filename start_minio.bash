
helm dependency build ./minio-operator/chart
echo
helm upgrade -i minio-operator minio-operator/chart --namespace opal --create-namespace
echo "----------------------------------------------------"
helm dependency build ./minio/chart
echo
helm upgrade -i minio-tenant minio/chart --namespace minio-tenant --create-namespace
