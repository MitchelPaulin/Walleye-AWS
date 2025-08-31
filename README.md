# Walleye-AWS
Walleye binaries and deploy scripts for AWS

## AWS Deployment

This is the deployment config for Walleye. It is set up to using a local opening book up to 8 moves deep then will think on its own. No end game tablebase is used, Walleye will attempt to find Checkmate on its own. 

The lichess token is not included in `./deploy.sh`, it must be added manually

1. Add the variable to the config
```sh
ssh ubuntu@lightsail-ip # Replace with the IP of the lightsail service
sudo nano /opt/lichess-bot/config.yml
```

Then populate the `token: PUT_YOUR_TOKEN_HERE` variable

2. Start the service

```sh
sudo systemctl enable --now lichess-bot
```

3. Check logs to make sure everything is working 

```sh
journalctl -u lichess-bot -f
```

## On compilation 

Building from source can be too CPU/RAM intensive on some cheaper hosting instances, to circumvent this the deploy script is set up to simply download an binary already compiled to target x86_64, the deploy script also contains some commented out steps if you would prefer to compile from source if hosting on a stronger instance. 

