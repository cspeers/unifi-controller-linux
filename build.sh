#!/usr/bin/env bash
source build.config
echo "building $IMAGE_NAME:$IMAGE_TAG -  $APPLICATION_NAME"
#docker build -t $IMAGE_NAME:$DOCKER_IMAGE_TAG -t $IMAGE_NAME:$IMAGE_TAG --build-arg UNIFI_VERSION=$DOCKER_APPLICATION_VERSION --build-arg BASE_IMAGE=${DOCKER_IMAGE_BASE} --build-arg LAST_UPDATE=$(date "+%m/%d/%y") .
docker build -t $IMAGE_NAME:$IMAGE_TAG \
    --progress=plain  \
    --build-arg UNIFI_VERSION=$DOCKER_APPLICATION_VERSION \
    --build-arg BASE_IMAGE=${DOCKER_IMAGE_BASE} \
    --build-arg LAST_UPDATE=$(date "+%m/%d/%y") .
