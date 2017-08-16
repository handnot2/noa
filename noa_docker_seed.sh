#!/bin/sh

NOA_HOME=${HOME}/.noa

if [ ! -d ${NOA_HOME}/pgdc/pgdata ];
then
  echo "Run noa_docker_setup.sh before using this."
  echo "This is supposed to be run once after setup."
  exit 1
fi

echo "> Performing Ecto migration"
sudo docker-compose exec noa bin/noa migrate

echo "> Seeding data"
sudo docker-compose exec noa bin/noa seed seeds/demo_seed_data.yml > \
  ${NOA_HOME}/seed_output.txt

echo "> Done. Hopefully things worked without any issues!"
echo "> The seed results are made available in"
echo "> ${NOA_HOME}/seed_output.txt file. Keep this file."
echo "> You will need it later."
echo ""
echo "Next Steps:"
echo "1. Run: sudo docker-compose down"
echo "2. Bring it back up again: sudo docker-compose up -d"
echo "   Noa should be up and running. Confirm this."
echo "3. Run: sudo docker-compose logs noa"
echo "   You should see that Phoenix is listening on port 4000"
echo "4. Time to fire up Noa Playground to checkout your own OAuth2 server"
echo "   Head over to https://github.com/handnot2/noa_playground"
echo "   for further instructions on Noa Playground."
echo ""
echo "At this point you can use the standard docker-compose commands"
echo "to work with this setup."
echo ""
echo "If you want to stop Noa, just run: sudo docker-compose down."
echo "Use ./noa_docker_cleanup.sh to wipe off this Noa setup."
