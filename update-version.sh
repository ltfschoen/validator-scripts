#!/bin/sh

# run script on server from remote host and set environment variables
ssh me@example.com bash << EOF
export VAR1=$VAR1
export VAR2=$VAR2
./script-or-command-on-server.sh
EOF

# update version of validator software on server
export CURRENT_RELEASE=v1.0.1-rc1
export LATEST_RELEASE=$(curl --silent -qI https://github.com/webb-tools/tangle/releases/latest |
  awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}');
if [ "${LATEST_RELEASE}" != "${CURRENT_RELEASE}" ]
then
  export CURRENT_RELEASE=${LATEST_RELEASE}
  cd /root/tangle-testnet
  wget --show-progress -O tangle-testnet-linux-amd64 https://github.com/webb-tools/tangle/releases/download/${LATEST_RELEASE}/tangle-testnet-linux-amd64
  chmod 755 tangle-default-linux-amd64
  cp ./tangle-default-linux-amd64 /usr/bin

  echo "found new release ${LATEST_RELEASE}"
	echo 'export CURRENT_RELEASE="${LATEST_RELEASE}"' >> ~/.bashrc
	source ~/.bashrc

  # will this prompt to click ok to continue
  DEBIAN_FRONTEND=noninteractive sudo apt update && sudo apt upgrade -y

  # update rust
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source $HOME/.cargo/env
  rustup default nightly
  rustup update
  rustup update nightly
  rustup target add wasm32-unknown-unknown --toolchain nightly

  systemctl restart docker
else
  echo "no new release found"
fi

# rotate session keys without polkadot.js apps
docker pull jacogr/polkadot-js-tools:latest
docker run -it --rm $(docker pull jacogr/polkadot-js-tools:latest | grep Status |  awk 'NF>1{print $NF}') --help
docker run -it --rm $(docker pull --platform linux/amd64 jacogr/polkadot-js-tools:latest | grep Status |  awk 'NF>1{print $NF}') --help
docker run -it --platform linux/amd64 --rm $(docker pull --platform linux/amd64 jacogr/polkadot-js-tools:latest | grep Status |  awk 'NF>1{print $NF}') --help
# output {"jsonrpc":"2.0","result":"0xZZZZZZZZZZZ","id":1}  | jq -r '.[] | .[] | .result'
OUTPUT={"jsonrpc":"2.0","result":"0xZZZZZZZZZZZ","id":1}\n    printf '${OUTPUT}' | jq -r '.[] | .result'


# references
#
# https://substrate.stackexchange.com/a/1660/83
# https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8
# https://stackoverflow.com/questions/57587094/can-i-make-docker-do-always-a-pull-when-performing-a-run
# https://stackoverflow.com/questions/43373176/store-json-directly-in-bash-script-with-variables

