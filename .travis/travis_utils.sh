#!/bin/bash

build_message(){
    # $1 = build message
    echo
    echo =========BUILD MESSAGE=========
    echo "$@"
    echo ===============================
    echo
}

login_docker(){
  docker login --username=$DOCKER_USER --password=$DOCKER_PASS
}

prepare_ci(){
  DOCKER_ORG=treehouses
  DOCKER_REPO=kolibri-tags
  BRANCH=$TRAVIS_BRANCH
  COMMIT=${TRAVIS_COMMIT::8}
}

push_a_docker(){
  build_message pushing $1
	docker push $1
	build_message done pushing $1
}

tag_a_docker(){
  build_message processing $2
	docker tag $1 $2
	build_message done processing $2
}

prepare_kolibri_amd64(){
  build_message prepare Kolibri amd64 docker...
  KOLIBRI_AMD64=$DOCKER_ORG/$DOCKER_REPO:amd64-$BRANCH-$COMMIT
  KOLIBRI_AMD64_LATEST=$DOCKER_ORG/$DOCKER_REPO:amd64-latest
}

prepare_kolibri_arm(){
  build_message prepare Kolibri arm docker...
  KOLIBRI_ARM=$DOCKER_ORG/$DOCKER_REPO:arm-$BRANCH-$COMMIT
  KOLIBRI_ARM_LATEST=$DOCKER_ORG/$DOCKER_REPO:arm-latest
}


prepare_kolibri_aarch64(){
  build_message prepare Kolibri aarch64 docker...
  KOLIBRI_AARCH64=$DOCKER_ORG/$DOCKER_REPO:aarch64-$BRANCH-$COMMIT
  KOLIBRI_AARCH64_LATEST=$DOCKER_ORG/$DOCKER_REPO:aarch64-latest
}

prepare_multiarch_manifest_tool(){
  build_message Prepare Manifest tool
  sudo wget -O /usr/local/bin/manifest_tool https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-amd64
  sudo chmod +x /usr/local/bin/manifest_tool
  mkdir -p /tmp/MA_manifests
}

prepare_yq(){
  build_message Prepare yq
  sudo wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/1.14.1/yq_linux_amd64
  sudo chmod +x /usr/local/bin/yq
}

prepare_everything(){
  prepare_ci
  prepare_kolibri_amd64
  prepare_kolibri_arm
  prepare_kolibri_aarch64
  prepare_multiarch_manifest_tool
  prepare_yq
}

package_docker(){
  # $1: directory
  # $2: tag
  # $3: tag latest
  build_message processing $2
  nohup bell &
  docker build -f $1 -t $2 .
  if [ "$BRANCH" = "master" ]
	then
		tag_a_docker $2 $3
	fi
}

push_docker(){
  # $1: tag
  # $2: tag latest
  push_a_docker $1
	if [ "$BRANCH" = "master" ]
	then
	  push_a_docker $2
	fi
}

tag_docker(){
  # $1: tag old
  # $2: tag new
  tag_a_docker $1 $2
	if [ "$BRANCH" = "master" ]
	then
	  tag_a_docker $1 $3
	fi
}

delete_docker(){
  # $1: tag
  # $2: tag latest
	docker rmi -f $1
	if [ "$BRANCH" = "master" ]
	then
		docker rmi -f $2
  fi
}

deploy_docker(){
  # $1: directory
  # $2: tag
  # $3: tag latest
	login_docker
	package_docker $1 $2 $3
	push_docker $2 $3
}

bell() {
  while true; do
    echo -e "\a"
    sleep 60
  done
}

create_multiarch_manifest_kolibri(){
    build_message Creating Kolibri Multiarch Manifests
    if [ "$BRANCH" = "master" ]
    then
        # $1: latest arm
        # $2: latest amd64   
        # $3: latest aarch64 (arm64)
        yq n image treehouses/kolibri:latest | \
        yq w - manifests[0].image $1 | \
        yq w - manifests[0].platform.architecture arm | \
        yq w - manifests[0].platform.os linux | \
        yq w - manifests[1].image $2 | \
        yq w - manifests[1].platform.architecture amd64 | \
        yq w - manifests[1].platform.os linux | \
        yq w - manifests[2].image $3 | \
        yq w - manifests[2].platform.architecture arm64 | \
        yq w - manifests[2].platform.os linux | \
        tee /tmp/MA_manifests/MA_kolibri_latest.yaml
    else
        build_message Branch is Not master so no need to create Multiarch manifests for kolibri.
    fi
}

push_multiarch_manifests(){
    build_message Pushing Multiarch Manifests to cloud
    if [ "$BRANCH" = "master" ]
    then
        manifest_tool push from-spec /tmp/MA_manifests/MA_kolibri_latest.yaml
        build_message Successfully Pushed Multiarch Manifests to cloud
    else
         build_message Branch is Not master so no need to Push Multiarch Manifests to cloud
    fi
}
