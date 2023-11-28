### Table of Contents

[Purpose](https://github.com/309thEDDGE/opal-helm#purpose)
[Getting Started](https://github.com/309thEDDGE/opal-helm#getting-started-with-opal-helm-depolyment)
[ArgoCD](https://github.com/309thEDDGE/opal-helm#argocd)
[Deploying ArgoCD](https://github.com/309thEDDGE/opal-helm#deploying-argocd)
    - [Starting Minikube](https://github.com/309thEDDGE/opal-helm#starting-minikube)
    - [Setting up Argocd Regcred](https://github.com/309thEDDGE/opal-helm#setting-up-argo-regcred)
    - [Configure ArgoCD Helm Chart](https://github.com/309thEDDGE/opal-helm#configure-argocd-helm-chart)
    - [Install ArgoCD Helm Chart](https://github.com/309thEDDGE/opal-helm#install-argocd-helm-chart)
    - [Accessing ArgoCD Secret](https://github.com/309thEDDGE/opal-helm#access-the-argocd-secret)
    - [Adding the Repository to ArgoCD](https://github.com/309thEDDGE/opal-helm#add-repo-to-argocd-dashboard)
[Deploying OPAL](https://github.com/309thEDDGE/opal-helm#deploying-opal)
[Important URLs](https://github.com/309thEDDGE/opal-helm#important-urls)
[Mongodb](https://github.com/309thEDDGE/opal-helm#argocd)
[To Do List](https://github.com/309thEDDGE/opal-helm#todo)

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

### Configure the ArgoCD Helm Chart

change directory to the ARGOCD/chart helm repository. open the values.yaml IDE of your choice.  

make the following changes:

**line 60:**
    - change upgradeJob -> enabled value from "true" to "false"
**line 135:**
    - change imagePullSecrets -> name from "private-registry" to "regcred"
**line 1470:**
    - change redis-bb -> image -> pullSecrets from "private-registry" to "regcred"
**line 2000:**
    - change server -> ingress -> enabled from "flase" to "true" 
**line 2002:**  
    - remove brackets from server -> ingress -> annotations and add the following fields
        
>traefik.ingress.kubernetes.io/router.entrypoints: websecure 
>traefik.ingress.kubernetes.io/router.tls: "true"

NOTE: make sure to save the file
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
>password: output from the last section 

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

### Helm install OPAL
Navigate to the parent opal-helm repository directory and helm install opal-setup:
>$helm install opal ./opal-setup

This process can take several minutes depeneding on different variables.  Opening a watch list for the pods can be helpful in this step:
>$watch kubectl get pods -A

After the status of all opal pods are running and the keycloak-setup pod is complete, open a browser to access the services.

### Patching argoCD
if there is a reason to update any of the helm values while argoCD is running, there will have to be a patch applied to make sure the changes take place
>$kubectl patch Application/keycloak \ --type json \ --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' -n argocd

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

## Mongodb

### Mongodb configuration and user creation

In order to add users to the Mongodb database, you will need to first create the user with the root admin.

MongoDB can be accessed on the following DNS name(s) and ports from within your cluster:

>mongo-db-mongodb.opal.svc.cluster.local

To get the root password run:
>kubectl get secret --namespace opal opal-mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d

To connect to your database, and create a MongoDB client container:

>kubectl run --namespace opal mongo-db-mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image registry1.dso.mil/ironbank/bitnami/mongodb:5.0.9 --command -- bash

The terminal should change showing that the container is running

### Log in as root
Then, run the following command:
>$ mongosh admin --host "opal-mongodb" --authenticationDatabase admin -u rootname

To connect to your database from outside the cluster execute the following commands:

>kubectl port-forward --namespace opal svc/mongo-db-mongodb 27017:27017 &
mongosh --host 127.0.0.1 --authenticationDatabase admin -p $MONGODB_ROOT_PASSWORD

### Create a Mongo Database
After logging into the container as root, If this is a fresh OPAL deployment you will need to create the databases before adding users.

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

### Create a Mongo User

>db.createUser(
  {
    user: "user_name",
    pwd:  passwordPrompt(),   // or cleartext password
    roles: [ { role: "readWrite", db: "name_of_database" },
             { role: "read", db: "name_of_database" } ]
  }
)

### MongoDB Built-in Roles

Mongo grats acces to data and commands through role.  These roles are built-in, but there is also the option to create user-defined roles.

### Signing in as a user with specific roles
To be able to securly enter a database you will need to login with the user credentials, this can be done with the following command:

>db.auth( username, passwordPrompt())

By default mongosh excludes all db.auth() operations from the saved history
## TODO
add the regcred-init repo to opal-helm
add the argoCD repo to opal-helm



