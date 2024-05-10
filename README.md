# Validator scripts

## Automatically update a validator node to the latest version

* Note: Unless a client upgrade is needed updating the validator is not necessary
* Create the following files and associated permissions onto the server
```bash
touch /root/check-version-main.sh && chmod 755 /root/check-version-main.sh
touch /root/check-version-slave.sh && chmod 755 /root/check-version-slave.sh
```
* Paste the contents of the associated scripts included in this repository into the above files
* Check and change the files if necessary depending on whether you are running the script on Tangle Mainnet or Tangle Testnet before running.
* Create screen session `screen -S check-version`. see screen help https://gist.github.com/drewlesueur/950187/1e3382cbcd1ef012c68487fbc2e38c8963fc3b3c
* Run the script in the background screen session with `nohup /root/check-version-main.sh & >> /root/check-version-log.log`
  * Note: To run the script immune to hangups and use `/dev/null` after `>` or `>>` with some file path if you care what's in the stdout
* View log with `tail -f /root/check-version-log.log`
* Kill process with `ps aux | grep check-version-log.log`, then `kill -9 <pid>`
* Detach from that screen session to main bash `(Ctrl a) + d`
* Return back to specific screen session `screen -x check-version`
  * Kill window session if necessary with `Ctrl K`

## Rotate validator session keys with via CLI with Polkadot.js Tools instead of via UI with Polkadot.js Apps 

* Rotate validator session keys on localhost and store generated session key in a variable

```bash
OUTPUT=$(
  curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' http://localhost:9944
)
SESSION_KEY=$(printf "${OUTPUT}" | jq -r '.result')
printf "${SESSION_KEY}"
```

* Set the validator session keys into the local validator
  * Create environment variable file from the example
    ```
    cp .env-example .env
    ```
  * Populate .env with other values
    * Use the secret seed of the validator for the value of `SEED`
    * Obtain the IP address on the remote server with `ifconfig` as value of `REMOTE_IP_ADDRESS`
    * Obtain the architecture of the remote server with `uname -a` as value of `PLATFORM`
    * Use the session key generated earlier as the value of `SESSION_KEY`
  * Run 
    ```
    . ./scripts/rotate-keys-main.sh
    ```
  * **FIXME**: If I run the script not on the same machine as the validator and use the secret seed of a testnet account with sufficient balance and run the above it gives error:
    ```
    RpcError: 1010: Invalid Transaction: Inability to pay some fees , e.g. account balance too low
    ``` 
  * **FIXME**: If I run the below command on the validator server that is running the validator instead of from a separate machine it returns error `API-WS: disconnected from ws://127.0.0.1:9944: 1006:: Abnormal Closure`, even if I am running the validator with `--unsafe-rpc-external --rpc-cors=all --rpc-methods=Unsafe` (that should not be used in production)

### Optional Experiments

* Optional: pull docker image from dockerhub for https://github.com/polkadot-js/tools

```bash
docker pull jacogr/polkadot-js-tools:latest
```

* Optional: pull image and view CLI help

```bash
uname -a
export PLATFORM="linux/amd64"
docker run -it --platform $PLATFORM --rm $(docker pull --platform $PLATFORM jacogr/polkadot-js-tools:latest | grep Status |  awk 'NF>1{print $NF}') --help
```

* Optional: Store the example session key below into a variable

```bash
VALUE=$(cat <<EOF
{"jsonrpc":"2.0","result":"0xZZZZZZZZ","id":1}
EOF
)
SESSION_KEY=$(printf "${VALUE}" | jq -r '.result')
printf "${SESSION_KEY}"
```

## Run script on remote server from host

* Note: run with `source ` or `. ` to set environment variables in a script so they are reflected in the shell 
```bash
#!/bin/sh

ssh me@example.com bash << EOF
export VAR1=$VAR1
export VAR2=$VAR2
. ./script-or-command-on-server.sh
EOF
```

## References

* https://unix.stackexchange.com/questions/410737/how-can-i-run-a-particular-script-every-second
* https://substrate.stackexchange.com/a/1660/83
* https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8
* https://stackoverflow.com/questions/57587094/can-i-make-docker-do-always-a-pull-when-performing-a-run
* https://stackoverflow.com/questions/43373176/store-json-directly-in-bash-script-with-variables
* https://stackoverflow.com/questions/39798542/using-jq-to-fetch-key-value-from-json-output
* https://stackoverflow.com/questions/57587094/can-i-make-docker-do-always-a-pull-when-performing-a-run
* https://substrate.stackexchange.com/questions/1627/how-to-call-session-set-keys-from-the-cli
* https://github.com/polkascan/py-substrate-interface/issues/205
