#!/bin/sh

# configurable
IS_MAINNET=false

# do not configure this - reset env
LATEST_RELEASE_URL_SHORT= # e.g. `1.0.2`
BINARY_INFIX= # e.g. `default`, or `mainnet` value shown in binary filename
REMOTE_VERSION= # e.g. `tangle-testnet-linux-amd64 1.0.2-xxx-x86_64-linux-gnu`
LOCAL_VERSION= # e.g. `tangle-testnet-linux-amd64 1.0.0-6855ead-x86_64-linux-gnu`
CHAIN_DIR_POSTFIX= # e.g. `testnet`, or `mainnet`

echo "Running at: `date -u`"

if [ "${IS_MAINNET}" = true ]
then
  BINARY_INFIX="default"
  CHAIN_DIR_POSTFIX="mainnet"
  echo "using Mainnet"
  cd /root/tangle-${BINARY_INFIX}
else
  BINARY_INFIX="testnet"
  CHAIN_DIR_POSTFIX=${BINARY_INFIX}
  echo "using Testnet"
  cd /root/tangle-${BINARY_INFIX}
fi

# if we run `./tangle-testnet-linux-amd64 --version` and it outputs `tangle-testnet-linux-amd64 1.0.0-6855ead-x86_64-linux-gnu`
# then we want to compare that with the output of downloading the latest version and running the same thing
# and if they differ, then delete the current version, and use just the `1.0.0` part
# since even if its an RC1 or similar version, it'll use the same version, we'll just be updating the local version

# this is just outputs `v1.x.x` or `v1.x.x-rc2` or similar from URL
export LATEST_RELEASE_URL_SHORT=$(curl --silent -qI https://github.com/webb-tools/tangle/releases/latest |
  awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}');
echo "latest release $LATEST_RELEASE_URL_SHORT"

# FIXME - get commit and compare so don't have to keep downloading to check
# https://stackoverflow.com/questions/67040794/how-can-i-get-the-commit-hash-of-the-latest-release-from-github-api

# but we want the version from running `--version`
# so get the version like `tangle-testnet-linux-amd64 1.0.0-6855ead-x86_64-linux-gnu`
# TODO - also install later using this version that we temporarily downloaded
export REMOTE_VERSION="$(
  rm /tmp/remote-version &&
  wget -O /tmp/remote-version https://github.com/webb-tools/tangle/releases/download/${LATEST_RELEASE_URL_SHORT}/tangle-${BINARY_INFIX}-linux-amd64 &&
  chmod 755 /tmp/remote-version &&
  /tmp/remote-version --version
)"
echo "remote version: $REMOTE_VERSION"

export LOCAL_VERSION="$(/usr/bin/tangle-${BINARY_INFIX}-linux-amd64 --version)"
echo "local version: $LOCAL_VERSION"

if [ "${REMOTE_VERSION}" != "${LOCAL_VERSION}" ]
then
  echo "downloading new release ${LATEST_RELEASE_URL_SHORT} with version ${REMOTE_VERSION} to replace local version ${LOCAL_VERSION}"
  systemctl stop validator

  cd /root/tangle-${BINARY_INFIX}
  mv tangle-${BINAlRY_INFIX}-linux-amd64 tangle-${BINARY_INFIX}-linux-amd64-$LOCAL_VERSION-old
  rm tangle-${BINARY_INFIX}-linux-amd64
  wget --show-progress -O tangle-${BINARY_INFIX}-linux-amd64 https://github.com/webb-tools/tangle/releases/download/${LATEST_RELEASE_URL_SHORT}/tangle-${BINARY_INFIX}-linux-amd64
  chmod 755 tangle-${BINARY_INFIX}-linux-amd64
  rm /usr/bin/tangle-${BINARY_INFIX}-linux-amd64
  cp ./tangle-${BINARY_INFIX}-linux-amd64 /usr/bin

  echo "finished installing new release ${LATEST_RELEASE_URL_SHORT} with version ${REMOTE_VERSION} to replace local version ${LOCAL_VERSION}"

	# we don't need the below line
  # echo 'export LOCAL_VERSION="${LATEST_RELEASE_URL_SHORT}"' >> ~/.bashrc
	# source ~/.bashrc

  # will this prompt to click ok to continue
  # comment out since not sure how to bypass `Newer kernel available` prompt
  # DEBIAN_FRONTEND=noninteractive sudo apt update && sudo apt upgrade -y

  # update rust
  echo "updating rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  . $HOME/.cargo/env
  rustup default nightly
  rustup update
  rustup update nightly
  rustup target add wasm32-unknown-unknown --toolchain nightly

  echo "restarting docker"
  systemctl restart docker

  echo "removing old db, frontier, and network folders"
  # remove subfolders, but not the /keystore
  if [ "${IS_MAINNET}" = true ]
  then
    # note that th chain folder on mainnet uses `mainnet` not `default`
    rm -rf ~/tangle/data-path/validator/luke1/chains/tangle-${CHAIN_DIR_POSTFIX}/db/full
    rm -rf ~/tangle/data-path/validator/luke1/chains/tangle-${CHAIN_DIR_POSTFIX}/db
    rm -rf ~/tangle/data-path/validator/luke1/chains/tangle-${CHAIN_DIR_POSTFIX}/frontier
    rm -rf ~/tangle/data-path/validator/luke1/chains/tangle-${CHAIN_DIR_POSTFIX}/network
  else
    rm -rf ~/tangle-${BINARY_INFIX}/data-path/validator/luke1/chains/tangle-${BINARY_INFIX}/db/full
    rm -rf ~/tangle-${BINARY_INFIX}/data-path/validator/luke1/chains/tangle-${BINARY_INFIX}/db
    rm -rf ~/tangle-${BINARY_INFIX}/data-path/validator/luke1/chains/tangle-${BINARY_INFIX}/frontier
    rm -rf ~/tangle-${BINARY_INFIX}/data-path/validator/luke1/chains/tangle-${BINARY_INFIX}/network
  fi

  echo "reloading validator"
  systemctl daemon-reload
  systemctl enable validator
  systemctl start validator

  # want to exit so it repeats, not keep it running
  # sudo journalctl -u validator.service -f

  echo "success restarting validator with new version"
  exit 0
else
  echo "no new release found"
  exit 1
fi
