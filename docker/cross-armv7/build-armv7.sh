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

 rm -rf ../../api/target/arm-unknown-linux-gnueabihf/release

 sed -i "s/""$docker_tag_cross_postgres""/""$docker_tag_cross""/g" ../../api/Cross.toml
 docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(dirname $(dirname `pwd`))/api:/code cross-pi-runner cross build --target=arm-unknown-linux-gnueabihf --release

 sed -i "s/""$docker_tag_cross""/""$docker_tag_cross_postgres""/g" ../../api/Cross.toml
 docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(dirname $(dirname `pwd`))/api:/code cross-pi-runner cross build --target=arm-unknown-linux-gnueabihf --release

 cp ../../api/target/arm-unknown-linux-gnueabihf/release/recipes_api dist/