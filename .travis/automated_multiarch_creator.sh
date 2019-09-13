#!/usr/bin/env bash

# Examples:
# ./automated_multiarch_creator.sh -o treehouses -r kolibri -a 0.10.3 -m arm -s arm64 -d amd64
while getopts "o:r:a:m:s:d:" option; do
  case "$option" in
    o) DOCKER_ORG=${OPTARG};;
    r) DOCKER_REPO=${OPTARG};;
    a) IMAGE_ALIAS=${OPTARG};;
    m) ARM_IMAGE=${OPTARG};;
    s) ARM64_IMAGE=${OPTARG};;
    d) AMD64_IMAGE=${OPTARG};;
  esac
done

create_multiarch_manifest(){
    # FIXME: make architecture dynamic
    local TARGET_IMAGE=${1}
    local ARM_IMAGE=${2}
    local AMD64_IMAGE=${3}
#     local ARM64_IMAGE=${4}
    echo Creating multiarch manifest
    {
        yq n image ${TARGET_IMAGE} | \
        yq w - manifests[0].image ${ARM_IMAGE} | \
        yq w - manifests[0].platform.architecture arm | \
        yq w - manifests[0].platform.os linux | \
        yq w - manifests[1].image ${AMD64_IMAGE} | \
        yq w - manifests[1].platform.architecture amd64 | \
        yq w - manifests[1].platform.os linux | \
#         yq w - manifests[2].image ${ARM64_IMAGE} | \
#         yq w - manifests[2].platform.architecture arm64 | \
#         yq w - manifests[2].platform.os linux | \
        tee ma_manifest.yaml
    }
}

deploy_multiarch_manifest(){
    echo Pushing Multiarch Manifests to cloud
    manifest_tool push from-spec ma_manifest.yaml
    echo Successfully Pushed Multiarch Manifests to cloud

}

main(){
    docker login --username="$DOCKER_USER" --password="$DOCKER_PASS"
    local TARGET_IMAGE=${DOCKER_ORG}/${DOCKER_REPO}:${IMAGE_ALIAS}
    local BRANCH=$(if [ ${TRAVIS_PULL_REQUEST} == "false" ]; then echo ${TRAVIS_BRANCH}; else echo ${TRAVIS_PULL_REQUEST_BRANCH}; fi)
    if [ "$BRANCH" = "master" ]; then
#         create_multiarch_manifest ${TARGET_IMAGE} ${ARM_IMAGE} ${AMD64_IMAGE} ${ARM64_IMAGE}
        create_multiarch_manifest ${TARGET_IMAGE} ${ARM_IMAGE} ${AMD64_IMAGE}
        deploy_multiarch_manifest
    else
        echo Branch is NOT master so no need to push multiarch manifests to registry!
    fi
    docker logout
}

main
