#!/usr/bin/env python3

import click
import json
from datetime import datetime
from os.path import exists
import os
import requests
import logging
import sys

def load_config():
    """Load configuration from config files."""
    config = {}
    ezan_home = os.environ.get('EZAN_HOME', os.path.expanduser('~/ezan'))

    # Default config values
    config['latitude'] = "42.040257"
    config['longitude'] = "-87.6862397"
    config['prayer_method'] = "13"

    # Try to load from default.config
    default_config = os.path.join(ezan_home, 'default.config')
    if exists(default_config):
        with open(default_config, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"')
                    if key in ['latitude', 'longitude', 'prayer_method']:
                        config[key] = value

    # Try to load from custom.config (overrides default)
    custom_config = os.path.join(ezan_home, 'custom.config')
    if exists(custom_config):
        with open(custom_config, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"')
                    if key in ['latitude', 'longitude', 'prayer_method']:
                        config[key] = value

    return config, ezan_home

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

    logging.info("START")

    config, ezan_home = load_config()

    cache_dir = os.path.join(ezan_home, 'cache')
    os.makedirs(cache_dir, exist_ok=True)
    cache_file = os.path.join(cache_dir, datetime.now().strftime("%y%m%d"))

    if not exists(cache_file):
        ts = int(datetime.now().timestamp())
        api_url = 'http://api.aladhan.com/v1/timings/{timestamp}?latitude={latitude}&longitude={longitude}&method={prayer_method}'
        url = api_url.format(
            latitude=config['latitude'],
            longitude=config['longitude'],
            prayer_method=config['prayer_method'],
            timestamp=ts
        )

        logging.debug(f"Fetching from API: {url}")
        response = requests.get(url)
        data = response.json()

        # Validate API response before caching
        if data.get('status') == 'OK':
            with open(cache_file, "w") as outfile:
                json.dump(data, outfile)
            logging.info("API response cached successfully")
        else:
            logging.error("API call failed, not caching response")
            click.echo("ERROR: Failed to fetch prayer times from API", err=True)
            sys.exit(1)

    with open(cache_file, 'r') as f:
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
        # Fix time comparison by converting to datetime objects
        current_time = datetime.now().time()
        fajr_dt = datetime.strptime(fajr_time, "%H:%M").time()
        dhuhr_dt = datetime.strptime(dhuhr_time, "%H:%M").time()
        asr_dt = datetime.strptime(asr_time, "%H:%M").time()
        maghrib_dt = datetime.strptime(maghrib_time, "%H:%M").time()
        isha_dt = datetime.strptime(isha_time, "%H:%M").time()

        if current_time < fajr_dt:
            click.echo('current: Fajr: ' + fajr_time)
        elif current_time < dhuhr_dt:
            click.echo('current: Dhuhr: ' + dhuhr_time)
        elif current_time < asr_dt:
            click.echo('current: Asr: ' + asr_time)
        elif current_time < maghrib_dt:
            click.echo('current: Magrib: ' + maghrib_time)
        else:
            click.echo('current: Isha: ' + isha_time)

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    ezan_vakti()
