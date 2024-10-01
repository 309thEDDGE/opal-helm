<!-- the M-x command below will only work in emacs with the markdown module. Probably won't do anything in any other editors -->
<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [OPAL-HELM](#opal-helm)
  - [Getting Started with Opal-helm Deployment](#getting-started-with-opal-helm-deployment)
    - [Prerequisites](#prerequisites)
      - [Additional Prerequisites for Local Deployment](#additional-prerequisites-for-local-deployment)
      - [Optional Extras](#optional-extras)
    - [Local Installation](#local-installation)
      - [Starting Minikube](#starting-minikube)
      - [ArgoCD](#argocd)
        - [Setting up ArgoCD regcred](#setting-up-argocd-regcred)
        - [Install ArgoCD helm chart](#install-argocd-helm-chart)
        - [Access the ArgoCD secret](#access-the-argocd-secret)
        - [Accessing the ArgoCD Dashboard](#accessing-the-argocd-dashboard)
  - [Deploying OPAL](#deploying-opal)
    - [TLS Certificates](#tls-certificates)
      - [For Live/Airgapped Environments:](#for-liveairgapped-environments)
      - [For Local Deployments (must be internet-connected):](#for-local-deployments-must-be-internet-connected)
      - [Install Certificates](#install-certificates)
    - [Image Registry Authentication](#image-registry-authentication)
      - [Install dockerconfig.json](#install-dockerconfigjson)
    - [Git Sync](#git-sync)
    - [Install the OPAL helm chart](#install-the-opal-helm-chart)
      - [Configuring OPAL](#configuring-opal)
      - [Installation](#installation)
    - [First Login](#first-login)
      - [Set Permissions](#set-permissions)
      - [Creating a new User](#creating-a-new-user)
    - [Troubleshooting](#troubleshooting)
      - [Failed Initialization or Pods Not Stopping After Uninstallation](#failed-initialization-or-pods-not-stopping-after-uninstallation)
      - [Jupyterhub Gives Error `500` When Launching Server](#jupyterhub-gives-error-500-when-launching-server)
  - [Nginx](#nginx)
    - [Nginx setup](#nginx-setup)
  - [Dask Gateway](#dask-gateway)
    - [Node Assignment](#node-assignment)
    - [Modifying Resource Limits](#modifying-resource-limits)
    - [Using Dask and its Dashboard](#using-dask-and-its-dashboard)
  - [Mongodb](#mongodb)
    - [Mongodb documentation](#mongodb-documentation)
    - [Mongodb configuration and user creation](#mongodb-configuration-and-user-creation)
    - [Log in as root](#log-in-as-root)
    - [Create a userAdmin](#create-a-useradmin)
    - [Create a Mongo User and authentication](#create-a-mongo-user-and-authentication)
    - [Create a Mongo Database](#create-a-mongo-database)
    - [Insert test data into a Database](#insert-test-data-into-a-database)
    - [Helpful Mongosh Commands](#helpful-mongosh-commands)
    - [MongoDB Built-in Roles](#mongodb-built-in-roles)
    - [Signing in as a user with specific roles](#signing-in-as-a-user-with-specific-roles)
  - [Prometheus Integration](#prometheus-integration)
    - [Install Prometheus](#install-prometheus)
      - [Prerequisites](#prerequisites-1)
      - [Installation](#installation-1)
      - [Usage](#usage)
      - [Enabling Services](#enabling-services)

<!-- markdown-toc end -->


# OPAL-HELM

This repo contains all the deployment helm charts and configuration files for deploying the Open Platform for Avionics Learning or OPAL.

## Getting Started with Opal-helm Deployment

### Prerequisites

- A Kubernetes Cluster (or Minikube if deploying locally)
- Kubectl
    - https://kubernetes.io/docs/tasks/tools/#kubectl
- K9s (optional, but highly recommended)
    - https://k9scli.io/topics/install/
- Helm
    - https://helm.sh/docs/intro/install/
- A valid authentication token for `registry1.dso.mil`
- Clone https://github.com/309theddge/opal-helm

#### Additional Prerequisites for Local Deployment

- Minikube
    - https://minikube.sigs.k8s.io/docs/start/
- Docker (DO NOT install Docker Desktop if using Linux)
    - https://docs.docker.com/engine/install/
- Clone https://github.com/309theddge/k8s-utils
- Clone https://github.com/309theddge/argo

#### Optional Extras

- Prometheus Stack
    - https://github.com/309theddge/kube-prometheus

### Local Installation

#### Starting Minikube

Run the following command in your terminal:

``` bash
minikube start
```

If minikube fails to start, use the minikube documentation to troubleshoot any issues 
https://minikube.sigs.k8s.io/docs/start/

#### ArgoCD

ArgoCD is a continuous deployment (CD) tool used to manage and provide automatic updates for Kubernetes applications

The opal team uses Argo CD to ensure OPAL deployments are always up-to-date


##### Setting up ArgoCD regcred

`cd` into `k8s-utils/regcred-init` and run the following command:

``` bash
helm install argo-regcred . --create-namespace -n argocd -f argo-values.yaml
```

##### Install ArgoCD helm chart

Now that the registry credentials have been configured, navigate into the `argo` repository cloned previously, and install the helm chart:

``` bash
cd charts
helm install argo . -n argocd
```


##### Access the ArgoCD secret

To retrieve the argoCD admin password:

``` bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Alternatively, using `K9s`:
1. Press `0` to ensure all namespaces are visible
2. Type `:secret` and press enter
4. Move your cursor down to `argocd-initial-admin-secret` and press `x`
5. Copy the password for the next step

##### Accessing the ArgoCD Dashboard

To connect to the argoCD dashboard, you will need to port-forward the argocd-server service:

``` bash
kubectl port-forward service/argo-argocd-server -n argocd 8080:443
```

Alternatively, using `K9s`:
1. Press `0` to ensure all namespaces are visible
2. Type `:svc` and press enter
4. Move your cursor down to `argocd-argocd-server` and press `shift-f`
5. Ensure `Container Port` says `server::8080`. If not, delete the line and set it to `8080`
6. Move your cursor down to `OK` and press enter

Access the argoCD dashboard by visiting `localhost:8080` in your browser.

To log in, enter the following:

Username: 
> admin

Password: 
> output from the last section (remove the trailing '%' symbol if present)

**The following step is optional in internet-facing deployments as the opal-helm repository is public**

Once logged in, go to `Settings`->`Repositories`->`Connect Repo`
Change the connection method to `VIA HTTPS`

Fill out the following fields:
Repository URL:
> https://github.com/309thEDDGE/opal-helm.git

Username:
> enter github user name

Password:
> enter your github token

Click the `Connect` button at the top of the page to save the connection

If configured correctly, the connection status will show as *Successful*

## Deploying OPAL

With argoCD running and configured, the opal helm chart can now be installed.

### TLS Certificates

For full functionality of OPAL, tls certificates will need to be provided. 

#### For Live/Airgapped Environments:

Ensure your certificates cover the following subdomains at a bare minimum:

- `opal.<domain>`
- `keycloak.<domain>`
- `minio.<domain>`

#### For Local Deployments (must be internet-connected):

We have provided a tool for generating local selfsigned certificates that cover all opal subdomains. To generate these certificates:

`cd` into `k8s-utils/cert-gen`
Run `bash gen_selfsigned_certs.bash`. This will create the files `tls.crt` and `tls.key`

#### Install Certificates

Place your certificates in `opal-helm/opal-setup`, naming your certificate and private key `tls.crt` and `tls.key`, respectively.

### Image Registry Authentication

In all cases but one (busybox...), OPAL uses images stored in Platform1's IronBank. Assuming you're not mirroring these images already for an airgapped deployment, you will need to provide your docker credentials to allow kubernetes to download them.

#### Install dockerconfig.json

To allow kubernetes to authenticate with a private image registry, you'll first need to log in to that registry through the docker cli.
In the case of IronBank, this will be `docker login registry1.dso.mil`. If using a different private registry, use that URL instead.

Upon successful login, assuming you are using a Linux system, the login command should have created the file `~/.docker/config.json`. Copy this to `opal-helm/opal-setup`, and rename it to `dockerconfig.json`

### Git Sync

If enabled in the values.yaml, jupyterhub will add sidecars containers to the hub pod that will periodically pull in updates from the `opal` and `weave` repositories. 

> **NOTE**: Some repositories may require a github account and access token with repo scope.

To use git-sync, place your token in opal-setup, and rename it to `git-creds`. In opal-setup/values, fill in your username in jupyterhub:appValues:gitSync

### Install the OPAL helm chart

Prior to installing OPAL, if you are testing a specific branch or have configurations stored in another branch, ensure that the value of `targetRevision` in `opal-helm/opal-setup/values.yaml` is set to the correct branch, or you may run into unforeseen issues.

#### Configuring OPAL

> **NOTE:** This section is largely irrelevant for local deployments, as the default configuration is catered to a straightforward local install. If you are testing changes for a PR or simply wish to modify your configuration from the default, feel free to ignore this note.

There are two main configuration points made available to users:
- `opal-helm/opal-setup/values.yaml`
This is the "secret" values configuration. Any configurations that you do not wish to store in git should be made here. Common use cases for this file include ingress hosts or initial admin passwords for select services.
> **NOTE:** This should go without saying, but don't commit this file if you store any sensitive data in it
- `opal-helm/opal/*-values.yaml`
Values stored in this directory should contain only values safe to store in version control. To use configurations here, create a copy of `values.yaml`, and push your changes to a new branch. Ensure you change `targetRevision` and `valuesFile` in `opal-setup/values.yaml` to reflect your new branch and configuration file.

#### Installation

Before starting, navigate into the `opal-helm` repository and ensure the `opal-setup` directory follows the below structure. If any files are missing, refer to the previous steps.

```
opal-setup
├── charts
│   └── ...
├── Chart.yaml
├── dockerconfig.json
├── templates
│   └── ...
├── tls.crt
├── tls.key
└── values.yaml
```

If all expected files are present, navigate into `opal-setup`, and run the following:
``` bash
helm install opal-setup .
```

> **NOTE:** if deploying locally using minikube, also run `minikube tunnel` in a separate terminal. Failure to do so will cause installation to stall out on creation of the ingress controller

This process can take several minutes depending on your internet speeds, CPU, system memory, etc. Opening a watch list for the pods can be helpful in this step:

``` bash
watch kubectl get pods -A
```

Alternatively, using `K9s`:
1. Press `0` to ensure all namespaces are visible
2. Type `:pods` and press enter
3. Scroll down until you see pods in the `opal` and `minio-tenant` namespaces. Note that these namespaces will be different if you changed the target namespaces in `values.yaml`

After the status of all opal pods are running and the keycloak-setup pod is complete, open a browser to access the services. Assuming complete success, your services should be available at your configured ingress points. 
In a local deployment, the ingress points will default to:

- opal.10.96.30.9.nip.io
- minio.10.96.30.9.nip.io
- keycloak.10.96.30.9.nip.io

> **NOTE:** Older versions of the helm chart may append a `-k8s` to the service names in the ingress points. To confirm your configured ingresses, run `kubectl get ing -A` in your terminal.

### First Login

Before accessing OPAL, you'll need to set up some permissions in Keycloak. First, get the Keycloak admin password:

``` bash
kubectl get secret -n opal opal-setup-keycloak-env -o jsonpath='{.data.KEYCLOAK_ADMIN_PASSWORD}' | base64 --decode
```

Alternatively, using `K9s`:
1. Press `0` to ensure all namespaces are visible
2. Type `:secret` and press enter
3. Type `/keycloak-env` and press enter
4. Move your cursor down to `opal-setup-keycloak-env` and press `x`
5. Copy the value of `KEYCLOAK_ADMIN_PASSWORD`

Access Keycloak through the configured ingress point.

To log in, enter the following:

Username: 
> admin

Password: 
> output from the last section (remove the trailing '%' symbol if present)

#### Set Permissions

The  `admin` user, should already have keycloak permission and groups correctly assigned.  You must log into keycloak if you wish to create a new user.

#### Creating a new User

To add a user, login to the keycloak url with these root credentials and perform the following:

- Click `Administration Console` (you may automatically be redirected without this step)
- Click `Users`
- Click `Add User`
- Create a username, click save.

After the user is generated, the following steps are performed within the user configuration. If this is not automatically pulled up, it can be accessed by clicking `Users` on the left bar, searching for the username, and clicking the blue UID for the user:

- To allow Minio access, click `Attributes` and add the key `policy` and the value `consoleAdmin`. For less permissive policies see [the minio documentation](https://docs.min.io/minio/baremetal/security/minio-identity-management/policy-based-access-control.html). Ensure `Add` and then `Save` are clicked, otherwise jupyterhub will show a `500: internal Server Error` when the user attempts login
- Click `Groups`, then click `jupyterhub_staff`, then click `join` to allow the user to log into jupyterhub
- Click `Credentials`, add a temporary password in the `Password` and `Password Comfirmation` fields
- Send the username and temporary password to the user

Go to `Groups` in the left column. Select `jupyterhub_staff`.

You should now be able to access OPAL/Jupyterhub in your browser.


### Troubleshooting

#### Failed Initialization or Pods Not Stopping After Uninstallation
You may find you need to uninstall opal-setup to fix a failure in keycloak's initialization, or a number of other periodic bugs. This is not always a clean process, and will need to be forced by manually removing any problematic resources. This can be done using the following command:

``` bash
kubectl patch Application/<failing application> --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' -n argocd
```

Failed applications can be found by running `kubectl get apps -n argocd`. They will often appear to be stuck in the `progressing` state.

#### Jupyterhub Gives Error `500` When Launching Server

This can be caused by a couple of issues.

Most commonly, this indicates that the `policy` attribute was not set correctly in Keycloak. See the `Set Permissions` section above.

Another cause commonly seen after stopping/restarting Minikube is MinIO failing to connect to Keycloak. The simplest way to resolve this is in `K9s`. 
1. Type `:pods` and press enter
2. Move your cursor down to the `<deployment name>-minio-ss-0-\*` pods. 
> **NOTE:** if this helm chart was installed as `opal-setup`, this will look like `opal-setup-minio-ss-0-\*`
3. For each pod, press `ctrl-k j`. This will need to be done quickly.



## Nginx

OPAL uses nginx as a fileserver to provide a custom conda channel to users

### Nginx setup

By default, nginx will automatically populate from the `condaChannelImage` value in the nginx section of `opal/values.yaml`. Additional packages can be added using the following steps:

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

``` bash
kubectl cp <path_to_condapkg> opal/<nginx-podname>:/usr/share/nginx/html
```

Once in your singleuser environment, you can install the default conda environment using the following command:

``` bash
conda env create -f local_channel_env.yaml
```


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

In order to modify resource limits for dask gateway you will need to configure the values in the dask gateway helm chart values. Currently, by default they should be configured to allow the scheduler and workers 2 G of memory and one core a piece with the cluster total limits being 10 G of memory with 6 cores and 6 workers as a maximum. These values can be located at:

- gateway
  - extraConfig (This is where the cluster limits are defined)
  - backend
    - scheduler
      - cores
      - memory
    - worker
      - cores
      - memory

### Using Dask and its Dashboard

The first step in using dask is creating a Gateway and creating a cluster through it.
This Can be done like this:

```python
from dask_gateway import Gateway
gateway = Gateway(address=os.environ["DASK_GATEWAY_ADDRESS"], auth="jupyterhub")
cluster = gateway.new_cluster()
```

Following that a client will need to be made like this:

```python
from dask.distributed import Client
client = Client(cluster)
client
```

This will output a URL that will give you access to the dask dashboard. However, you will need to modify the URL
inorder for it to work.

```text
Original
https://proxy-public/services/dask-gateway/clusters/opal.c9637057fccb41abb9adc9313fd2b6db/status
Modified
https://opal-k8s.10.96.30.9.nip.io/services/dask-gateway/clusters/opal.c9637057fccb41abb9adc9313fd2b6db/status
```

You can see that the
```text
proxy-public
```
has been replaced with
```text
opal-k8s.10.96.30.9.nip.io
```

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

``` bash
kubectl run --namespace opal mongo-db-mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image registry1.dso.mil/ironbank/bitnami/mongodb:5.0.9 --command -- bash
```

The terminal should change showing that the container is running

To connect to your database from outside the cluster execute the following commands:

``` bash
kubectl port-forward --namespace opal svc/mongo-db-mongodb 27017:27017 &
mongosh --host 127.0.0.1 --authenticationDatabase admin -p $MONGODB_ROOT_PASSWORD
```

### Log in as root

The default root user name is : *rootuser*
Then, run the following command:

``` bash
mongosh admin --host "opal-setup-mongodb" --authenticationDatabase admin -u rootuser
```

This will prompt a password that is found in the previous section.

### Create a userAdmin

It is best practice to create a user administrator in order to create database users. 

```
db.createUser(
  {
    user: "user_name_admin",
    pwd:  passwordPrompt(),   // or cleartext password
    roles: [ { role: "userAdmin", db: "admin" } ]
  }
)
```

### Create a Mongo User and authentication

By deafault SCRAM-SHA-256 is enabled as the authentication mechanism supported by a cluster configured for authentication with MongoDB 4.0 and later.  Authentication requires a username, password, and a database name.  The default database name is "admin"

```
db.createUser(
  {
    user: "user_name",
    pwd:  passwordPrompt(),   // or cleartext password
    roles: [ { role: "readWrite", db: "name_of_database" } ]
  }
)
```

### Create a Mongo Database

To create a database simple run this command in the terminal:

``` 
use simple_db
```

This will create and empty database that will not be visible to any user until some data has been submitted

### Insert test data into a Database

For purposes of this example use the following entry in the command line to place some data in the sample database

```
db.movies.insertOne(
  {
    title: "Back to the Future",
    genres: [ "Time Travel", "Adventure" ],
    runtime: 116,
    rated: "PG",
    year: 1985,
    directors: [ "Robert Zemeckis" ],
    cast: [ "Michael J. Fox", "Christopher Lloyd", "Lea Thompson" ],
    type: "movie"
  }
)
```

### Helpful Mongosh Commands

```
show dbs  // *shows all available databases the user can access, if the user is root it will also display local and admin*

db // *prints the current database*

use <database_name> // *switch database*

show collections // *shows all collections from the current database*

load("myScripts.js") // *runs a JavaScript file for data entry

db.<name_of_collection>.find() // *shows all data in a specific collection
```

### MongoDB Built-in Roles

Mongo grants acces to data and commands through roles.  These roles are built-in, but there is also the option to create user-defined roles.

>**read** // *provides with user to read data on all non-system collections*

>**readWrite** // *provides all the privileges of the read role and the ability to modify data on all non-system collections*

>**dbAdmin** // *provides the ability to perform adminisrative tasks such as schema-related tasks, indexing, gathering statistics. This role does NOT grant privelges for user and role management.*

>**dbOwner** // *provides the ability to perform any administrative task on the database.*

>**userAdmin** // * provides the ability to create and modify roles and users on the current database. Since the userAdmin role allows users to grant any privilege to any user, including themselves, the role also indirectly provides superuser access to either the database or, if scoped to the admin database, the cluster.*


### Signing in as a user with specific roles
To be able to securly enter a database you will need to login with the user credentials and authentication method, this can be done with the following command in pymongo:

``` python
from pymongo import MongoClient
client = MongoClient('example.com',
                     username='user',
                     password='password',
                     authSource='the_database',
                     authMechanism='SCRAM-SHA-256')
```

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
2. Copy `~/.docker/config.json` into `k8s-utils/regcred-init`, rename to `dockerconfig.json`
3. In `k8s-utils/regcred-init`, run `helm install metrics-regcred . -n monitoring -f prometheus-values.yaml --create-namespace`

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

#### Enabling Services

To enable prometheus monitoring for any supported service, simply set `metrics` and `serviceMonitor` to `True` in your values.yaml

Supported services:
- Minio
- Keycloak
- Jupyterhub
- Traefik
