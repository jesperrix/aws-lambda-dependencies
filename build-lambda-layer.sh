#!/bin/bash
#
# Builds a zip file for an AWS lambda layer.
#
# $1 : requirements file : path to requirements file e.g. ./project/requirements.txt
# $2 : target name : name for the final zip e.g. "my-project"-pyxx-env.zip
#
# example: ./build-lambda-layer.sh /path/to/requirements.txt "my-project"
#             output: my-project-env-Pythonx.x.x.zip
#
# Copyright (C) 2020, Jesper Rix <rixjesper@gmail.com>

set -ex

# Current scirpt dir
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Current working dir
CUR_DIR=$(pwd)

# REQUIREMENTS_FILE dir and filename
REQUIREMENTS_FILE="${1}"
REQUIREMENTS_FILE_DIR="$(cd "$(dirname "$REQUIREMENTS_FILE" )" && pwd )"
REQUIREMENTS_FILE_NAME="$(basename $REQUIREMENTS_FILE)"
REQUIREMENTS_FILE_ABS=$REQUIREMENTS_FILE_DIR/$REQUIREMENTS_FILE_NAME

# Name of output
TARGET_NAME="${2}"

# Check arguments
[ ! -f "$REQUIREMENTS_FILE" ] && echo "No such file: $REQUIREMENTS_FILE" && exit 1
[ "$TARGET_NAME" = "" ] && echo "No target name: $REQUIREMENTS_FILE" && exit 1

# TODO when adding other python runtimes use different docker images
docker run \
    -v${CUR_DIR}:/workdir \
    -v${REQUIREMENTS_FILE_ABS}:/workdir/requirements.txt \
    -v${SCRIPT_DIR}/lambda-docker/build-lambda-zip.sh:/workdir/build-lambda-zip.sh \
    --workdir /workdir \
    -it \
    --rm \
    aws-lambda-dependencies-py3.8 \
    build-lambda-zip.sh $TARGET_NAME

# For debugging
#docker run \
    #-v${CUR_DIR}:/workdir \
    #-v${REQUIREMENTS_FILE_ABS}:/workdir/requirements.txt \
    #-v${SCRIPT_DIR}/lambda-docker/build-lambda-zip.sh:/workdir/build-lambda-zip.sh \
    #--workdir /workdir \
    #-it \
    #--rm \
    #--entrypoint "" \
    #aws-lambda-dependencies-py3.8 \
    #bash
