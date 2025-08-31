# Walleye-AWS
Walleye binaries and deployment scripts for AWS

## AWS Deployment

This is the deployment configuration for Walleye. It is set up to use a local opening book up to 8 moves deep, after which it will begin calculating on its own. No endgame tablebase is used — Walleye will attempt to find checkmate independently.

The Lichess token is not included in `./deploy.sh`; it must be added manually

1. Create an AWS instance of your choosing and upload `deploy.sh` as the deploy script

I found 1GB of Ram and 2 vCPUS was sufficient

2. Add the token to the config

```sh
ssh ubuntu@lightsail-ip # Replace with the IP of the lightsail service
sudo nano /opt/lichess-bot/config.yml
```
Then populate the `token: PUT_YOUR_TOKEN_HERE` variable

3. Start the service

```sh
sudo systemctl enable --now lichess-bot
```

4. Check logs to make sure everything is working 

```sh
journalctl -u lichess-bot -f
```

## On compilation 

Building Walleye from source can be too CPU or RAM-intensive on some smaller hosting instances. To avoid this, the deployment script is set up to download an already compiled binary targeting x86_64.

The deployment script also contains commented-out steps if you prefer to compile from source on a more powerful instance. Doing so may yield better performance, especially if you can target a CPU with newer instruction sets.

