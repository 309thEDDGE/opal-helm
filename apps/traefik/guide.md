add the eks repo

helm repo add eks https://aws.github.io/eks-charts

install load balancer controller

helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=<cluster-name> --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

check if the load balance controller is installed

kubectl get deployment -n kube-system aws-load-balancer-controller