#!/bin/sh

NOA_HOME=${HOME}/.noa

if [ -d ${NOA_HOME}/pgdc/pgdata ];
then
  echo "Noa Docker setup already exists at ${NOA_HOME}"
  echo "Run noa_docker_cleanup.sh first"
  exit 1
fi

echo "> Creating ${HOME}"
mkdir -p ${NOA_HOME}
mkdir -p ${NOA_HOME}/seeds

echo "> Creating noa.env file for docker-compose"
echo "POSTGRES_PASSWORD=${NOA_DB_PASSWORD:=postgres}"   >  ${NOA_HOME}/noa.env
echo "NOA_DB_PASSWORD=${NOA_DB_PASSWORD:=postgres}"     >> ${NOA_HOME}/noa.env
echo "NOA_SECRET_KEY_BASE=`openssl rand -base64 48`"    >> ${NOA_HOME}/noa.env
echo "NOA_STUBHANDLER_SECRET=`openssl rand -base64 48`" >> ${NOA_HOME}/noa.env

echo "> Copying seed data from priv/repo"
cp priv/repo/seed_data.yml ${NOA_HOME}/seeds/demo_seed_data.yml
echo "> Creating an empty resource owner credential file - ro_quickstart.creds"
touch ${NOA_HOME}/seeds/ro_quickstart.creds

echo "> Bringing up Postgresql"
sudo docker-compose up -d db

echo "> Twiddling while postgres starts up"
sleep 6

echo "> Bringup up Noa"
sudo docker-compose up -d noa

echo "> Bit more twiddling"
sleep 3

echo ""
echo "Next Steps:"
echo "1. Goto ${NOA_HOME}/seeds"
echo "2. Edit ro_quickstart.creds file and add end user credentials one per line."
echo "   Format is username:password"
echo "   Make sure each is a minimum of 4 characters."
echo "   **Keep a copy** of this ro_quickstart.creds somewhere else"
echo "   So you copy that back here next time."
echo "3. Optional. Take a look at ${NOA_HOME}/seeds/demo_seed_data.yml"
echo "   Hold off on making any changes to this yet. You can try making"
echo "   changes after you have played with the setup."
echo "4. After you completed the above steps, come back to this directory"
echo "   and run ./noa_docker_seed.sh"
