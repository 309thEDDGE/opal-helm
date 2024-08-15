# get helm values
c = get_config()

import os
from oauthenticator.generic import GenericOAuthenticator
import requests
import re
import sys

from tornado.httpclient import AsyncHTTPClient
from kubernetes_asyncio import client
from jupyterhub.utils import url_path_join

configuration_directory = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, configuration_directory)

from config_utilities import (
    get_config,
    get_name,
    get_name_env,
    get_secret_value,
    set_config_if_not_none,
)

# helm values usually use camelCase, this works around that
# shamelessly ripped from zero-to-jupyterhub configs
def camelCaseify(s):
    return re.sub(r"_([a-z])", lambda m: m.group(1).upper(), s)

AsyncHTTPClient.configure("tornado.curl_httpclient.CurlAsyncHTTPClient")

c.JupyterHub.spawner_class = 'kubespawner.KubeSpawner'

# Connect to a proxy running in a different pod
c.ConfigurableHTTPProxy.api_url = f'http://{get_name("proxy-api")}:{get_name_env("proxy-api", "_SERVICE_PORT")}'
c.ConfigurableHTTPProxy.should_start = False

# Leave singleuser running if hub shuts down
c.JupyterHub.cleanup_servers = False

# proxy routing
c.JupyterHub.last_activity_interval = 60
c.JupyterHub.tornado_settings = {
    "slow_spawn_timeout:": 0,
}

# the hub should listen on all interfaces, so the proxy can access it
c.JupyterHub.hub_ip = '0.0.0.0'


# set the user's server image
#c.KubeSpawner.image_pull_policy = "Never"
c.KubeSpawner.image_pull_policy = "IfNotPresent"
c.KubeSpawner.image_pull_secrets = ["regcred"]
# c.KubeSpawner.image = "registry.il2.dso.mil/skicamp/project-opal/tip:f970c010"
c.KubeSpawner.image = os.environ["SINGLE_USER_IMAGE"]
# wait a bit longer for spawn
c.KubeSpawner.http_timeout = 60 * 5

# inherit some jupyterhub environment variables
c.KubeSpawner.env_keep = [
    "OPAL_BANNER_TEXT",
    "OPAL_BANNER_COLOR",
    "MINIO_IDENTITY_OPENID_CLIENT_ID",
    "KEYCLOAK_MINIO_CLIENT_SECRET",
    "KEYCLOAK_OPAL_API_URL",
    "S3_ENDPOINT",
    "MONGODB_HOST",
    "MONGODB_USERNAME",
    "DASK_GATEWAY_ENDPOINT",
    "NGINX_HOST",
    "CONDA_OVERRIDE_CUDA"
]

metaflow_mount_path = "/opt/opal/metaflow-metadata"
dda_url_name = os.environ["BASE_URL"] + "/user/{unescaped_username}/proxy/8000"
mongo_password = os.environ["mongodb-root-password"]
# add some extra environment variables
c.KubeSpawner.environment = {
    "USERNAME": "jovyan",
    "METAFLOW_DATASTORE_SYSROOT_LOCAL": metaflow_mount_path,
    "CONDA_ENVS_PATH": "$HOME/.conda/envs/",
    "JUPYTER_RUNTIME_DIR": "/tmp",
    "DDA_ROOT_PATH": dda_url_name,
    "MONGODB_PASSWORD": mongo_password
}

# init container for fixing permissions in home/jovyan
c.KubeSpawner.init_containers = [{
    "name": "fix-permissions",
    "image": "busybox",
    "command": ["sh", "-c", "chown -v -R 1000:100 /jovyan"],
    "volume_mounts": [{
        'mountPath': '/jovyan',
        'name': "home-jovyan-mnt"
        }]
    }
]
# assign a security context for write permissions to
# the attached volumes
c.KubeSpawner.fs_gid = 100
c.KubeSpawner.uid = 1000

# # Mount volume for storage
pvc_name_template = 'claim-{username}'
c.KubeSpawner.pvc_name_template = pvc_name_template

c.KubeSpawner.storage_pvc_ensure = True
use_azure = os.getenv('USE_AZUREFILE', False)
if use_azure:
    c.KubeSpawner.storage_class = 'azuredisk-csi-singleuser'
    # sometimes azuredisk attach is crazy slow
    c.KubeSpawner.start_timeout = 60 * 5
else:
    c.KubeSpawner.storage_class = 'standard'

c.KubeSpawner.storage_access_modes = ['ReadWriteOnce']
#singleuser_storage = int(os.env['SINGLE_USER_STORAGE_CAPACITY'])
#c.KubeSpawner.storage_capacity = '{}Gi'.format(singleuser_storage)
c.KubeSpawner.storage_capacity = os.environ['SINGLE_USER_STORAGE_CAPACITY']

# Add volumes to singleuser pods
c.KubeSpawner.volumes = [
    {
        'name': "home-jovyan-mnt",
        "persistentVolumeClaim": {
            "claimName": pvc_name_template
        }
    },
    {
        'name': f'{get_name("singleuser")}',
        "configMap": {
            "name": "singleuser-config",
            "defaultMode": 0o755 # octal permission number
        }
    },
    {
        'name': "metaflow-store",
        "persistentVolumeClaim": {
            "claimName": "metaflow-datastore"
        }
    },
    {
        'name': 'opal-sync-mnt',
        'persistentVolumeClaim': {
            'claimName': 'opal-sync-pvc'
        }
    },
    {
        'name': 'ddapi-sync-mnt',
        'persistentVolumeClaim': {
            'claimName': 'ddapi-sync-pvc'
        }
    },
    {
        'name': 'weave-sync-mnt',
        'persistentVolumeClaim': {
            'claimName': 'weave-sync-pvc'
        }
    }
]

c.KubeSpawner.volume_mounts = [
    {
        'mountPath': '/tmp/tars/jhub-conf.tar',
        'subPath': "jupyterhub-conf-dir.tar",
        'name': "singleuser-config"
    },
    {
        'mountPath': '/home/jovyan',
        'name': "home-jovyan-mnt"
    },
    {
        'mountPath': '/tmp/startup_script.bash',
        "subPath": "startup_script.bash",
        "name": "singleuser-config"
    },
    {
        'mountPath': '/home/jovyan/.jupyter/jupyter_notebook_config.py',
        "subPath": "jupyter_notebook_config.py",
        "name": "singleuser-config"
    },
    {
        'mountPath': '/etc/jupyter/jupyter_server_config.py',
        "subPath": "jupyter_server_config.py",
        "name": "singleuser-config"
    },
    {
        'mountPath': metaflow_mount_path,
        "name": "metaflow-store",
        "readOnly": False
    },
    {
        'mountPath': '/opt/data/opal',
        "subPath": "opal",
        'name': 'opal-sync-mnt'
    },
    {
        'mountPath': '/opt/data/data-discovery-api',
        "subPath": "data-discovery-api",
        'name': 'ddapi-sync-mnt'
    },
    {
        'mountPath': '/opt/data/weave',
        "subPath": "weave",
        'name': 'weave-sync-mnt'
    },
    {
        'mountPath': '/opt/conda/.condarc',
        'subPath': '.condarc.toplevel',
        'name': 'singleuser-config'
    },
    {
        'mountPath': '/opt/conf/.condarc',
        'subPath': '.condarc.user',
        'name': 'singleuser-config'
    },
    {
        'mountPath': '/opt/conf/conda_channel.yaml',
        'subPath': 'conda_channel.yaml',
        'name': 'singleuser-config'
    }
]

# set the startup bash script
c.KubeSpawner.cmd = "/tmp/startup_script.bash"

# # Gives spawned containers access to the API of the hub
c.Jupyterhub.hub_bind_url = 'http://:8081'
c.JupyterHub.hub_connect_url = f'http://{get_name("hub"):{get_name_env("hub","_SERVICE_PORT")}}'

# Authentication
def get_minio_creds(keycloak_access_token):
    body = {
            "Action": "AssumeRoleWithWebIdentity",
            "WebIdentityToken": keycloak_access_token,
            "Version": "2011-06-15",
            # "DurationSeconds": 604800, # This should pick up the value specified by keycloak if left blank
            }
    r = requests.post(s3_endpoint, data=body)

    if r.status_code != 200:
        raise Exception(f"***Minio sts failed***\nkeycloak access token: {keycloak_access_token}\nresponse for sts request:\n{r}\ntext response:\n{r.text}")
    xml = r.text
    access_key_id = xml.split("<AccessKeyId>")[1].split("</AccessKeyId>")[0]
    secret_access_key = xml.split("<SecretAccessKey>")[1].split("</SecretAccessKey>")[0]
    session_token = xml.split("<SessionToken>")[1].split("</SessionToken>")[0]

    return access_key_id, secret_access_key, session_token

# authenticator class
s3_endpoint = os.environ['S3_ENDPOINT']

class CustomAuthenticator(GenericOAuthenticator):
    async def pre_spawn_start(self, user, spawner):
        try:
            auth_state = await user.get_auth_state()
        except:
            print("Minio STS Failed")
            auth_state = None

        if not auth_state:
            # user has no auth state
            return

        access_token = auth_state['access_token']

        access_key_id, secret_access_key, session_token = get_minio_creds(access_token)

        # define environment variables
        spawner.environment['S3_KEY'] = access_key_id
        spawner.environment['S3_SECRET'] = secret_access_key
        spawner.environment['S3_SESSION'] = session_token

        # define some more environment variables - these are necessary for metaflow
        spawner.environment['AWS_ACCESS_KEY_ID'] = access_key_id
        spawner.environment['AWS_SECRET_ACCESS_KEY'] = secret_access_key
        spawner.environment['AWS_SESSION_TOKEN'] = session_token
        spawner.environment['USERNAME'] = 'jovyan'

# ENVIRONMENT VARIABLES FOR GENERIC OAUTHENTICATOR KEYCLOAK CONFIGURATION
keycloak_jupyterhub_client_id = os.environ['KEYCLOAK_JUPYTERHUB_CLIENT_ID']
keycloak_jupyterhub_client_secret = os.environ['KEYCLOAK_JUPYTERHUB_CLIENT_SECRET']
keycloak_jupyterhub_oauth_callback_url = os.environ['KEYCLOAK_JUPYTERHUB_OAUTH_CALLBACK_URL']
keycloak_jupyterhub_authorize_url = os.environ['KEYCLOAK_JUPYTERHUB_AUTHORIZE_URL']
keycloak_opal_api_url = os.environ['KEYCLOAK_OPAL_API_URL']
keycloak_jupyterhub_userdata_url = os.environ['KEYCLOAK_JUPYTERHUB_USERDATA_URL']
keycloak_jupyterhub_username_key = os.environ['KEYCLOAK_JUPYTERHUB_USERNAME_KEY']

c.GenericOAuthenticator.login_service = 'keycloak'
c.GenericOAuthenticator.userdata_params = {"state": "state"}
c.GenericOAuthenticator.client_id = keycloak_jupyterhub_client_id
c.GenericOAuthenticator.client_secret = keycloak_jupyterhub_client_secret
c.GenericOAuthenticator.tls_verify = False
c.GenericOAuthenticator.oauth_callback_url = keycloak_jupyterhub_oauth_callback_url
c.GenericOAuthenticator.authorize_url = keycloak_jupyterhub_authorize_url
c.GenericOAuthenticator.token_url = keycloak_opal_api_url
c.GenericOAuthenticator.username_key = keycloak_jupyterhub_username_key
c.GenericOAuthenticator.userdata_url = keycloak_jupyterhub_userdata_url
c.GenericOAuthenticator.enable_auth_state = True
c.GenericOAuthenticator.refresh_pre_spawn = True

c.JupyterHub.authenticator_class = CustomAuthenticator

# Group membership config
c.OAuthenticator.claim_groups_key = "groups"
c.OAuthenticator.allowed_groups = ["jupyterhub_staff"]
c.OAuthenticator.admin_groups = ["jupyterhub_admins"]
c.OAuthenticator.scope = ['openid', 'profile', 'roles']

########## extra services ##########

# Dask Gateway Setup
release_name = os.environ["HELM_RELEASE_NAME"]
namespace = os.environ["POD_NAMESPACE"]

jupyterhub_api_token = os.environ['JUPYTERHUB_API_TOKEN']
service_url = "http://{}-dask-gateway-traefik.{}".format(release_name, namespace)

c.JupyterHub.services = [
    {"name": "dask-gateway", "api_token": jupyterhub_api_token, "url": service_url }
]

c.KubeSpawner.environment.setdefault("DASK_GATEWAY_PROXY_ADDRESS", f"gateway://{release_name}-dask-gateway-traefik.{namespace}:80")
c.KubeSpawner.environment.setdefault("DASK_GATEWAY_ADDRESS", "http://proxy-public/services/dask-gateway")
c.KubeSpawner.environment.setdefault("DASK_GATEWAY_PUBLIC_ADDRESS", f"/services/dask-gateway")
c.KubeSpawner.environment.setdefault("DASK_GATEWAY_AUTH_TYPE", "jupyterhub")

# Cdsdashboards stuff
from cdsdashboards.app import CDS_TEMPLATE_PATHS
from cdsdashboards.hubextension import cds_extra_handlers

c.DockerSpawner.name_template = "{prefix}-{username}-{servername}"
c.JupyterHub.template_paths = CDS_TEMPLATE_PATHS
c.JupyterHub.extra_handlers = cds_extra_handlers
c.JupyterHub.allow_named_servers = True
c.CDSDashboardsConfig.builder_class = 'cdsdashboards.builder.dockerbuilder.DockerBuilder'
