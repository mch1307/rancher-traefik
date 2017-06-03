#!/usr/bin/env sh

TRAEFIK_HTTP_PORT=${TRAEFIK_HTTP_PORT:-"80"}
TRAEFIK_HTTPS_ENABLE=${TRAEFIK_HTTPS_ENABLE:-"true"}
TRAEFIK_HTTPS_PORT=${TRAEFIK_HTTPS_PORT:-"443"}
TRAEFIK_ADMIN_PORT=${TRAEFIK_ADMIN_PORT:-"8000"}
TRAEFIK_DEBUG=${TRAEFIK_DEBUG:="true"}
TRAEFIK_LOG_LEVEL=${TRAEFIK_LOG_LEVEL:-"DEBUG"}
TRAEFIK_LOG_FILE=${TRAEFIK_LOG_FILE:-"${SERVICE_HOME}/log/traefik.log"}
TRAEFIK_ACCESS_FILE=${TRAEFIK_ACCESS_FILE:-"${SERVICE_HOME}/log/access.log"}
TRAEFIK_SSL_PATH=${TRAEFIK_SSL_PATH:-"${SERVICE_HOME}/certs"}
TRAEFIK_ACME_ENABLE=${TRAEFIK_ACME_ENABLE:-"false"}
TRAEFIK_ACME_EMAIL=${TRAEFIK_ACME_EMAIL:-"test@traefik.io"}
TRAEFIK_ACME_ONDEMAND=${TRAEFIK_ACME_ONDEMAND:-"true"}
TRAEFIK_ACME_ONHOSTRULE=${TRAEFIK_ACME_ONHOSTRULE:-"true"}
TRAEFIK_K8S_ENABLE=${TRAEFIK_K8S_ENABLE:-"false"}
TRAEFIK_K8S_OPTS=${TRAEFIK_K8S_OPTS:-""}
TRAEFIK_RANCHER_ENDPOINT=${TRAEFIK_RANCHER_ENDPOINT}
TRAEFIK_RANCHER_DOMAIN=${TRAEFIK_RANCHER_DOMAIN}
#TRAEFIK_RANCHER_ACCESS_KEY=$(cat $TRAEFIK_RANCHER_ACCESSKEY && echo)
TRAEFIK_RANCHER_ACCESS_KEY=${TRAEFIK_RANCHER_ACCESSKEY}
#TRAEFIK_RANCHER_SECRET_KEY=${cat $TRAEFIK_RANCHER_SECRET && echo)
TRAEFIK_RANCHER_SECRET_KEY=${TRAEFIK_RANCHER_SECRET}
TRAEFIK_REFRESH_INTERVAL=${TRAEFIK_REFRESH_INTERVAL:-"15"}

curl -o ${TRAEFIK_SSL_PATH}/traefik.key rancher-metadata/latest/self/service/metadata/traefik/ssl_key
curl -o ${TRAEFIK_SSL_PATH}/traefik.crt rancher-metadata/latest/self/service/metadata/traefik/ssl_crt

TRAEFIK_ENTRYPOINTS_HTTP="\
  [entryPoints.http]
  address = \":${TRAEFIK_HTTP_PORT}\"
    [entryPoints.http.redirect]
    entryPoint = \"https\"
"


TRAEFIK_ENTRYPOINTS_HTTPS="\
  [entryPoints.https]
  address = \":${TRAEFIK_HTTPS_PORT}\"
    [entryPoints.https.tls]"
       TRAEFIK_ENTRYPOINTS_HTTPS=$TRAEFIK_ENTRYPOINTS_HTTPS"
      [[entryPoints.https.tls.certificates]]
      #certFile = \"$TRAEFIK_SSL_CERT\" 
      certFile = ${TRAEFIK_SSL_PATH}/traefik.crt
      #keyFile = \"$TRAEFIK_SSL_PRIVATE_KEY\" 
      keyFile = ${TRAEFIK_SSL_PATH}/traefik.key
"

if [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}${TRAEFIK_ENTRYPOINTS_HTTPS}
    TRAEFIK_ENTRYPOINTS='"http", "https"'
elif [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xonly" ]; then
    TRAEFIK_ENTRYPOINTS_HTTP=$TRAEFIK_ENTRYPOINTS_HTTP"\
    [entryPoints.http.redirect]
       entryPoint = \"https\"
"
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}${TRAEFIK_ENTRYPOINTS_HTTPS}
    TRAEFIK_ENTRYPOINTS='"http", "https"'
else 
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}
    TRAEFIK_ENTRYPOINTS='"http"'
fi

if [ "X${TRAEFIK_K8S_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_K8S_OPTS="[kubernetes]"
fi

TRAEFIK_ACME_CFG=""
if [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xtrue" ] || [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xonly" ] && [ "X${TRAEFIK_ACME_ENABLE}" == "Xtrue" ]; then

    TRAEFIK_ACME_CFG="\
[acme]
email = \"${TRAEFIK_ACME_EMAIL}\"
storage = \"${SERVICE_HOME}/acme/acme.json\"
onDemand = ${TRAEFIK_ACME_ONDEMAND}
OnHostRule = ${TRAEFIK_ACME_ONHOSTRULE}
entryPoint = \"https\"

"

fi

cat << EOF > ${SERVICE_HOME}/etc/traefik.toml
# traefik.toml
debug = ${TRAEFIK_DEBUG}
logLevel = "${TRAEFIK_LOG_LEVEL}"
traefikLogsFile = "${TRAEFIK_LOG_FILE}"
accessLogsFile = "${TRAEFIK_ACCESS_FILE}"
defaultEntryPoints = [${TRAEFIK_ENTRYPOINTS}]
[entryPoints]
${TRAEFIK_ENTRYPOINTS_OPTS}
[web]
address = ":${TRAEFIK_ADMIN_PORT}"

${TRAEFIK_K8S_OPTS}

[rancher]
domain = "${TRAEFIK_RANCHER_DOMAIN}"
Watch = true
Endpoint = "${TRAEFIK_RANCHER_ENDPOINT}"
AccessKey = "${TRAEFIK_RANCHER_ACCESS_KEY}"
SecretKey = "${TRAEFIK_RANCHER_SECRET_KEY}"
RefreshSeconds  = "${TRAEFIK_REFRESH_INTERVAL}"


[file]
filename = "${SERVICE_HOME}/etc/rules.toml"
watch = true

${TRAEFIK_ACME_CFG}
EOF
