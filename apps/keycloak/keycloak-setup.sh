#!/bin/bash

# The following pages will help if this script needs updating:
# https://github.com/keycloak/keycloak-documentation/blob/main/server_admin/topics/admin-cli.adoc
# https://www.keycloak.org/docs-api/15.0/rest-api/index.html

cd /opt/keycloak/bin

#EXTERNAL_KEYCLOAK=${EXTERNAL_KEYCLOAK:-http://keycloak:8080/}

authenticate_keycloak () {
./kcadm.sh config credentials \
            --server $EXTERNAL_KEYCLOAK \
            --user $KEYCLOAK_USER \
            --password $KEYCLOAK_PASSWORD \
            --realm master
}

until authenticate_keycloak; do
    if [ $? -eq 1 ]; then
        echo "keycloak_setup cannot authenticate. It is likely the keycloak server is still booting. Retrying in 2 seconds"
	sleep 2
    else
        echo "keycloak_setup successfully authenticated"
    fi
done

echo "Bootstrapping Keycloak config"

# Don't require ssl
#echo "Disabling ssl"
./kcadm.sh update realms/master -s sslRequired=NONE

# Jupyterhub client creation
echo "Creating opal-jupyterhub client"
JUPYTERHUB_CLIENT_ID=$(./kcadm.sh create clients \
            --server $EXTERNAL_KEYCLOAK \
            -r master \
            -s clientId=$KEYCLOAK_JUPYTERHUB_CLIENT_ID \
            -s 'redirectUris=["*"]' \
	        -s 'attributes."access.token.lifespan"=60480000' \
            -s secret=$KEYCLOAK_JUPYTERHUB_CLIENT_SECRET -i)

echo "Creating jhub-group-mapper in opal-jupyterhub client with $JUPYTERHUB_CLIENT_ID"
./kcadm.sh create clients/$JUPYTERHUB_CLIENT_ID/protocol-mappers/models \
            -r master \
            -s name=jhub-group-mapper \
            -s protocol=openid-connect \
            -s protocolMapper=oidc-group-membership-mapper \
            -s 'config."full.path"=false' \
            -s 'config."id.token.claim"=true' \
            -s 'config."access.token.claim"=true' \
            -s 'config."claim.name"=groups' \
            -s 'config."userinfo.token.claim"=true'

# Minio client creation

#Minio client mapper creation
echo "Creating miniopolicyclaim mapper for opal-jupyterhub client with $JUPYTERHUB_CLIENT_ID"
./kcadm.sh create clients/$JUPYTERHUB_CLIENT_ID/protocol-mappers/models \
            -r master \
            -s name=miniopolicyclaim \
            -s protocol=openid-connect \
            -s protocolMapper=oidc-usermodel-attribute-mapper \
            -s 'config."id.token.claim"=true' \
            -s 'config."userinfo.token.claim"=true' \
            -s 'config."user.attribute"=policy' \
            -s 'config."id.token.claim"=true' \
            -s 'config."access.token.claim"=true' \
            -s 'config."claim.name"=policy' \
            -s 'config."jsonType.label"=String'

# Enable event logging for the master realm. Events expire after 14 days
./kcadm.sh update events/config -r master -s eventsEnabled=true -s 'enabledEventTypes=[]' -s eventsExpiration=1209600

# Create jupyterhub_admins and jupyterhub_staff groups
echo "creating staff groups"
./kcadm.sh create groups -r master -s name=jupyterhub_admins
./kcadm.sh create groups -r master -s name=jupyterhub_staff
echo "created jupyterhub_admins and jupyterhub_staff groups"

# Adds admin user to jupyterhub_admins and jupyterhub_staff groups

# Adds policy=readwrite to staff_group
./kcadm.sh update groups/$JUPYTERHUB_STAFF_GROUP_ID -s 'attributes.policy=["readwrite"]' -r master
./kcadm.sh update groups/$JUPYTERHUB_ADMINS_GROUP_ID -s 'attributes.policy=["consoleAdmin"]' -r master

echo "Done initializing keycloak"
