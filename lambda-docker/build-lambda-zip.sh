#!/bin/bash
#
# Builds a zip file for an AWS lambda layer.
#
# Has to be run in a container with following dirs/files:
#   /workdir
#   /workdir/requirements.txt
#   /workdir/build-lambda-zip.sh
#
#
# $1 : "project-name"-env.zip target name for the final zip
#
# ex. build-lambda-zip.sh "my-project" 
#      output: my-project-env-Pythonx.x.x.zip
#
# Copyright (C) 2020, Jesper Rix <rixjesper@gmail.com>
set -ex

PYTHON_VERS="$(python -V | sed 's/ //g' | tr '[:upper:]' '[:lower:]')"
TARGET="${1}-env-${PYTHON_VERS}.zip"

CURDIR=/workdir

# Create a temporary folder for intermediate build
BUILD_DIR=${CURDIR}/tmp_build_$(date +%H%M%S)
PYTHON_INSTALL_DIR=${BUILD_DIR}/python

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Check if requirements file exists
[ ! -f "${CURDIR}/requirements.txt" ] && echo "No such file: ${CURDIR}/requirements.txt" && exit 1

# copy the requirements file into the working dir
cp $CURDIR/requirements.txt $BUILD_DIR/requirements.txt

# Install requirements for building in docker container
pip install -r requirements.txt

# install same requirements in output dir
pip install -r requirements.txt --target $PYTHON_INSTALL_DIR

HAS_PYARROW=0
if grep -q 'pyarrow.*' requirements.txt; then
    HAS_PYARROW=1
    echo "build pyarrow"
fi

HAS_NUMPY=0
if grep -q 'numpy.*' requirements.txt; then
    HAS_NUMPY=1
    version=$(grep 'numpy' requirements.txt)
    echo "build ${version}"
    rm -rf $PYTHON_INSTALL_DIR/numpy
    rm -rf $PYTHON_INSTALL_DIR/numpy-*
    # Let numpy.libs be there
    pip install --no-cache-dir --compile --global-option=build_ext --global-option="-j 4" $version --target $PYTHON_INSTALL_DIR
fi

HAS_SCIPY=0
if grep -q 'scipy.*' requirements.txt; then
    HAS_SCIPY=1
    version=$(grep 'scipy' requirements.txt)
    echo "build ${version}"
    rm -rf $PYTHON_INSTALL_DIR/scipy*
    pip install --no-cache-dir --compile --global-option=build_ext --global-option="-j 4" $version --target $PYTHON_INSTALL_DIR
fi

HAS_PANDAS=0
if grep -q 'pandas.*' requirements.txt; then
    HAS_PANDAS=1
    version=$(grep 'pandas' requirements.txt)
    echo "build ${version}"
    rm -rf $PYTHON_INSTALL_DIR/pandas*
    pip install --no-cache-dir --compile --global-option=build_ext --global-option="-j 4" $version --target $PYTHON_INSTALL_DIR
fi

# TODO remove
ls -la $PYTHON_INSTALL_DIR | grep numpy

# TODO try without numpy
if [ $HAS_PYARROW -eq 1 ]; then
    echo "build pyarrow"
    export ARROW_HOME=$(pwd)/dist
    export LD_LIBRARY_PATH=$(pwd)/dist/lib:$LD_LIBRARY_PATH

    pyarrow_version=$(grep 'pyarrow' $BUILD_DIR/requirements.txt | awk -F'==' '{print $2}')

    git clone \
    --branch apache-arrow-$pyarrow_version \
    --single-branch \
    https://github.com/apache/arrow.git

    #git clone \
    #--branch apache-arrow-0.16.0 \
    #--single-branch \
    #https://github.com/apache/arrow.git

    mkdir dist
    mkdir arrow/cpp/build
    pushd arrow/cpp/build

    cmake3 \
        -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DARROW_FLIGHT=OFF \
        -DARROW_GANDIVA=OFF \
        -DARROW_ORC=OFF \
        -DARROW_WITH_SNAPPY=ON \
        -DARROW_WITH_ZLIB=ON \
        -DARROW_PARQUET=ON \
        -DARROW_CSV=OFF \
        -DARROW_PYTHON=ON \
        -DARROW_PLASMA=OFF \
        -DARROW_BUILD_TESTS=OFF \
        -GNinja \
        ..

    ninja-build
    ninja-build install

    popd

    pushd arrow/python

    export ARROW_PRE_0_15_IPC_FORMAT=0
    export PYARROW_WITH_HDFS=0
    export PYARROW_WITH_FLIGHT=0
    export PYARROW_WITH_GANDIVA=0
    export PYARROW_WITH_ORC=0
    export PYARROW_WITH_CUDA=0
    export PYARROW_WITH_PLASMA=0
    export PYARROW_WITH_PARQUET=1
    export ARROW_PYTHON_INCLUDE_DIR=$BUILD_DIR/dist/include

    python setup.py build_ext \
      --build-type=release \
      --bundle-arrow-cpp \
      bdist_wheel

    #pip install dist/pyarrow-*.whl -t /aws-data-wrangler/dist/pyarrow_files
    pip install dist/pyarrow-*.whl -t $BUILD_DIR/pyarrow-files

    popd

    rm -f $BUILD_DIR/pyarrow_files/pyarrow/libarrow.so
    rm -f $BUILD_DIR/pyarrow_files/pyarrow/libparquet.so
    rm -f $BUILD_DIR/pyarrow_files/pyarrow/libarrow_python.so

    rm -rf $BUILD_DIR/python/pyarrow*
    rm -rf $BUILD_DIR/python/boto*

    # TODO 
    cp -r python/ python_before_pyarrow
    cp -r $BUILD_DIR/pyarrow-files/pyarrow* python/

fi

# TODO remove
ls -la $PYTHON_INSTALL_DIR | grep numpy

cd $BUILD_DIR

echo "size before stipping of tests: $(du -hs python/ | cut -f1)"

# Remove all test dirs
find python -wholename "*/tests/*" -type f -delete

echo "Total size of unpacked layer: $(du -hs python/ | cut -f1)"

echo "zipping the layer into $TARGET"
# Create the zip
zip -q -r9 "${CURDIR}/${TARGET}" ./python

cd $CURDIR

# Removing temporary build dir
# TODO add again
#rm -rf $BUILD_DIR
