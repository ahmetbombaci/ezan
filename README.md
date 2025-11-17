# Ezan (Call for Prayer)

Make Ezan (Call for prayer) available at your home via Chromecast or custom commands.

This is a cron-based system that automatically schedules prayer time notifications daily. Prayer times are fetched from the [Aladhan API](http://api.aladhan.com/) and can be configured for any location worldwide.

## Features

- 🕌 Automatic daily prayer time scheduling via cron
- 📱 Chromecast integration to play Adhan (call to prayer)
- 🔔 Custom command execution at prayer times
- 💾 Smart caching to reduce API calls
- 🛠 Easy installation with interactive setup
- 🏥 Health check utility
- 📝 Comprehensive logging
- ⚙️ Flexible configuration with default and custom configs
- 🌍 Uses EZAN_HOME environment variable for flexible installation

## Quick Install

```bash
# Clone the repository
git clone https://github.com/yourusername/ezan.git
cd ezan

# Run the installer
./install.sh
```

The installer will:
1. Set up the directory structure
2. Install dependencies
3. Guide you through configuration
4. Set up the daily cron job
5. Schedule today's prayer times

## Manual Installation

### Required Packages

```bash
sudo apt install curl jq python3 python3-pip
```

### Python Dependencies

**Option 1: Using Virtual Environment (Recommended)**
```bash
cd ~/ezan
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

The system will automatically detect and use the virtual environment when scheduling cronjobs.

**Option 2: User Installation**
```bash
pip3 install --user -r requirements.txt
```

**Option 3: Manual Installation**
```bash
pip3 install --user click requests pychromecast zeroconf
```

**Note:** The ezan.sh script automatically detects Python installations in this order:
1. `~/ezan/.venv/bin/python3` (virtual environment)
2. `~/ezan/venv/bin/python3` (alternative venv location)
3. `$VIRTUAL_ENV/bin/python3` (active virtual environment)
4. System `python3`

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/ezan.git ~/ezan
   ```

2. **Set EZAN_HOME (optional):**
   ```bash
   export EZAN_HOME=~/ezan
   echo 'export EZAN_HOME=~/ezan' >> ~/.bashrc
   ```

   If not set, defaults to `~/ezan/`

3. **Create custom configuration:**

   Create `~/ezan/custom.config` to override `default.config` settings:

   ```bash
   # Location settings
   latitude="42.040257"
   longitude="-87.6862397"

   # Prayer calculation method
   # 13 - Turkey (Diyanet İşleri), 2 - ISNA, 3 - Muslim World League
   # See all: curl http://api.aladhan.com/v1/methods | jq
   prayer_method=13

   # Which prayers to notify
   call_fajr=false
   call_dhuhr=true
   call_asr=true
   call_magrib=true
   call_isha=true

   # Action: cast or command
   action=cast

   # For cast action:
   cast_name="Living Room Display"

   # For command action:
   # action=command
   # command_script="notify-send 'Prayer Time!'"
   ```

4. **Find your Chromecast device:**
   ```bash
   python3 ~/ezan/device-list.py
   ```

5. **Make scripts executable:**
   ```bash
   chmod +x ~/ezan/ezan.sh
   chmod +x ~/ezan/ezan-vakti.sh
   chmod +x ~/ezan/ezan-health-check.sh
   ```

6. **Set up daily cron job:**

   This job runs daily at 1 AM to schedule that day's prayer times:

   ```bash
   crontab -e
   ```

   Add:
   ```
   0 1 * * * ~/ezan/ezan.sh >> ~/ezan/ezan.log 2>&1
   ```

   Or use the automated command:
   ```bash
   crontab -l | { cat; echo "0 1 * * * ~/ezan/ezan.sh >> ~/ezan/ezan.log 2>&1"; } | crontab -
   ```

7. **Run ezan.sh to schedule today's prayers:**
   ```bash
   ~/ezan/ezan.sh
   ```

## Usage

### Check Prayer Times

Display all prayer times for today:
```bash
~/ezan/ezan-vakti.sh --all
```

Display current/next prayer time:
```bash
~/ezan/ezan-vakti.sh --current
```

Display specific prayer:
```bash
~/ezan/ezan-vakti.sh --fajr
~/ezan/ezan-vakti.sh --dhuhr
~/ezan/ezan-vakti.sh --asr
~/ezan/ezan-vakti.sh --maghrib
~/ezan/ezan-vakti.sh --isha
```

Python version (same options):
```bash
python3 ~/ezan/ezan-vakti.py --all
```

### Health Check

Run the health check to verify your installation:
```bash
~/ezan/ezan-health-check.sh
```

This checks:
- Directory structure
- Configuration files
- Required commands (curl, jq, python3)
- Python dependencies
- Cache status
- Scheduled cronjobs
- API connectivity
- Log files

### View Scheduled Prayers

```bash
crontab -l | grep ezanruncronjob
```

### View Logs

```bash
tail -f ~/ezan/ezan.log
```

## Directory Structure

```
~/ezan/                      # Default EZAN_HOME location
├── ezan.sh                  # Main scheduler (run daily by cron)
├── ezan-vakti.sh            # Display prayer times (bash)
├── ezan-vakti.py            # Display prayer times (python)
├── ezan.py                  # Chromecast player script
├── device-list.py           # List Chromecast devices
├── install.sh               # Interactive installer
├── ezan-health-check.sh     # System health checker
├── default.config           # Default configuration
├── custom.config            # Your custom configuration (gitignored)
├── requirements.txt         # Python dependencies
├── cache/                   # API response cache (gitignored)
│   ├── 251117              # Today's cache file (YYMMDD format)
│   └── crontab.backup.*    # Crontab backups
└── ezan.log                 # Application logs (gitignored)
```

## Configuration Files

### default.config
Contains default values. **Don't modify this file** - use `custom.config` instead.

### custom.config
Your personal configuration that overrides defaults. This file is gitignored.

Required settings:
- `latitude` - Your location latitude
- `longitude` - Your location longitude
- `prayer_method` - Calculation method (see [Aladhan API](http://api.aladhan.com/v1/methods))

Optional settings:
- `call_fajr`, `call_dhuhr`, `call_asr`, `call_magrib`, `call_isha` - Enable/disable prayers (true/false)
- `debugging` - Enable debug logging (true/false)
- `action` - Action type: `cast` or `command`
- `cast_name` - Chromecast friendly name (for cast action)
- `command_script` - Command to execute (for command action)

## How It Works

1. **Daily Scheduler (`ezan.sh`):**
   - Runs daily at 1 AM via cron
   - Fetches prayer times from Aladhan API
   - Validates API response
   - Caches response for the day
   - Creates crontab backup
   - Schedules 5 cronjobs for enabled prayers

2. **Prayer Time Jobs:**
   - Triggered at each prayer time
   - Either cast to Chromecast or execute custom command
   - Marked with `#ezanruncronjob` tag for easy identification

3. **Caching:**
   - API responses cached in `~/ezan/cache/`
   - One cache file per day (YYMMDD format)
   - Only successful responses are cached
   - Reduces API calls and improves reliability

## Troubleshooting

### Run Health Check
```bash
~/ezan/ezan-health-check.sh
```

### Enable Debug Logging
Add to `custom.config`:
```bash
debugging=true
```

### Check Cron Logs
```bash
grep CRON /var/log/syslog
```

### View Application Logs
```bash
tail -50 ~/ezan/ezan.log
```

### Clear Cache
```bash
rm -rf ~/ezan/cache/*
~/ezan/ezan.sh  # Fetch fresh data
```

### Verify Cronjobs
```bash
# View all ezan cronjobs
crontab -l | grep ezan

# View today's prayer time jobs
crontab -l | grep ezanruncronjob
```

### Restore Crontab from Backup
```bash
crontab ~/ezan/cache/crontab.backup.YYYYMMDD
```

### Test Chromecast Connection
```bash
python3 ~/ezan/device-list.py
```

### Common Issues

**"API call failed"**
- Check internet connection
- Verify API is accessible: `curl http://api.aladhan.com/v1/methods`

**"No chromecast discovered"**
- Ensure device is on same network
- Check device name matches `cast_name` in config
- Run `device-list.py` to find correct name

**Cronjobs not running**
- Verify cron service is running: `sudo service cron status`
- Check crontab: `crontab -l`
- Look for errors in `/var/log/syslog`

**Wrong prayer times**
- Verify `latitude` and `longitude` in config
- Check `prayer_method` is appropriate for your region
- Check system timezone: `timedatectl`

## Timezone Configuration

Ensure your system timezone is correct:

```bash
# Check current timezone
timedatectl

# List available timezones
timedatectl list-timezones | grep -i chicago

# Set timezone
sudo timedatectl set-timezone America/Chicago
```

## Updating

To update to the latest version:

```bash
cd ~/ezan
git pull origin main
./install.sh  # Re-run installer to update files
```

Your `custom.config` will be preserved.

## Uninstall

1. Remove cron jobs:
   ```bash
   crontab -e
   # Delete the ezan.sh line and any ezanruncronjob lines
   ```

2. Remove directory:
   ```bash
   rm -rf ~/ezan
   ```

3. Remove from shell profile:
   ```bash
   # Edit ~/.bashrc or ~/.zshrc and remove EZAN_HOME export
   ```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Credits

- Prayer times from [Aladhan API](http://api.aladhan.com/)
- Chromecast integration via [pychromecast](https://github.com/home-assistant-libs/pychromecast)

## License

This project is provided as-is for personal use.
