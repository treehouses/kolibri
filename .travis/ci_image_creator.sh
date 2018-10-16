#!/usr/bin/env bash

# Examples:
# ./ci_image_creator.sh -p ./base_debian
while getopts "p:" option; do
  case "$option" in
    p) IMAGE_BUILD_TARGET_PATH=${OPTARG};
  esac
done

main() {
    local DOCKER_ORG=$(grep "^DOCKER_IMAGE_NAME=" ${IMAGE_BUILD_TARGET_PATH}/docker.env | awk -F '=' '{print $2}' | sed -e 's/^"//' -e 's/"$//' | awk -F '/' '{print $1}')
    local DOCKER_REPO=$(grep "^DOCKER_IMAGE_NAME=" ${IMAGE_BUILD_TARGET_PATH}/docker.env | awk -F '=' '{print $2}' | sed -e 's/^"//' -e 's/"$//' | awk -F '/' '{print $2}' | awk -F ':' '{print $1}')
    local IMAGE_ALIAS=$(grep "^DOCKER_IMAGE_NAME=" ${IMAGE_BUILD_TARGET_PATH}/docker.env | awk -F '=' '{print $2}' | sed -e 's/^"//' -e 's/"$//' | awk -F '/' '{print $2}' | awk -F ':' '{print $2}')

    ./.gitlab/automated_image_creator.sh -o ${DOCKER_ORG} -r ${DOCKER_REPO} -a ${IMAGE_ALIAS} -p ${IMAGE_BUILD_TARGET_PATH}
}

main
