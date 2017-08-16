#!/bin/sh

NOA_HOME=${HOME}/.noa

if [ ! -d ${NOA_HOME}/pgdc/pgdata ];
then
  echo "Looks like Noa is not setup."
  echo "Run ./noa_docker_setup.sh to create a new Noa environment."
  exit 1
fi

echo "> Bringing down Noa Containers"
sudo docker-compose down

echo "> Twiddling a bit before wiping off ${NOA_HOME}"
sleep 6

echo "> rm -rf ${NOA_HOME}"
sudo rm -rf ${NOA_HOME}

echo "> Done! You can start all over by running ./noa_docker_setup.sh"
