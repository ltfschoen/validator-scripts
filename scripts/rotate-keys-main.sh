#!/bin/sh

# https://stackoverflow.com/a/75983637/3208553

args=()
while IFS== read -r k v; do
   args+=("$v")
done < .env

SEED=$args[1]
REMOTE_IP_ADDRESS=$args[2]
PLATFORM=$args[3]
SESSION_KEY=$args[4]

# the follow effectively runs `polkadot-js-api --ws ws://x.x.x.x:9944 --seed "<seed>" tx.session.setKeys <session_key: 0x...> None`
# using `api.tx.session.setKeys`, where `setKeys(keys: KitchensinkRuntimeSessionKeys, proof: Bytes)`
docker run -it --platform $PLATFORM \
  --rm $(
    docker pull --platform $PLATFORM jacogr/polkadot-js-tools:latest | grep Status |  awk 'NF>1{print $NF}'
  ) api \
  --ws ws://$REMOTE_IP_ADDRESS:9944 \
  --seed $SEED tx.session.setKeys ${SESSION_KEY} None
