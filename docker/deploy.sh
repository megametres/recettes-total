#!/bin/bash

cd ..
# Load the .env file
. .env

# Ensure the version is correct
make version

# Setup the environment to local
make local

cd docker

docker buildx build . --file Dockerfile-rust-armv7 --platform linux/arm/v7 --tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION --load

# push the image to the registry
make d push $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION

cd ..
# Setup the environment to prod
make prod

# pull the image from the registry
make d pull $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION

# Set the tag local
make d tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION $PROJECT_NAME"_rust_armv7":$API_VERSION

# Start the App
make up