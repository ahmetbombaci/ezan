#!/bin/bash

# https://linuxize.com/post/how-to-set-or-change-timezone-on-debian-10/
# sudo timedatectl set-timezone America/Chicago

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=ezan.config
source "$SCRIPT_DIR"/ezan.config

function debug() {
    if [ "${debugging:?}" == "true" ];
    then
		echo "[DEBUG]: $(date +%y%m%d%H%M): $1"
    fi
}

# Extract hour & minute from "HH:MM"
function convertPrayTime() {
    rawPrayTime=$1
    prayHour=${rawPrayTime:1:2}
    prayMinute=${rawPrayTime:4:2}
}


timestamp=$(date +%s)

url="http://api.aladhan.com/v1/timings/$timestamp?latitude=${latitude:?}&longitude=${longitude:?}&method=${prayer_method:?}"
debug "ezan end point: $url"

ezanJson=$(curl --silent "$url")
#debug sample ezan json so do not call the api#
#ezanJson="{\"code\":200,\"status\":\"OK\",\"data\":{\"timings\":{\"Fajr\":\"03:05\",\"Sunrise\":\"05:17\",\"Dhuhr\":\"12:54\",\"Asr\":\"16:57\",\"Sunset\":\"20:31\",\"Maghrib\":\"20:31\",\"Isha\":\"22:33\",\"Imsak\":\"02:55\",\"Midnight\":\"00:54\"},\"date\":{\"readable\":\"28 Jun 2019\",\"timestamp\":\"1561711957\",\"hijri\":{\"date\":\"24-10-1440\",\"format\":\"DD-MM-YYYY\",\"day\":\"24\",\"weekday\":{\"en\":\"Al Juma'a\",\"ar\":\"\u0627\u0644\u062c\u0645\u0639\u0629\"},\"month\":{\"number\":10,\"en\":\"Shaww\u0101l\",\"ar\":\"\u0634\u064e\u0648\u0651\u0627\u0644\"},\"year\":\"1440\",\"designation\":{\"abbreviated\":\"AH\",\"expanded\":\"Anno Hegirae\"},\"holidays\":[]},\"gregorian\":{\"date\":\"28-06-2019\",\"format\":\"DD-MM-YYYY\",\"day\":\"28\",\"weekday\":{\"en\":\"Friday\"},\"month\":{\"number\":6,\"en\":\"June\"},\"year\":\"2019\",\"designation\":{\"abbreviated\":\"AD\",\"expanded\":\"Anno Domini\"}}},\"meta\":{\"latitude\":42.040343,\"longitude\":-87.68391,\"timezone\":\"America\/Chicago\",\"method\":{\"id\":13,\"name\":\"Diyanet \u0130\u015fleri Ba\u015fkanl\u0131\u011f\u0131, Turkey\",\"params\":{\"Fajr\":18,\"Isha\":17}},\"latitudeAdjustmentMethod\":\"ANGLE_BASED\",\"midnightMode\":\"STANDARD\",\"school\":\"STANDARD\",\"offset\":{\"Imsak\":0,\"Fajr\":0,\"Sunrise\":0,\"Dhuhr\":0,\"Asr\":0,\"Maghrib\":0,\"Sunset\":0,\"Isha\":0,\"Midnight\":0}}}}"
debug "ezan response: $ezanJson"

# Clean up previous jobs
crontab -l | grep -v ezanruncronjob | { cat; } | crontab -

#schedule new job at pray time
function callEzan() {
    debug "$2:$1"
    convertPrayTime "$1"

    debug "$prayMinute $prayHour * * * python3 ${SCRIPT_DIR}/ezan.py --cast \"${cast_name:?}\" #ezanruncronjob"
    crontab -l | { cat; echo "$prayMinute $prayHour * * * python3 ${SCRIPT_DIR}/ezan.py --cast \"$cast_name\" #ezanruncronjob"; } | crontab -
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
