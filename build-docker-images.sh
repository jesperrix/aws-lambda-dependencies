#!/bin/bash
set -ex

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd $SCRIPT_DIR/lambda-docker

# Pointing explicitly to Dockerfile due to git in a symlinked folder
docker build \
    -f DockerFile \
    -t aws-lambda-dependencies-py3.8 \
    --build-arg base_image=lambci/lambda:build-python3.8 \
    --build-arg py_dev=python3.8-devel \
    .

popd
