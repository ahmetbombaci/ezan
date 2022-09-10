#!/bin/python3

import click
import json
from datetime import datetime
from os.path import exists
import os.path
import requests

@click.command()
@click.option('--fajr', is_flag=True, help='display fajr pray time.')
@click.option('--dhuhr', is_flag=True, help='display dhuhr pray time.')
@click.option('--asr', is_flag=True, help='display asr pray time.')
@click.option('--maghrib', is_flag=True, help='display maghrib pray time.')
@click.option('--isha', is_flag=True, help='display isha pray time.')
@click.option('--all', is_flag=True, help='display all pray times.')
@click.option('--current', is_flag=True, help='display current pray time. default option if no option is provided.')
def ezan_vakti(fajr, dhuhr, asr, maghrib, isha, all, current):
    """Display pray times."""

    cache_file = os.path.expandvars('$HOME/ezan-cache/') + datetime.now().strftime("%y%m%d")

    if not exists(cache_file):
    	my_latitude="42.040257"
    	my_longitude="-87.6862397"
		# See options at http://api.aladhan.com/v1/methods
    	my_prayer_method=13

    	ts = datetime.now().timestamp()
    	api_url='http://api.aladhan.com/v1/timings/{timestamp}?latitude={latitude}&longitude={longitude}&method=${prayer_method}'
    	response = requests.get(api_url.format(latitude=my_latitude, longitude=my_longitude, prayer_method=my_prayer_method, timestamp=ts))

    	with open(cache_file, "w") as outfile:
    		json.dump(response.json(), outfile)

    f = open(cache_file)
    info = json.load(f)
    fajr_time = info['data']['timings']['Fajr']
    dhuhr_time = info['data']['timings']['Dhuhr']
    asr_time = info['data']['timings']['Asr']
    maghrib_time = info['data']['timings']['Maghrib']
    isha_time = info['data']['timings']['Isha']
    if fajr or all:
    	click.echo('Fajr: ' + fajr_time)
    if dhuhr or all:
    	click.echo('Dhuhr: ' + dhuhr_time)
    if asr or all:
    	click.echo('Asr: ' + asr_time)
    if maghrib or all:
    	click.echo('Magrib: ' + maghrib_time)
    if isha or all:
    	click.echo('Isha: ' + isha_time)
    if current or (not fajr and not dhuhr and not asr and not maghrib and not isha and not all):
    	current_time=datetime.now().strftime("%H:%M")
    	if current_time < fajr_time:
    		click.echo('current: Fajr: ' + fajr_time)
    	elif current_time < dhuhr_time:
    		click.echo('current: Dhuhr: ' + dhuhr_time)
    	elif current_time < asr_time:
    		click.echo('current: Asr: ' + asr_time)
    	elif current_time < magrib_time:
    		click.echo('current: Magrib: ' + magrib_time)
    	else:
    		click.echo('current: Isha: ' + isha_time)

if __name__ == '__main__':
    ezan_vakti()
