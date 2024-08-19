<!-- the M-x command below will only work in emacs with the markdown module. Probably won't do anything in any other editors -->
<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Table of Contents](#table-of-contents)
- [Purpose](#purpose)
    - [Getting Started with Opal-helm Deployment](#getting-started-with-opal-helm-deployment)
        - [ArgoCD](#argocd)
    - [Deploying ArgoCD ](#deploying-argocd)
        - [Starting minikube](#starting-minikube)
        - [Setting up ArgoCD regcred](#setting-up-argocd-regcred)
        - [Install ArgoCD helm chart](#install-argocd-helm-chart)
        - [Access the ArgoCD secret](#access-the-argocd-secret)
        - [Add Repo to ArgoCD Dashboard](#add-repo-to-argocd-dashboard)
    - [Deploying OPAL](#deploying-opal)
        - [TLS certs](#tls-certs)
        - [Add docker configuration JSON](#add-docker-configuration-json)
        - [Git Sync](#git-sync)
        - [Helm install OPAL](#helm-install-opal)
        - [Patching argoCD](#patching-argocd)
        - [Important URLs](#important-urls)
    - [Nginx](#nginx)
        - [Nginx setup](#nginx-setup)
    - [Dask Gateway](#dask-gateway)
        - [Node Assignment](#node-assignment)
        - [Modifying Resource Limits](#modifying-resource-limits)
    - [Mongodb](#mongodb)
        - [Mongodb documentation](#mongodb-documentation)
        - [Mongodb configuration and user creation](#mongodb-configuration-and-user-creation)
        - [Log in as root](#log-in-as-root)
        - [Create a userAdmin](#create-a-useradmin)
        - [Create a Mongo Database](#create-a-mongo-database)
        - [Insert test data into a Database](#insert-test-data-into-a-database)
        - [Helpful Mongosh Commands](#helpful-mongosh-commands)
        - [Create a Mongo User and authentication](#create-a-mongo-user-and-authentication)
        - [MongoDB Built-in Roles](#mongodb-built-in-roles)
        - [Signing in as a user with specific roles](#signing-in-as-a-user-with-specific-roles)
    - [Prometheus Integration](#prometheus-integration)
        - [Install Prometheus](#install-prometheus)
            - [Prerequisites](#prerequisites)
            - [Installation](#installation)
            - [Usage](#usage)

<!-- markdown-toc end -->


# Purpose
This repo contains all the deployment helm charts and configuration files for deploying the Open Platform for Avionics Learning or OPAL.  
## Getting Started with Opal-helm Deployment

### ArgoCD
ArgoCD is a Kubernetes controller, responsible for continuously monitoring all running applications and comparing their live state to the desired state specified in the Git repository.

The opal team uses Argo CD to make sure our repository is fully managed and monitored for the most updated changes and features.

## Deploying ArgoCD 

The following packages are required before proceeding 
 - minikube 
    - https://minikube.sigs.k8s.io/docs/start/
- docker 
    - https://docs.docker.com/engine/install/
- kubectl 
    - https://kubernetes.io/docs/tasks/tools/
- helm 
    - https://helm.sh/docs/intro/install/

- You may need more packages depending on your current environment setup

### Starting minikube
From a terminal with administrator access run the following command:
>$minikube start

If minikube fails to start, use the minikube documentation to troubleshoot any issues 
https://minikube.sigs.k8s.io/docs/start/

### Setting up ArgoCD regcred
 change directory to the regcred-init directory and run the following command:

>$helm install argoregcred . --create-namespace -n argocd

### Install ArgoCD helm chart
now that the argoCD values are configured properly for a local deployment, helm install the argocd from the parent directory of ArgoCD repository

>$helm install argo ./chart -n argocd

### Access the ArgoCD secret
To access the password for the argocd login you will need to run the following command:
> $kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

the output from this command will be used on the argoCD dashboard interface

### Add Repo to ArgoCD Dashboard
In order to get argoCD dashboard working before applications are added, you need to start a port-forward service with kubectl:
>$kubectl port-forward service/argo-argocd-server -n argocd 8080:443

Access the argoCD interface by opening a browser and navigate to the following:
> localhost:8080

there should be a login page for argoCD
>username: **admin**
>password: output from the last section (remove the trailing '%' symbol if present)


once logged in go to the settings>repository>connect repo
Next change the connection method to :
>VIA HTTPS

Fill out the following fields:
Repository URL:
>https://github.com/309thEDDGE/opal-helm.git

Username:
> enter github user name

Password:
> enter your github token

Click the "*connect*" button at the top of the page to save the connection

If the information was entered correctly the connection status will be *Successful*

## Deploying OPAL
With argoCD running and configured properly, opal applications can be helm installed.

First close down the port-forwarding service by closing the terminal or ctl+c This will cause the browser URL to stop working.

### TLS certs
Supply TLS certs in the same directory as opal-helm/opal-setup

### Add docker configuration JSON
In order for the helm install to work properly in a local instance, it is necessary to add the docker config json file in the opal-helm/opal-setup directory.  This is needed for the helm chart to pull the appropriate image from a private repository.

### Git Sync
If enabled in the values.yaml, jupyterhub will add sidecars containers to the hub pod that will periodically pull in updates from the `opal` and `weave` repositories. 
**NOTE**: A github account and access token with repo scope is currently required to use this functionality.

To use git-sync, place your token in opal-setup, and rename it to `git-creds`. In opal-setup/values, fill in your username in jupyterhub:appValues:gitSync

### Helm install OPAL

In order to make sure opal is running properly, you need to change the branch to the specific git repo you will be working off of.  This is important for development and testing, as argo will always pull a specific branch from github.  To change the repo branch go into the values.yaml file in the opal-setup directory.

>targetRevision: "specific_branch"

Navigate to the parent opal-helm repository directory and helm install opal-setup:
>$helm install opal-setup ./opal-setup

This process can take several minutes depeneding on different variables.  Opening a watch list for the pods can be helpful in this step:
>$watch kubectl get pods -A

In order for the product to work properly you will also need to run a minikube tunnel.  Open a new browser and run the following command:

> minikube tunnel

After the status of all opal pods are running and the keycloak-setup pod is complete, open a browser to access the services.

### Patching argoCD
Applications will occasionally fail to sync following an update, there will have to be a patch applied to make sure the changes take place
> $kubectl patch Application/<failing application> \ --type json \ --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' -n argocd

### Important URLs
**Opal**
>opal-k8s.10.96.30.9.nip.io

**Argo**
>argo.10.96.30.9.nip.io/

**Keycloak**
>keycloak-k8s.10.96.30.9.nip.io

**Minio**
>minio-k8s.10.96.30.9.nip.io

**Traefik**
>traefik-k8s.10.96.30.9.nip.io

## Nginx
Nginx is being used as a file server for all of the conda packages used in Opal.

### Nginx setup
When setting up Nginx the files **must** be in the correct format. 

The expected filestructure, excluding any packages, is as follows:

```
usr
└── share
    └── nginx
        └── html
            └── condapkg
                ├── linux-64
                │   └── repodata.json
                └── noarch
                    └── repodata.json
```

To copy the files up use the following command.

```kubectl cp <path_to_condapkg> opal/<nginx-podname>:/usr/share/nginx/html```

After Jupyterhub is running, you will also need to create the conda environment by using the following command.

```conda env create -f local_channel_env.yaml```


## Dask Gateway
  
### Node Assignment

Dask gateway provides a means for users to farm out large compute tasks to scalable worker pools. By default, the kubernetes controller will schedule these workers onto any available node, potentially leading to degraded performance in user-facing services. This can be solved using kubernetes features called 'node affinity' and 'taints/tolerations', allowing us to have a separate nodepool that can only be utilized by dask's worker nodes. Some cluster-side configuration is required to make use of this functionality. The target nodes will need some sort of label to distinguish them from the rest of the cluster, as well as a taint to prevent other pods from being scheduled to these nodes. For the sake of this example, we'll use the following: 

``` yaml
labels:
    workload:dask-worker
```

``` yaml
taints:
    worker=false:NoSchedule
```

These can either be added through nodepool options through your cloud provider's CLI/Web UI, or manually per-node using `kubectl`. As cloud providers can vary, the following examples will use `kubectl`

To label nodes:
`kubectl label nodes <node-name> workload=dask-worker`

To taint nodes:
`kubectl taint nodes <node-name> worker=false:NoSchedule`

To add the required node affinity and tolerations to the worker pods, add the following to the `appValues` section of `daskGateway` in your values file:

``` yaml
gateway:
  backend:
    worker:
      extraPodConfig:
        nodeSelector:
          workload: "dask-worker"
        tolerations:
          - key: "worker"
            operator: "Equal"
            value: "false"
            effect: NoSchedule

```

### Modifying Resource Limits

Inorder to modify resource limits for dask gateway you will need to configure the values in the dask gateway helm chart values. Currently, by default they should be configured to allow the scheduler and workers 2 G of memory and one core a piece with the cluster total limits being 10 G of memory with 6 cores and 6 workers as a maximum. These values can be located at:
- gateway
  - extraConfig (This is where the cluster limits are defined)
  - backend
  
    - scheduler
    
      - cores
      - memory
    
    - worker
    
      - cores
      - memory

## Mongodb
Mongodb is a document database designed for ease of application development and scaling.  In the instance of OPAL, it is used in conjuction with pyMongo in a jupyterhub notebook to provide data analyst access to important collections within the database.

### Mongodb documentation

for reference 
> https://www.mongodb.com/docs/manual/

### Mongodb configuration and user creation

In order to add users to the Mongodb database, you will need to first create the user with the root admin.

MongoDB can be accessed on the following DNS name(s) and ports from within your cluster:

>mongo-db-mongodb.opal.svc.cluster.local

To get the root password run:
>kubectl get secret --namespace opal opal-setup-mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d

To connect to your database, and create a MongoDB client container:

>kubectl run --namespace opal mongo-db-mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image registry1.dso.mil/ironbank/bitnami/mongodb:5.0.9 --command -- bash

The terminal should change showing that the container is running

To connect to your database from outside the cluster execute the following commands:
>kubectl port-forward --namespace opal svc/mongo-db-mongodb 27017:27017 &
mongosh --host 127.0.0.1 --authenticationDatabase admin -p $MONGODB_ROOT_PASSWORD

### Log in as root
The default root user name is : *rootuser*
Then, run the following command:
>$ mongosh admin --host "opal-setup-mongodb" --authenticationDatabase admin -u rootuser

This will prompt a password that is found in the previous section.

### Create a userAdmin
It is best practice to create a user administrator in order to create database users. 

>>db.createUser(
  {
    user: "user_name_admin",
    pwd:  passwordPrompt(),   // or cleartext password
    roles: [ { role: "userAdmin", db: "admin" } ]
  }
)

### Create a Mongo Database
After logging into the container as root, If this is a fresh OPAL deployment you will need to log in as root in a  adding users.

To create a database simple run this command in the terminal:
> use database_name

This will create and empty database that will not be visible to any user until some data has been submitted

### Insert test data into a Database
For purposes of this documentation use the following entry in the command line to place some data in 

### Helpful Mongosh Commands
show dbs  // *shows all available databases the user can access, if the user is root it will also display local and admin*

>db // *prints the current database*

>use <database_name> // *switch database*

>show collections // *shows all collections from the current database*

>load("myScripts.js") // *runs a JavaScript file for data entry

>db.<name_of_collection>.find() // *shows all data in a specific collection

### Create a Mongo User and authentication

By deafault SCRAM-SHA-256 is enabled as the authentication mechanism supported by a cluster configured for authentication with MongoDB 4.0 and later.  Authentication requires a username, password, and a database name.  The default database name is "admin"

>db.createUser(
  {
    user: "user_name",
    pwd:  passwordPrompt(),   // or cleartext password
    roles: [ { role: "readWrite", db: "name_of_database" } ]
  }
)

### MongoDB Built-in Roles

Mongo grants acces to data and commands through roles.  These roles are built-in, but there is also the option to create user-defined roles.

>**read** // *provides with user to read data on all non-system collections*

>**readWrite** // *provides all the privileges of the read role and the ability to modify data on all non-system collections*

>**dbAdmin** // *provides the ability to perform adminisrative tasks such as schema-related tasks, indexing, gathering statistics. This role does NOT grant privelges for user and role management.*

>**dbOwner** // *provides the ability to perform any administrative task on the database.*

>**userAdmin** // * provides the ability to create and modify roles and users on the current database. Since the userAdmin role allows users to grant any privilege to any user, including themselves, the role also indirectly provides superuser access to either the database or, if scoped to the admin database, the cluster.*


### Signing in as a user with specific roles
To be able to securly enter a database you will need to login with the user credentials and authentication method, this can be done with the following command in pymongo:

>from pymongo import MongoClient
client = MongoClient('example.com',
                     username='user',
                     password='password',
                     authSource='the_database',
                     authMechanism='SCRAM-SHA-256')

By default mongosh excludes all db.auth() operations from the saved history

## Prometheus Integration

Prior to enabling any prometheus servicemonitors in OPAL, kube-prometheus-stack must be installed to the cluster

### Install Prometheus

#### Prerequisites

In addition to the prerequisites for a full OPAL install:

1. Clone https://github.com/309theddge/kube-prometheus
2. Clone https://github.com/309theddge/k8s-utils

#### Installation

**Registry Credentials Setup**

1. Ensure you are logged in to `registry1.dso.mil` through docker.
2. Copy `~/.docker/config.json` into `k8s-utils/regcred-init`
3. In `k8s-utils/regcred-init`, run `helm install metrics-regcred . -n monitoring --create-namespace`

**Prometheus Install**

The prometheus chart is preconfigured, so all you need to do is install it.
1. In `kube-prometheus`, run `helm install metrics . -n monitoring`. This is a very large chart, so the install may take some time

#### Usage

Once prometheus has been installed, you will be able to access the prometheus and grafana dashboards.

**Prometheus**

- K9s
    1. Type `:svc` and press enter
    2. Type `/operated` and press enter
    3. Scroll down to `prometheus-operated` and press shift-f. Ensure that `Container Port:` says `prometheus::9090`. If not, delete the line and enter `9090`
    4. Move your cursor down to "OK" and press enter
    5. You should now be able to visit `localhost:9090` in your browser and interact with the prometheus dashboard
- kubectl
    1. Run `kubectl port-forward svc/prometheus-operated 9090 -n monitoring` in your terminal
    2. You should now be able to visit `localhost:9090` in your browser and interact with the prometheus dashboard

**Grafana**

- K9s
    1. Type `:svc` and press enter
    2. Type `/grafana` and press enter
    3. Scroll down to `prometheus-grafana` and press shift-f. Ensure that `Container Port:` says `grafana::3000`. If not, delete the line and enter `3000`
    4. Move your cursor down to "OK" and press enter
    5. Type `:secret` and press enter
    6. Type `/grafana` and press enter
    7. Move your cursor to `prometheus-grafana` and press `x`
    8. Make note of `admin-user` and `admin-password`
    9. You should now be able to visit `localhost:3000` in your browser and log in to the dashboard with the username and password from the previous step
- kubectl
    1. Run `kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring` in your terminal
    2. Run `kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-user}" | base64 -d` in your terminal. Make note of the username printed
    2. Run `kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d` in your terminal. Make note of the password printed
    2. You should now be able to visit `localhost:3000` in your browser and log in to the grafana dashboard
