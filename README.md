# Ezan (Call for prayer)

Make Ezan (Call for prayer) available at your home via chromecast. 

This is a custom implementation for my needs but I am hoping that it is easy
to customize if you want to adapt.

# Install

## Required Packages

The following applications/packages are needed.

```
sudo apt install curl jq python3-pip
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
* Create `~/ezan.config` to override definitions at `default.config`:
	* Set `latitude` and `longitude` based on where you live.
    * Set `prayer_method`. 
		* See options at [aladhan api link](http://api.aladhan.com/v1/methods).
		* `curl http://api.aladhan.com/v1/methods | jq`
	* Set `action`. This can be either `cast` or `command`.
	* If the action is cast, set `cast_name` based on friendly name of chromecast device. You can use `python3 device-list.py`.
	* If the action is command set `command_script` so it will be executed during pray time.
* Make sure that `ezan.sh` is executable: `chmod +x ezan.sh`.
* Set new daily cronjob to refresh prayer times daily:
	* Manually:
		* `crontab -e`
		* Add new line: `0 1 * * * /home/pi/ezan/ezan/sh > /home/pi/ezan/ezan.log 2>&1`
		* Fix path of `ezan.sh` and `ezan.log`
	* Or, execute the following in `ezan.sh` directory:
		* `crontab -l | { cat; echo "0 1 * * * $(pwd)/ezan.sh > $(pwd)/ezan.log 2>&1"; } | crontab -`

You should be all set!


## Troubleshooting

By default, debug mode is enabled so logs can be found at `ezan.log`.
Debug mode can be turned off via `ezan.config` with `debugging=false`

This script and chromecast device must be in the same local area network (LAN).

Cronjob logs can be checked via: `cat /var/log/syslog | grep CRON`

