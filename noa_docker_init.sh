#!/bin/sh

if [ "x$1" = "x" -o -e "$1" ];
then
  echo "Provide name of a new directory to create"
  echo "Usage: noa_docker_init.sh new-directory-to-create"
  exit 1
fi

NOA_HOME="$1"

echo "> Creating ${NOA_HOME}"
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
echo "> Creating docker-compose.yml"
cp docker-compose.tmpl ${NOA_HOME}/docker-compose.yml
echo "> Copying seeding script: noa_docker_seed.sh"
cp noa_docker_seed.sh ${NOA_HOME}/
echo "> Copying README file"
cp README.tmpl ${NOA_HOME}/README.md

echo ""
echo "Next Steps: (covered in ${NOA_HOME}/README.md)"
echo "1. cd ${NOA_HOME}"
echo "2. Edit seeds/ro_quickstart.creds file and add end user credentials"
echo "   one per line. Format is: username:password"
echo "   Make sure each is a minimum of 4 characters."
echo "   **Keep a copy** of this ro_quickstart.creds somewhere else"
echo "   so you can copy that back here next time."
echo "3. Optional. Take a look at seeds/demo_seed_data.yml"
echo "   Hold off on making any changes to this yet. You can try making"
echo "   changes after you have played with the setup."
echo "4. After you completed the above steps, run ./noa_docker_seed.sh"
