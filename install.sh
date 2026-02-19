#!/bin/bash

# Ezan Installation Script
# Sets up the ezan prayer time system

set -e  # Exit on error

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================"
echo "Ezan Prayer Time System - Installer"
echo -e "======================================${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Ask for EZAN_HOME location
echo -e "${BLUE}Where would you like to install Ezan?${NC}"
echo "Press Enter to use default location: ~/ezan"
read -p "Installation path: " INSTALL_PATH

if [ -z "$INSTALL_PATH" ]; then
    EZAN_HOME="$HOME/ezan"
else
    EZAN_HOME="${INSTALL_PATH/#\~/$HOME}"  # Expand ~ to $HOME
fi

echo ""
echo -e "Installing to: ${GREEN}${EZAN_HOME}${NC}"
echo ""

# Create directory structure
echo -e "${BLUE}[1/7] Creating directory structure...${NC}"
mkdir -p "${EZAN_HOME}"
mkdir -p "${EZAN_HOME}/cache"

# Copy files if not already in target location
if [ "$SCRIPT_DIR" != "$EZAN_HOME" ]; then
    echo -e "${BLUE}[2/7] Copying files...${NC}"
    cp "${SCRIPT_DIR}"/*.sh "${EZAN_HOME}/" 2>/dev/null || true
    cp "${SCRIPT_DIR}"/*.py "${EZAN_HOME}/" 2>/dev/null || true
    cp "${SCRIPT_DIR}"/default.config "${EZAN_HOME}/" 2>/dev/null || true
    cp "${SCRIPT_DIR}"/requirements.txt "${EZAN_HOME}/" 2>/dev/null || true
    echo "  Files copied"
else
    echo -e "${BLUE}[2/7] Files already in place${NC}"
fi

# Make scripts executable
echo -e "${BLUE}[3/7] Making scripts executable...${NC}"
chmod +x "${EZAN_HOME}"/ezan.sh
chmod +x "${EZAN_HOME}"/ezan-vakti.sh
chmod +x "${EZAN_HOME}"/ezan-health-check.sh
echo "  Scripts are now executable"

# Check dependencies
echo -e "${BLUE}[4/7] Checking system dependencies...${NC}"

MISSING_DEPS=()

if ! command -v curl &> /dev/null; then
    MISSING_DEPS+=("curl")
fi

if ! command -v jq &> /dev/null; then
    MISSING_DEPS+=("jq")
fi

if ! command -v python3 &> /dev/null; then
    MISSING_DEPS+=("python3")
fi

if ! python3 -c "import venv" &> /dev/null 2>&1; then
    MISSING_DEPS+=("python3-venv")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "  ${RED}Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo "  Please install them using:"
    echo "    sudo apt install ${MISSING_DEPS[*]}"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "  ${GREEN}All system dependencies found${NC}"
fi

# Install Python dependencies
echo -e "${BLUE}[5/7] Installing Python dependencies...${NC}"
if command -v python3 &> /dev/null; then
    if [ -f "${EZAN_HOME}/requirements.txt" ]; then
        VENV_DIR="${EZAN_HOME}/venv"

        # Create virtual environment if it doesn't exist
        if [ ! -d "$VENV_DIR" ]; then
            echo "  Creating virtual environment..."
            python3 -m venv "$VENV_DIR"
        fi

        # Install packages into the venv
        "$VENV_DIR/bin/pip" install -r "${EZAN_HOME}/requirements.txt" --quiet
        echo -e "  ${GREEN}Python packages installed into venv${NC}"
    else
        echo -e "  ${YELLOW}requirements.txt not found, skipping${NC}"
    fi
else
    echo -e "  ${YELLOW}python3 not found, skipping Python packages${NC}"
fi

# Create custom.config
echo -e "${BLUE}[6/7] Creating configuration...${NC}"

if [ -f "${EZAN_HOME}/custom.config" ]; then
    echo -e "  ${YELLOW}custom.config already exists, skipping${NC}"
else
    echo ""
    echo "Please enter your location information:"
    echo ""

    read -p "Latitude (e.g., 42.040257): " LATITUDE
    read -p "Longitude (e.g., -87.6862397): " LONGITUDE

    echo ""
    echo "Prayer calculation method:"
    echo "  13 - Turkey (Diyanet)"
    echo "  2  - Islamic Society of North America (ISNA)"
    echo "  3  - Muslim World League"
    echo "  5  - Egyptian General Authority of Survey"
    echo "  See all methods: curl http://api.aladhan.com/v1/methods | jq"
    read -p "Prayer method (default: 13): " PRAYER_METHOD
    PRAYER_METHOD=${PRAYER_METHOD:-13}

    echo ""
    echo "Which prayer times would you like to be notified for?"
    read -p "Fajr? (y/N): " CALL_FAJR
    read -p "Dhuhr? (y/N): " CALL_DHUHR
    read -p "Asr? (y/N): " CALL_ASR
    read -p "Maghrib? (y/N): " CALL_MAGHRIB
    read -p "Isha? (y/N): " CALL_ISHA

    echo ""
    echo "Action to perform at prayer time:"
    echo "  1 - Cast to Chromecast"
    echo "  2 - Execute custom command"
    read -p "Choose action (1 or 2): " ACTION_CHOICE

    if [ "$ACTION_CHOICE" = "1" ]; then
        echo ""
        echo "Available Chromecast devices:"
        DEVICE_PYTHON="${EZAN_HOME}/venv/bin/python3"
        [ ! -f "$DEVICE_PYTHON" ] && DEVICE_PYTHON="python3"
        "$DEVICE_PYTHON" "${EZAN_HOME}/device-list.py" 2>/dev/null || echo "  (Run device-list.py to see available devices)"
        echo ""
        read -p "Enter Chromecast friendly name: " CAST_NAME

        cat > "${EZAN_HOME}/custom.config" <<EOF
# Custom Ezan Configuration

latitude="${LATITUDE}"
longitude="${LONGITUDE}"
prayer_method=${PRAYER_METHOD}

call_fajr=$( [[ $CALL_FAJR =~ ^[Yy]$ ]] && echo "true" || echo "false" )
call_dhuhr=$( [[ $CALL_DHUHR =~ ^[Yy]$ ]] && echo "true" || echo "false" )
call_asr=$( [[ $CALL_ASR =~ ^[Yy]$ ]] && echo "true" || echo "false" )
call_magrib=$( [[ $CALL_MAGHRIB =~ ^[Yy]$ ]] && echo "true" || echo "false" )
call_isha=$( [[ $CALL_ISHA =~ ^[Yy]$ ]] && echo "true" || echo "false" )

action=cast
cast_name="${CAST_NAME}"
EOF
    else
        read -p "Enter command to execute: " CUSTOM_COMMAND

        cat > "${EZAN_HOME}/custom.config" <<EOF
# Custom Ezan Configuration

latitude="${LATITUDE}"
longitude="${LONGITUDE}"
prayer_method=${PRAYER_METHOD}

call_fajr=$( [[ $CALL_FAJR =~ ^[Yy]$ ]] && echo "true" || echo "false" )
call_dhuhr=$( [[ $CALL_DHUHR =~ ^[Yy]$ ]] && echo "true" || echo "false" )
call_asr=$( [[ $CALL_ASR =~ ^[Yy]$ ]] && echo "true" || echo "false" )
call_magrib=$( [[ $CALL_MAGHRIB =~ ^[Yy]$ ]] && echo "true" || echo "false" )
call_isha=$( [[ $CALL_ISHA =~ ^[Yy]$ ]] && echo "true" || echo "false" )

action=command
command_script="${CUSTOM_COMMAND}"
EOF
    fi

    echo -e "  ${GREEN}Configuration created${NC}"
fi

# Setup cron job
echo -e "${BLUE}[7/7] Setting up cron job...${NC}"
echo ""
echo "A daily cron job is needed to schedule prayer times each day."
echo "Recommended: Run at 1 AM daily"
echo ""
read -p "Install daily cron job? (Y/n): " INSTALL_CRON

if [[ ! $INSTALL_CRON =~ ^[Nn]$ ]]; then
    CRON_CMD="0 1 * * * ${EZAN_HOME}/ezan.sh >> ${EZAN_HOME}/ezan.log 2>&1"

    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "${EZAN_HOME}/ezan.sh"; then
        echo -e "  ${YELLOW}Cron job already exists${NC}"
    else
        # Add to crontab
        (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
        echo -e "  ${GREEN}Cron job installed${NC}"
        echo "  Schedule: Daily at 1 AM"
    fi

    # Run ezan.sh immediately to schedule today's prayers
    echo ""
    read -p "Run ezan.sh now to schedule today's prayer times? (Y/n): " RUN_NOW
    if [[ ! $RUN_NOW =~ ^[Nn]$ ]]; then
        export EZAN_HOME
        "${EZAN_HOME}/ezan.sh"
        echo -e "  ${GREEN}Prayer times scheduled for today${NC}"
    fi
else
    echo -e "  ${YELLOW}Skipped cron setup${NC}"
    echo "  You can add it manually later:"
    echo "    crontab -e"
    echo "    Add: 0 1 * * * ${EZAN_HOME}/ezan.sh >> ${EZAN_HOME}/ezan.log 2>&1"
fi

# Add EZAN_HOME to shell profile
echo ""
echo -e "${BLUE}Adding EZAN_HOME to shell profile...${NC}"

SHELL_RC="${HOME}/.bashrc"
if [ -f "${HOME}/.zshrc" ]; then
    SHELL_RC="${HOME}/.zshrc"
fi

if ! grep -q "EZAN_HOME" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Ezan prayer time system" >> "$SHELL_RC"
    echo "export EZAN_HOME=\"${EZAN_HOME}\"" >> "$SHELL_RC"
    echo -e "  ${GREEN}Added EZAN_HOME to ${SHELL_RC}${NC}"
else
    echo -e "  ${YELLOW}EZAN_HOME already in shell profile${NC}"
fi

# Installation complete
echo ""
echo -e "${GREEN}======================================"
echo "Installation Complete!"
echo -e "======================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Reload your shell: source ${SHELL_RC}"
echo "  2. Run health check: ${EZAN_HOME}/ezan-health-check.sh"
echo "  3. Test configuration: ${EZAN_HOME}/ezan-vakti.sh --all"
echo ""
echo "Configuration file: ${EZAN_HOME}/custom.config"
echo "Log file: ${EZAN_HOME}/ezan.log"
echo ""
echo -e "${BLUE}May your prayers be accepted!${NC}"
