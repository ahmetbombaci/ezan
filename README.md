# Ezan (Call for prayer)

Make Ezan (Call for prayer) available at your home via chromecast. 

This is a custom implementation for my needs but I am hoping that it is easy
to customize if you want to adapt.

# Install

## Debian Packages

The following packages are needed.

```
sudo apt install jq python3-pip
```

## Home Assistant pychromecast lib

Ref [pychromecast github](https://github.com/home-assistant-libs/pychromecast)

```
pip3 install pychromecast
```

## Timezone

Make sure that your timezone is accurate:

```
pi@raspberrypi:~ $ timedatectl
```

In order to change it:

```
pi@raspberrypi:~ $ timedatectl list-timezones | grep Chica
America/Chicago
pi@raspberrypi:~ $ sudo timedatectl set-timezone America/Chicago
```

## Clone This Repo

* Clone this repo. 
* Update `ezan.config`:
	* Set latitude and longitude based on where you live.
	* Set `cast_name` based on friendly name of chromecast device. You can use `python3 device-list.py`.
    * Set `prayer_method`. See options at [aladhan api link](http://api.aladhan.com/v1/methods).
* Make sure that `ezan.sh` is executable: `chmod +x ezan.sh`.
* Set new daily cronjob to refresh prayer times daily:
	* `crontab -l | { cat; echo "0 1 * * * python3 /home/pi/Python/ezan.sh"; } | crontab -`

You should be all set!


## Troubleshooting

By default, debug mode is enabled so logs can be found at `ezan.log`.
 
