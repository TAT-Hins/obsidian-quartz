#!/bin/sh

VAULT_DIR='Your Obsidian Vault root folder'
CODE_DIR='.'
PORT=Your exposed port
IMAGE_TAG='quartz:latest' # Any image tag you like
CONTAINER_NAME='quartz'   # Any container name you like
CLEAN_VAULT=false         # True if preferred to clean the content/ folder and copy the vault from scratch

clean_vault(){
    find ${CODE_DIR}/content -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +
}

clean_all(){
    docker container rm -f ${CONTAINER_NAME}
    docker image rm -f ${IMAGE_TAG}
    clean_vault
}

copy_vault(){
    if [ "${CLEAN_VAULT}" = true ]; then
        clean_vault
    fi

    cp -r ${VAULT_DIR}/[^.]* ${CODE_DIR}/content/
}

build(){
    copy_vault
    docker build -q ${CODE_DIR} -t ${IMAGE_TAG}
}

run_preview(){
    docker run --rm -itp ${PORT}:8080 --name ${CONTAINER_NAME} --net nas ${IMAGE_TAG}
}

run_start(){
    docker run -d --name ${CONTAINER_NAME} -p ${PORT}:8080 --restart=unless-stopped --net nas ${IMAGE_TAG}
}

run_build_start(){
    copy_vault
    VAULT_DIR=${VAULT_DIR} CODE_DIR=${CODE_DIR} PORT=${PORT} IMAGE_TAG=${IMAGE_TAG} CONTAINER_NAME=${CONTAINER_NAME} docker-compose -f docker-compose.yml up -d
}

run_build_restart(){
    docker-compose -f docker-compose.yml down
    clean_all
    run_build_start
}

case $1 in
    clean)
    clean_all
    ;;
    clean_vault)
    clean_vault
    ;;
    # build)
    # build
    # ;;
    preview)
    clean_all
    build
    run_preview
    ;;
    # start)
    # clean
    # build
    # run_start
    # ;;
    compose_start)
    run_build_start
    ;;
    compose_restart)
    CLEAN_VAULT=true
    run_build_restart
    ;;
esac
