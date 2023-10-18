# MinIO Operator

## Overview

MinIO is an object storage application that is fully compatible with the S3 API. Deploying MinIO enables portability for apps that need S3 as a backend so they can run outside of an AWS environment.

The MinIO operator is a [Kubernetes Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) used to manage the deployment of MinIO tenants into the cluster.

## Dependencies

This chart does not technically depend on anything, however if you want to actually deploy an instance of MinIO into the cluster you will need to also use the [minio](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio) Big Bang package. Put another way, the MinIO package depends on this one to deploy an instance of MinIO in Kubernetes.

## How it works

This chart deploys an instance of the MinIO operator in the `minio-operator` namespace. To deploy MinIO, `minioOperator` and `minio` must both be enabled through the addons functionality in the Big Bang [values.yaml](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/chart/values.yaml). This will create an instance of MinIO in the `minio` namespace.

## External Resources

- Source code & docs ([GitHub](https://github.com/minio/operator))
- [OperatorHub](https://operatorhub.io/operator/minio-operator)
