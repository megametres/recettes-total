#!/bin/bash

cd ..
# Load the .env file
. .env

# Ensure the version is correct
make version

# Setup the environment to local
make local

cd docker

# Build api
docker buildx build . --no-cache --file Dockerfile-rust-armv7 --platform linux/arm/v7 --tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION --load
# Build frontend
docker buildx build ../frontend --no-cache --file Dockerfile-angular --platform linux/arm/v7 --tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION --load

cd ..

# push the rust image to the registry
make push "$DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION"
# push the angular image to the registry
make push $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION

# Setup the environment to prod
make prod

# pull the rust image from the registry
make pull $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION
# pull the angular image from the registry
make pull $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION

# Set the tag local
make tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION $PROJECT_NAME"_rust_armv7":$API_VERSION
make tag $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION $PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION

# Remove the unnecessary imae tag
make rmi $DEPLOYMENT_REGISTRY$PROJECT_NAME"_rust_armv7":$API_VERSION
make rmi $DEPLOYMENT_REGISTRY$PROJECT_NAME"_angular_armv7":$FRONTEND_VERSION

# Leave the environment setup to local
make local