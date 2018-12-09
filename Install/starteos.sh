# be sure that the docker daemon is running before you start this script
#
# this script will create an alias at the end, so please run it with:
#
# source starteos.sh
#
# see https://developers.eos.io/eosio-nodeos/docs/docker-quickstart

docker pull eosio/eos-dev:v1.2.5 # pull eosio image
docker network create eosdev # create an eos network(see docker networking)

docker run --name nodeos -d -p 8888:8888 --network eosdev \
-v /tmp/eosio/work:/work -v /tmp/eosio/data:/mnt/dev/data  \
-v /tmp/eosio/config:/mnt/dev/config eosio/eos-dev:v1.2.5  \
/bin/bash -c "nodeos -e -p eosio --plugin eosio::producer_plugin \
--plugin eosio::history_plugin --plugin eosio::chain_api_plugin \
--plugin eosio::history_api_plugin \
 --plugin eosio::http_plugin -d /mnt/dev/data \
--config-dir /mnt/dev/config \
--http-server-address=0.0.0.0:8888 \
--access-control-allow-origin=* --contracts-console --http-validate-host=false"


# run keosd container

docker run -d --name keosd -p 9876:9876 --network=eosdev \
-i eosio/eos-dev:v1.2.5 /bin/bash -c "keosd --http-server-address=0.0.0.0:9876"

# check nodeos

echo "Check Nodeos"

docker logs --tail 10 nodeos

# check keosd

echo "Check Keosd"

docker exec keosd bash -c "cleos --wallet-url http://127.0.0.1:9876 wallet list keys"

echo "Please Ignore the No available wallet message"

# check nodeos endpoints

echo "Check Nodeeos endpoints"

curl http://localhost:8888/v1/chain/get_info | jq .

# find IP of keosd
# you can do this manually, we use jq

echo "Find Keosd IP address.."

IPADDRESS="$(docker network inspect eosdev | jq -r '.[].Containers[] | select(.Name=="keosd").IPv4Address')"

echo "Complete output: ${IPADDRESS}"
# set alias

alias cleos='docker exec -it nodeos /opt/eosio/bin/cleos --url http://localhost:8888 --wallet-url http://${IPADDRESS%/*}:9876'