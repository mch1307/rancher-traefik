#!/usr/bin/env bash

function log {
        echo `date` $ME - $@
}

function serviceLog {
    log "[ Redirecting ${SERVICE_NAME} log... ]"
    if [ -e ${TRAEFIK_LOG_FILE} ]; then
        rm ${TRAEFIK_LOG_FILE}
    fi
    ln -sf /proc/1/fd/1 ${TRAEFIK_LOG_FILE}
}

function serviceAccess {
    log "[ Redirecting ${SERVICE_NAME} log... ]"
    if [ -e ${TRAEFIK_ACCESS_FILE} ]; then
        rm ${TRAEFIK_ACCESS_FILE}
    fi
    ln -sf /proc/1/fd/1 ${TRAEFIK_ACCESS_FILE}
}

function serviceCheck {
    log "[ Generating ${SERVICE_NAME} configuration... ]"
    ${SERVICE_HOME}/bin/traefik.toml.sh
}

function serviceStart {
    serviceCheck
    serviceLog
    serviceAccess
    echo `cat /opt/traefik/etc/traefik.toml`
    ${SERVICE_HOME}/bin/traefik --configFile=${SERVICE_HOME}/etc/traefik.toml 
    echo $! > ${SERVICE_HOME}/traefik.pid
    log $(cat ${SERVICE_HOME}/traefik.pid)
}

export TRAEFIK_LOG_FILE=${TRAEFIK_LOG_FILE:-"${SERVICE_HOME}/log/traefik.log"}
export TRAEFIK_ACCESS_FILE=${TRAEFIK_ACCESS_FILE:-"${SERVICE_HOME}/log/access.log"}

serviceStart &>> /proc/1/fd/1

