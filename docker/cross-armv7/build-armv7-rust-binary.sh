#!/bin/bash

docker_tag_cross=cross-pi
docker_tag_cross_postgres=cross-pi-postgres
docker_tag_runner=cross-runner

#Build images if required
test=$( docker images -q ${docker_tag_cross} )
if [[ -z "$test" ]]; then
  docker build -t ${docker_tag_cross} .
fi
test=$( docker images -q ${docker_tag_cross_postgres} )
if [[ -z "$test" ]]; then
  docker build -t ${docker_tag_cross_postgres} . --build-arg POSTGRES=true
fi
test=$( docker images -q ${docker_tag_runner} )
if [[ -z "$test" ]]; then
  docker build . -t ${docker_tag_runner} --file Dockerfile-cross-runner
fi

# Remove old builds
 rm -rf ../../api/target/arm-unknown-linux-gnueabihf/release

# Set the image in Cross.toml to $docker_tag_cross
 sed -i "s/""$docker_tag_cross_postgres""/""$docker_tag_cross""/g" ../../api/Cross.toml
 # First compilation that will fail
 docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(dirname $(dirname `pwd`))/api:/code $docker_tag_runner cross build --target=arm-unknown-linux-gnueabihf --release

# Set the image in Cross.toml to $docker_tag_cross
 sed -i "s/""$docker_tag_cross""/""$docker_tag_cross_postgres""/g" ../../api/Cross.toml
 # Second compilation that will passes
 docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(dirname $(dirname `pwd`))/api:/code $docker_tag_runner cross build --target=arm-unknown-linux-gnueabihf --release

# Copy the binary
 cp ../../api/target/arm-unknown-linux-gnueabihf/release/recipes_api dist/