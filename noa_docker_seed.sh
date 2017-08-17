#!/bin/sh

if [ -f seed_output.txt ];
then
  echo "noa_docker_seed.sh can be run only once."
  echo "If you faced problems earlier and are trying"
  echo "run again, it is better to remove this directory"
  echo "and start over. Just keep a copy of seeds/ro_quickstart.creds"
  echo "somewhere else you can quickly copy it over when you"
  echo "start afresh. Just make sure that any partially created"
  echo "Docker containers are removed."
  exit 1
fi

echo "> Bringing up Postgresql"
sudo docker-compose up -d db

echo "> Twiddling while postgres starts up"
sleep 6

echo "> Bringup up Noa"
sudo docker-compose up -d noa

echo "> Bit more twiddling"
sleep 5

echo "> Performing Ecto migration"
sudo docker-compose exec noa bin/noa migrate

echo "> Seeding data"
sudo docker-compose exec noa bin/noa seed seeds/demo_seed_data.yml > \
  seed_output.txt

echo "> Done. Hopefully things worked without any issues!"
echo ""
echo "Next Steps:"
echo "1. Run: sudo docker-compose logs noa"
echo "   You should see that Phoenix is listening on port 4000"
echo "2. Keep the generated seed_output.txt file. It has information"
echo "   you need to work with Noa."
echo "3. Time to fire up Noa Playground to checkout your own OAuth2 server."
echo "   Head over to https://github.com/handnot2/noa_playground"
echo "   for further instructions on Noa Playground."
echo ""
echo "At this point you can use the standard docker-compose commands"
echo "to work with this setup."
echo ""
echo "If you want to stop Noa, just run: sudo docker-compose down."
echo "If you want to wipe off this setup use sudo rm -rf shell command."
