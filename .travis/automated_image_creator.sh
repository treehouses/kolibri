#!/usr/bin/env bash

# Examples:
# ./automated_image_creator.sh -o midtrans -r base -a debian -p ./base_debian
while getopts "o:r:a:p:f:" option; do
  case "$option" in
    o) DOCKER_ORG=${OPTARG};;
    r) DOCKER_REPO=${OPTARG};;
    a) IMAGE_ALIAS=${OPTARG};;
    p) IMAGE_BUILD_TARGET_PATH=${OPTARG};;
    f) IMAGE_DOCKERFILE=${OPTARG};;
  esac
done

build_message() {
    # $1 = build message
    echo
    echo =========BUILD MESSAGE=========
    echo "$@"
    echo ===============================
    echo
}

login_docker() {
    if [[ -z "$DOCKER_USER" ]] || [[ -z "$DOCKER_PASS" ]]; then
        build_message 'Either DOCKER_USER or DOCKER_PASS environment variable does not exist, please set it up in pipeline setting!'
        exit 1
    fi
    docker login --username="$DOCKER_USER" --password="$DOCKER_PASS"
}

fallback_env() {
    local TARGET_VARIABLE="$1"
    local FALLBACK_VALUE="$2"
    local CURRENT_VALUE=$(env | grep "^${TARGET_VARIABLE}=" | awk -F '=' '{print $2}')

    echo "${CURRENT_VALUE}"

    if [[ -z "$CURRENT_VALUE" ]]; then
        build_message "${TARGET_VARIABLE} is not set and will defaulting to ${FALLBACK_VALUE}"
        eval "export ${TARGET_VARIABLE}=${FALLBACK_VALUE}"
    fi
}

package_image() {
    local BRANCH=${1}
    local IMAGE_NAME=${2}
    local IMAGE_NAME_LATEST=${3}

    echo "== Packing image"
    build_message processing ${IMAGE_NAME}
    if [ ! -z ${IMAGE_DOCKERFILE} ]; then
        docker build -t ${IMAGE_NAME} -f ${IMAGE_BUILD_TARGET_PATH}/${IMAGE_DOCKERFILE} ${IMAGE_BUILD_TARGET_PATH} || exit 1
    else
        docker build -t ${IMAGE_NAME} ${IMAGE_BUILD_TARGET_PATH} || exit 1
    fi
    build_message done processing ${IMAGE_NAME}
    if [ ${BRANCH} = "master" ]
    then
        build_message processing ${IMAGE_NAME_LATEST}
        docker tag ${IMAGE_NAME} ${IMAGE_NAME_LATEST}
        build_message done processing ${IMAGE_NAME_LATEST}
    fi
}

push_image() {
    local BRANCH=${1}
    local IMAGE_NAME=${2}
    local IMAGE_NAME_LATEST=${3}

    echo "== Pushing image"
    build_message processing ${IMAGE_NAME}
    docker push ${IMAGE_NAME}
    build_message done processing ${IMAGE_NAME}
    if [ ${BRANCH} = "master" ]; then
        build_message processing ${IMAGE_NAME_LATEST}
        docker push ${IMAGE_NAME_LATEST}
        build_message done processing ${IMAGE_NAME_LATEST}
    fi
}

delete_image() {
    local BRANCH=${1}
    local IMAGE_NAME=${2}
    local IMAGE_NAME_LATEST=${3}

    echo "== Deleting image"
    build_message processing ${IMAGE_NAME}
    docker rmi -f ${IMAGE_NAME}
    build_message done processing ${IMAGE_NAME}
    if [ ${BRANCH} = "master" ]; then
        build_message processing ${IMAGE_NAME_LATEST}
        docker rmi -f ${IMAGE_NAME_LATEST}
        build_message done processing ${IMAGE_NAME_LATEST}
    fi
}

main() {
    local BRANCH=$(git rev-parse --abbrev-ref HEAD)
    local COMMIT=$(git rev-parse --short HEAD)
    local IMAGE_GLOBAL_VERSION=$(cat package.json | grep version | awk '{print$2}' | awk '{print substr($0, 2, length($0) - 3)}')

    if [[ ! -z ${IMAGE_ALIAS} ]]; then
        IMAGE_ALIAS_WITH_SEPARATOR=${IMAGE_ALIAS}-
        IMAGE_LATEST_TAG=${IMAGE_ALIAS}
    else
        IMAGE_ALIAS_WITH_SEPARATOR=""
        IMAGE_LATEST_TAG="latest"
    fi

    local IMAGE_NAME=${DOCKER_ORG}/${DOCKER_REPO}:${IMAGE_ALIAS_WITH_SEPARATOR}${BRANCH}-${COMMIT}-${IMAGE_GLOBAL_VERSION}
    local IMAGE_NAME_LATEST=${DOCKER_ORG}/${DOCKER_REPO}:${IMAGE_LATEST_TAG}

    echo Full name: ${IMAGE_NAME}
    echo Full latest name: ${IMAGE_NAME_LATEST}
    echo Build path: ${IMAGE_BUILD_TARGET_PATH}
    login_docker
    package_image ${BRANCH} ${IMAGE_NAME} ${IMAGE_NAME_LATEST}
    push_image ${BRANCH} ${IMAGE_NAME} ${IMAGE_NAME_LATEST}
    docker logout
    delete_image ${BRANCH} ${IMAGE_NAME} ${IMAGE_NAME_LATEST}
}

main
