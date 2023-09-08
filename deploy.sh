docker cp deploy.yaml akash:/ ; docker exec -it akash /bin/bash -c 'akash tx deployment create deploy.yaml --from $AKASH_KEY_NAME --node $AKASH_NODE --chain-id $AKASH_CHAIN_ID --fees 200uakt -y'
get AKASH_DSEQ from output
AKASH_DSEQ=CHANGETHIS > variables
AKASH_OSEQ=1 > variables
AKASH_GSEQ=1 > variables
