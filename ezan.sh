#!/bin/bash

# https://linuxize.com/post/how-to-set-or-change-timezone-on-debian-10/
# sudo timedatectl set-timezone America/Chicago

# Set EZAN_HOME to ~/ezan/ if not already set
EZAN_HOME="${EZAN_HOME:-$HOME/ezan}"

# shellcheck source=/dev/null
source "${EZAN_HOME}/default.config"

if [ -e  "${EZAN_HOME}/custom.config" ];
then
	# shellcheck source=/dev/null
	source "${EZAN_HOME}/custom.config"
fi

LOG_FILE="${EZAN_HOME}/ezan.log"

function log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]: $1" | tee -a "${LOG_FILE}"
}

function log_error() {
    echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')]: $1" | tee -a "${LOG_FILE}" >&2
}

function debug() {
    if [ "${debugging:?}" == "true" ];
    then
		echo "[DEBUG]: $(date +%y%m%d%H%M): $1" | tee -a "${LOG_FILE}"
    fi
}

# Detect Python interpreter to use
# Priority: 1. EZAN_HOME/.venv, 2. EZAN_HOME/venv, 3. Current VIRTUAL_ENV, 4. System python3
if [ -f "${EZAN_HOME}/.venv/bin/python3" ]; then
    PYTHON_CMD="${EZAN_HOME}/.venv/bin/python3"
    debug "Using venv python: ${PYTHON_CMD}"
elif [ -f "${EZAN_HOME}/venv/bin/python3" ]; then
    PYTHON_CMD="${EZAN_HOME}/venv/bin/python3"
    debug "Using venv python: ${PYTHON_CMD}"
elif [ -n "$VIRTUAL_ENV" ] && [ -f "$VIRTUAL_ENV/bin/python3" ]; then
    PYTHON_CMD="$VIRTUAL_ENV/bin/python3"
    debug "Using VIRTUAL_ENV python: ${PYTHON_CMD}"
else
    PYTHON_CMD="python3"
    debug "Using system python3"
fi

# Extract hour & minute from "HH:MM"
function convertPrayTime() {
    rawPrayTime=$1
    prayHour=${rawPrayTime:1:2}
    prayMinute=${rawPrayTime:4:2}
}


mkdir -p "${EZAN_HOME}/cache/"
CACHE_FILE="${EZAN_HOME}/cache/$(date +%y%m%d)"

if [ -e "${CACHE_FILE}" ];
then
  debug "Using cache file"
  ezanJson=$(<"${CACHE_FILE}")
else
  timestamp=$(date +%s)

  url="http://api.aladhan.com/v1/timings/$timestamp?latitude=${latitude:?}&longitude=${longitude:?}&method=${prayer_method:?}"
  debug "ezan end point: $url"

  ezanJson=$(curl -L --silent "$url")

  # Check if API call was successful before caching
  status=$(echo "${ezanJson}" | jq -r '.status' 2>/dev/null)
  if [ "$status" = "OK" ]; then
    echo "${ezanJson}" > "${CACHE_FILE}"
    debug "API response cached successfully"
  else
    debug "API call failed, not caching response"
    log_error "Failed to fetch prayer times from API"
    exit 1
  fi
fi

#debug sample ezan json so do not call the api#
#ezanJson="{\"code\":200,\"status\":\"OK\",\"data\":{\"timings\":{\"Fajr\":\"03:05\",\"Sunrise\":\"05:17\",\"Dhuhr\":\"12:54\",\"Asr\":\"16:57\",\"Sunset\":\"20:31\",\"Maghrib\":\"20:31\",\"Isha\":\"22:33\",\"Imsak\":\"02:55\",\"Midnight\":\"00:54\"},\"date\":{\"readable\":\"28 Jun 2019\",\"timestamp\":\"1561711957\",\"hijri\":{\"date\":\"24-10-1440\",\"format\":\"DD-MM-YYYY\",\"day\":\"24\",\"weekday\":{\"en\":\"Al Juma'a\",\"ar\":\"\u0627\u0644\u062c\u0645\u0639\u0629\"},\"month\":{\"number\":10,\"en\":\"Shaww\u0101l\",\"ar\":\"\u0634\u064e\u0648\u0651\u0627\u0644\"},\"year\":\"1440\",\"designation\":{\"abbreviated\":\"AH\",\"expanded\":\"Anno Hegirae\"},\"holidays\":[]},\"gregorian\":{\"date\":\"28-06-2019\",\"format\":\"DD-MM-YYYY\",\"day\":\"28\",\"weekday\":{\"en\":\"Friday\"},\"month\":{\"number\":6,\"en\":\"June\"},\"year\":\"2019\",\"designation\":{\"abbreviated\":\"AD\",\"expanded\":\"Anno Domini\"}}},\"meta\":{\"latitude\":42.040343,\"longitude\":-87.68391,\"timezone\":\"America\/Chicago\",\"method\":{\"id\":13,\"name\":\"Diyanet \u0130\u015fleri Ba\u015fkanl\u0131\u011f\u0131, Turkey\",\"params\":{\"Fajr\":18,\"Isha\":17}},\"latitudeAdjustmentMethod\":\"ANGLE_BASED\",\"midnightMode\":\"STANDARD\",\"school\":\"STANDARD\",\"offset\":{\"Imsak\":0,\"Fajr\":0,\"Sunrise\":0,\"Dhuhr\":0,\"Asr\":0,\"Maghrib\":0,\"Sunset\":0,\"Isha\":0,\"Midnight\":0}}}}"
debug "ezan response: $ezanJson"

# Clean up previous jobs - save backup first
BACKUP_FILE="${EZAN_HOME}/cache/crontab.backup.$(date +%Y%m%d)"
crontab -l > "${BACKUP_FILE}" 2>/dev/null || true
debug "Crontab backup saved to ${BACKUP_FILE}"

# Remove old ezan cronjobs
crontab -l 2>/dev/null | grep -v ezanruncronjob | crontab - 2>/dev/null || true

#schedule new job at pray time
function callEzan() {
    debug "$2:$1"
    convertPrayTime "$1"

	if [ "${action:?}" == "cast" ]; then
			script_exec="${PYTHON_CMD} ${EZAN_HOME}/ezan.py --cast \"${cast_name:?}\" #ezanruncronjob"
	elif [ "${action:?}" == "command" ]; then
			script_exec="${command_script:?} #ezanruncronjob" 
	fi
	debug "$script_exec"
	crontab -l | { cat; echo "$prayMinute $prayHour * * * $script_exec"; } | crontab -

}

if [ "${call_fajr:?}" == "true" ];
then
		fajr=$(echo "$ezanJson" | jq '.data.timings.Fajr')
		callEzan "$fajr" "fajr"
fi

if [ "${call_dhuhr:?}" == "true" ];
then
		dhuhr=$(echo "$ezanJson" | jq '.data.timings.Dhuhr')
		callEzan "$dhuhr" "dhuhr"
fi

if [ "${call_asr:?}" == "true" ];
then
		asr=$(echo "$ezanJson" | jq '.data.timings.Asr')
		callEzan "$asr" "asr"
fi

if [ "${call_magrib:?}" == "true" ];
then
		magrib=$(echo "$ezanJson" | jq '.data.timings.Maghrib')
		callEzan "$magrib" "magrib"
fi

if [ "${call_isha:?}" == "true" ];
then
		isha=$(echo "$ezanJson" | jq '.data.timings.Isha')
		callEzan "$isha" "isha"
fi
