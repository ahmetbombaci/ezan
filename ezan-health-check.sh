#!/bin/bash

# Ezan Health Check Script
# Verifies the ezan system is configured correctly and running properly

# Set EZAN_HOME to ~/ezan/ if not already set
EZAN_HOME="${EZAN_HOME:-$HOME/ezan}"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "Ezan System Health Check"
echo "======================================"
echo ""

ERRORS=0
WARNINGS=0

# Check 1: EZAN_HOME directory exists
echo -n "Checking EZAN_HOME directory... "
if [ -d "${EZAN_HOME}" ]; then
    echo -e "${GREEN}OK${NC} (${EZAN_HOME})"
else
    echo -e "${RED}FAILED${NC}"
    echo "  Directory ${EZAN_HOME} does not exist"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: Config files exist
echo -n "Checking default.config... "
if [ -f "${EZAN_HOME}/default.config" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "  File ${EZAN_HOME}/default.config not found"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Checking custom.config... "
if [ -f "${EZAN_HOME}/custom.config" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}WARNING${NC}"
    echo "  File ${EZAN_HOME}/custom.config not found (optional)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 3: Required commands
echo -n "Checking for curl... "
if command -v curl &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "  curl is not installed"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Checking for jq... "
if command -v jq &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "  jq is not installed"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Checking for python3... "
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "  python3 is not installed"
    ERRORS=$((ERRORS + 1))
fi

# Detect which Python will be used by ezan.sh
echo -n "Detecting Python interpreter for cronjobs... "
if [ -f "${EZAN_HOME}/.venv/bin/python3" ]; then
    PYTHON_CMD="${EZAN_HOME}/.venv/bin/python3"
    echo -e "${GREEN}OK${NC} (venv)"
    echo "  Using: ${PYTHON_CMD}"
elif [ -f "${EZAN_HOME}/venv/bin/python3" ]; then
    PYTHON_CMD="${EZAN_HOME}/venv/bin/python3"
    echo -e "${GREEN}OK${NC} (venv)"
    echo "  Using: ${PYTHON_CMD}"
elif [ -n "$VIRTUAL_ENV" ] && [ -f "$VIRTUAL_ENV/bin/python3" ]; then
    PYTHON_CMD="$VIRTUAL_ENV/bin/python3"
    echo -e "${YELLOW}WARNING${NC}"
    echo "  Using active venv: ${PYTHON_CMD}"
    echo "  Note: Cronjobs won't have VIRTUAL_ENV set. Consider installing to ${EZAN_HOME}/.venv"
    WARNINGS=$((WARNINGS + 1))
else
    PYTHON_CMD="python3"
    echo -e "${GREEN}OK${NC} (system)"
    echo "  Using: system python3"
fi

# Check 4: Python dependencies
echo -n "Checking Python dependencies... "
if ${PYTHON_CMD} -c "import click, requests, pychromecast" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}WARNING${NC}"
    echo "  Some Python packages may be missing in ${PYTHON_CMD}"
    if [ "$PYTHON_CMD" != "python3" ]; then
        echo "  Install with: ${PYTHON_CMD} -m pip install -r ${EZAN_HOME}/requirements.txt"
    else
        echo "  Install with: pip3 install --user -r ${EZAN_HOME}/requirements.txt"
    fi
    WARNINGS=$((WARNINGS + 1))
fi

# Check 5: Cache directory
echo -n "Checking cache directory... "
if [ -d "${EZAN_HOME}/cache" ]; then
    echo -e "${GREEN}OK${NC}"

    # Check for today's cache
    TODAY_CACHE="${EZAN_HOME}/cache/$(date +%y%m%d)"
    echo -n "  Checking today's cache... "
    if [ -f "${TODAY_CACHE}" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}NOT FOUND${NC}"
        echo "    No cache for today. Will be created on next run."
    fi
else
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo "  Will be created automatically"
fi

# Check 6: Cronjob status
echo -n "Checking for ezan cronjobs... "
CRON_COUNT=$(crontab -l 2>/dev/null | grep -c "ezanruncronjob")
if [ "$CRON_COUNT" -gt 0 ]; then
    echo -e "${GREEN}OK${NC} (${CRON_COUNT} jobs scheduled)"
    echo "  Scheduled prayer time jobs:"
    crontab -l 2>/dev/null | grep "ezanruncronjob" | while read -r line; do
        echo "    $line"
    done
else
    echo -e "${YELLOW}WARNING${NC}"
    echo "  No prayer time cronjobs found"
    echo "  Run ezan.sh to schedule today's prayer times"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 7: Main cronjob (daily scheduler)
echo -n "Checking for daily ezan.sh cronjob... "
if crontab -l 2>/dev/null | grep -q "ezan.sh"; then
    echo -e "${GREEN}OK${NC}"
    DAILY_JOB=$(crontab -l 2>/dev/null | grep "ezan.sh")
    echo "  Daily job: $DAILY_JOB"
else
    echo -e "${YELLOW}WARNING${NC}"
    echo "  No daily ezan.sh cronjob found"
    echo "  Add one with: crontab -e"
    echo "  Example: 0 1 * * * ${EZAN_HOME}/ezan.sh >> ${EZAN_HOME}/ezan.log 2>&1"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 8: API connectivity
echo -n "Checking API connectivity... "
if curl --silent --max-time 5 "http://api.aladhan.com/v1/methods" > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "  Cannot reach api.aladhan.com"
    echo "  Check your internet connection"
    ERRORS=$((ERRORS + 1))
fi

# Check 9: Log file
echo -n "Checking log file... "
if [ -f "${EZAN_HOME}/ezan.log" ]; then
    echo -e "${GREEN}OK${NC}"
    LOG_SIZE=$(stat -f%z "${EZAN_HOME}/ezan.log" 2>/dev/null || stat -c%s "${EZAN_HOME}/ezan.log" 2>/dev/null)
    if [ -n "$LOG_SIZE" ]; then
        echo "  Size: $((LOG_SIZE / 1024)) KB"
    fi

    # Check for recent errors
    if [ -f "${EZAN_HOME}/ezan.log" ]; then
        ERROR_COUNT=$(grep -c "ERROR" "${EZAN_HOME}/ezan.log" 2>/dev/null || echo 0)
        if [ "$ERROR_COUNT" -gt 0 ]; then
            echo -e "  ${YELLOW}Found ${ERROR_COUNT} error(s) in log${NC}"
            echo "  Last 3 errors:"
            grep "ERROR" "${EZAN_HOME}/ezan.log" | tail -3 | while read -r line; do
                echo "    $line"
            done
        fi
    fi
else
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo "  Will be created on next run"
fi

# Summary
echo ""
echo "======================================"
echo "Health Check Summary"
echo "======================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}${WARNINGS} warning(s) found${NC}"
    exit 0
else
    echo -e "${RED}${ERRORS} error(s) found, ${WARNINGS} warning(s)${NC}"
    echo "Please fix the errors above before running ezan."
    exit 1
fi
