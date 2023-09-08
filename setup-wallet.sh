#!/bin/bash
docker kill akash
docker build -t akash .
echo "Welcome to Akash wallet creator and deployer"
echo "Setting up data directory at $(pwd)/data - do not delete this!"
mkdir data
echo "Getting the latest from Akash network to setup variables file"

function variables(){
rm variables
AKASH_NODE=https://akash-rpc.global.ssl.fastly.net:443
AKASH_NET="https://raw.githubusercontent.com/akash-network/net/master/mainnet"
AKASH_VERSION="$(curl -s "https://raw.githubusercontent.com/akash-network/net/master/mainnet/version.txt")"
AKASH_KEYRING_BACKEND=os
AKASH_CHAIN_ID="$(curl -s "https://raw.githubusercontent.com/akash-network/net/master/mainnet/chain-id.txt")"
#AKASH_NODE="$(curl -s "https://raw.githubusercontent.com/akash-network/net/master/mainnet/rpc-nodes.txt" | head -1)"
AKASH_KEY_NAME="default"

echo "AKASH_NODE=$AKASH_NODE" > variables
echo "AKASH_CHAIN_ID=$AKASH_CHAIN_ID" >> variables
echo "AKASH_KEYRING_BACKEND=$AKASH_KEYRING_BACKEND" >> variables
echo "AKASH_VERSION=$AKASH_VERSION" >> variables
echo "AKASH_NET=$AKASH_NET" >> variables
echo "AKASH_KEY_NAME=$AKASH_KEY_NAME" >> variables
}
variables

echo "Starting Akash in Docker"
docker run -itd --env-file=variables --rm --name akash -v $(pwd)/data:/root/.akash akash
#echo "Input a passphrase for your new wallet"
#read pass
pass=$1

docker exec -it akash /bin/bash -c "printf '$pass\n$pass\n' | akash keys add default" | grep 'Error' &> /dev/null
if [ $? == 0 ]; then
   echo "Wallet already exists"
fi
echo "Your wallet address is:"
docker exec -it akash /bin/bash -c "echo $pass | akash keys list | grep address | cut -d ':' -f2 | cut -c 2-"
ADDRESS=$(docker exec -it akash /bin/bash -c "echo $pass | akash keys list | grep address | cut -d ':' -f2 | cut -c 2-")
echo "AKASH_ACCOUNT_ADDRESS=$ADDRESS" >> variables
echo "Got address for the first time, restarting to inject variables"
docker kill akash ; docker run -itd --env-file=variables --rm --name akash -v $(pwd)/data:/root/.akash akash
echo "Saving genesis and json"
docker exec -it akash /bin/bash -c 'curl -s "$AKASH_NET/genesis.json" > /root/.akash/config/genesis.json'
docker exec -it akash /bin/bash -c 'curl -s "$AKASH_NET/rpc-nodes.json" > /root/.akash/config/rpc-nodes.json'
docker exec -it akash /bin/bash -c 'curl -s "$AKASH_NET/seed-nodes.json" > /root/.akash/config/seed-nodes.json'
docker exec -it akash /bin/bash -c 'curl -s "$AKASH_NET/api-nodes.json" > /root/.akash/config/api-nodes.json'

echo "Print or save this screen now!"
sleep 3
echo "Now checking Akash is connected and has valid genesis:)"
docker exec -it akash /bin/bash -c "akash status"
docker exec -it akash /bin/bash -c "akash validate-genesis"

#echo helloworld | akash keys list | grep address | cut -d ":" -f2 | awk '{print $1}'
