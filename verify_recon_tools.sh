#!/bin/bash

# Verification script for Web Reconnaissance Tools
# This script checks if all installed tools are accessible

echo "================================"
echo "Web Recon Tools Verification"
echo "================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for results
TOTAL=0
WORKING=0
FAILED=0

# Function to check tool
check_tool() {
    local tool=$1
    
    TOTAL=$((TOTAL + 1))
    
    if command -v "$tool" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $tool"
        WORKING=$((WORKING + 1))
    else
        echo -e "${RED}✗${NC} $tool - NOT FOUND"
        FAILED=$((FAILED + 1))
    fi
}

echo "Phase 1: Surface Maximization Tools"
echo "-----------------------------------"
check_tool "subfinder"
check_tool "assetfinder"
check_tool "anew"
check_tool "dnsx"
check_tool "gau"
check_tool "waybackurls"
check_tool "jq"
check_tool "rg"
echo ""

echo "Phase 2: Port & Service Fingerprinting Tools"
echo "--------------------------------------------"
check_tool "masscan"
check_tool "naabu"
check_tool "massdns"
check_tool "zmap"
check_tool "httpx"
check_tool "httprobe"
echo ""

echo "Phase 3: Parameter & Endpoint Mining Tools"
echo "------------------------------------------"
check_tool "katana"
check_tool "gf"
check_tool "qsreplace"
check_tool "nuclei"
echo ""

echo "================================"
echo "Summary"
echo "================================"
echo -e "Total Tools: $TOTAL"
echo -e "${GREEN}Working: $WORKING${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
else
    echo -e "${GREEN}Failed: $FAILED${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tools are installed and accessible!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tools are missing. See above for details.${NC}"
    exit 1
fi
