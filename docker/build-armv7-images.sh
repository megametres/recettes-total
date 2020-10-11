#!/bin/bash

if [[ "$#" -ne  "0" ]] && [[ $1 == "-a" || $1 == "-r" ]]
then
    if [[ "$1" == "-a" ]]
    then
        NEED_ANGULAR=true
        NEED_RUST=false
    else
        NEED_ANGULAR=false
        NEED_RUST=true
    fi
else
    NEED_ANGULAR=true
    NEED_RUST=true
fi

if [[ $NEED_RUST ]]
then
    cd cross-armv7
    ./build-armv7-rust-binary.sh
    cd ..
fi

cd ..
# Load the .env file
. .env

# Ensure the version is correct
make version

# Setup the environment to local
make local

cd docker

# Build api
$NEED_RUST && docker buildx build . --no-cache --file Dockerfile-rust-armv7 --platform linux/arm/v7 --tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION --load
# Build frontend
$NEED_ANGULAR && docker buildx build ../frontend --no-cache --file Dockerfile-angular --platform linux/arm/v7 --tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION --load

cd ..

# push the rust image to the registry
$NEED_RUST && make push "$DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION"
# push the angular image to the registry
$NEED_ANGULAR && make push $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION

# Setup the environment to prod
make prod

# pull the rust image from the registry
$NEED_RUST && make pull $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION
# pull the angular image from the registry
$NEED_ANGULAR && make pull $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION

# Set the tag local
$NEED_RUST && make tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION $PROJECT_NAME"_rust_armv7":$API_VERSION
$NEED_ANGULAR && make tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION $PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION

# Remove the unnecessary imae tag
$NEED_RUST && make rmi $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION
$NEED_ANGULAR && make rmi $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION

# Leave the environment setup to local
make local