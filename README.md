# Walleye-AWS
Walleye binaries and deploy scripts for AWS

## AWS Deployment

This is the deployment config for Walleye. It is set up to using a local opening book up to 8 moves deep then will begin to think after that. No end game tablebase is used, Walleye will attempt to find Checkmate. 

The lichess token is not included in `./deploy.sh`, it must be added manually

1. Create an AWS instance of your chosing and upload `deploy.sh` as the deploy script

1GB of Ram and 2 vCPUS were sufficient

2. Add the variable to the config
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

Building from source can be too CPU/RAM intensive on some cheaper hosting instances, to circumvent this the deploy script is set up to simply download an already compiled binary targeting x86_64, the deploy script also contains some commented out steps if you would prefer to compile from source if hosting on a stronger instance. This could result in better peformance if targeting a CPU with newer instruction sets. 

