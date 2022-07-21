#!/bin/bash
#set -x
set -e

if [[ $# -ne 5 && $# -ne 6 ]] ; then
    echo 'Usage:: rollback.sh [env] [cluster name] [package name] [ecr repo] [ecr tag] [region:: default ap-northeast-2]'
    exit 1
fi

if [[ $# -eq 6 ]]
then
    REGION=$6
else
    REGION="ap-northeast-2"
fi

if [[ "$1" -ne "prd" || "$1" -ne "stg" || "$1" -ne "dev" ]] ; then
    echo 'The value of env parameter should be one of "prd", "stg", "dev"'
fi

ENV=$1
CLUSTER_NAME=$2
PACKAGE_NAME=$3
REPO=$4
TAG=$5

MANIFEST_TO_BE_LATEST=($(aws ecr describe-images --region ap-northeast-2 \
--repository-name ${REPO} \
--output text \
--query 'sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]' \
| grep ${TAG} | tr '\t' '\n'  | tail -2))

CURR_IMAGE_TAG=${MANIFEST_TO_BE_LATEST[1]}
PREV_IMAGE_TAG=${MANIFEST_TO_BE_LATEST[0]}
echo "current image tag : ${CURR_IMAGE_TAG}"
echo "previous image tag: ${PREV_IMAGE_TAG}"

TODAY=`date +%Y%m%d-%H%M%S`
#echo $TODAY
#echo "rollback-${TODAY}"

CURR_IMAGE_MANIFEST=$(aws ecr batch-get-image --repository-name ${REPO} --image-ids imageTag=${CURR_IMAGE_TAG} --region ${REGION} --output json | jq --raw-output --join-output '.images[0].imageManifest')
PREV_IMAGE_MANIFEST=$(aws ecr batch-get-image --repository-name ${REPO} --image-ids imageTag=${PREV_IMAGE_TAG} --region ${REGION} --output json | jq --raw-output --join-output '.images[0].imageManifest')

#echo "curr image manifest: ${CURR_IMAGE_MANIFEST}"
#echo "prev image manifest: ${PREV_IMAGE_MANIFEST}"

echo "ECR Image Tag Rollback:: Change ${PREV_IMAGE_TAG} to ${CURR_IMAGE_TAG}"
#aws ecr put-image --repository-name ${REPO} --image-tag "rollback-${TODAY}" --image-manifest ${CURR_IMAGE_MANIFEST} --region ${REGION}
#aws ecr put-image --repository-name ${REPO} --image-tag ${CURR_IMAGE_TAG} --image-manifest ${PREV_IMAGE_MANIFEST} --region ${REGION}

echo "Rollback Deploy:: cluster:${CLUSTER_NAME} service:${PACKAGE_NAME}-${ENV}"
#aws ecs update-service --cluster "${CLUSTER_NAME}" --service "${PACKAGE_NAME}-${ENV}" --force-new-deployment
