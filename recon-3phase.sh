#!/bin/bash

# Web Recon 2025 - 3-Phase Reconnaissance Script
# Implements the complete workflow with interactive parameters, parallel execution, and HTML reporting

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORK_DIR="recon_${TIMESTAMP}"
RESULTS_DIR="${WORK_DIR}/results"
LOGS_DIR="${WORK_DIR}/logs"
REPORT_FILE="${WORK_DIR}/report.html"

# Tool tracking
declare -A TOOL_COMMANDS
declare -A TOOL_PIDS
declare -A TOOL_STATUS
declare -a EXECUTED_TOOLS

# Ensure PATH includes Go binaries
export PATH="$HOME/go/bin:$PATH"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

setup_directories() {
    mkdir -p "$RESULTS_DIR" "$LOGS_DIR"
    log_success "Created working directory: $WORK_DIR"
}

# ============================================================================
# INTERACTIVE PARAMETER COLLECTION
# ============================================================================

prompt_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -p "$(echo -e ${CYAN}$prompt${NC}) (y/n): " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            [nN][oO]|[nN]) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local response
    
    if [ -z "$default" ]; then
        read -p "$(echo -e ${CYAN}$prompt${NC}): " response
    else
        read -p "$(echo -e ${CYAN}$prompt${NC}) [$default]: " response
        response="${response:-$default}"
    fi
    echo "$response"
}

# ============================================================================
# PHASE 1: SURFACE MAXIMIZATION
# ============================================================================

phase1_collect_params() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}PHASE 1: SURFACE MAXIMIZATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    PHASE1_TARGET=$(prompt_input "Enter target domain" "example.com")
    PHASE1_SUBFINDER=true
    PHASE1_ASSETFINDER=true
    PHASE1_GAU=true
    PHASE1_WAYBACKURLS=true
    PHASE1_DNSX=true
    
    if prompt_yes_no "Use custom DNS resolvers for dnsx?"; then
        PHASE1_RESOLVERS=$(prompt_input "Path to resolvers file" "/etc/resolv.conf")
    else
        PHASE1_RESOLVERS=""
    fi
    
    log_success "Phase 1 parameters collected"
}

run_phase1() {
    log_info "Starting Phase 1: Surface Maximization"
    
    local phase1_log="${LOGS_DIR}/phase1.log"
    > "$phase1_log"
    
    # subfinder
    if [ "$PHASE1_SUBFINDER" = true ]; then
        log_info "Running subfinder on $PHASE1_TARGET..."
        (
            subfinder -d "$PHASE1_TARGET" -silent -o "${RESULTS_DIR}/phase1_subfinder.txt" 2>&1 | tee -a "$phase1_log"
        ) &
        TOOL_PIDS["subfinder"]=$!
        TOOL_COMMANDS["subfinder"]="subfinder -d ${PHASE1_TARGET} -silent"
        EXECUTED_TOOLS+=("subfinder")
    fi
    
    # assetfinder
    if [ "$PHASE1_ASSETFINDER" = true ]; then
        log_info "Running assetfinder on $PHASE1_TARGET..."
        (
            assetfinder --subs-only "$PHASE1_TARGET" 2>&1 | tee "${RESULTS_DIR}/phase1_assetfinder.txt" | tee -a "$phase1_log"
        ) &
        TOOL_PIDS["assetfinder"]=$!
        TOOL_COMMANDS["assetfinder"]="assetfinder --subs-only ${PHASE1_TARGET}"
        EXECUTED_TOOLS+=("assetfinder")
    fi
    
    # gau
    if [ "$PHASE1_GAU" = true ]; then
        log_info "Running gau on $PHASE1_TARGET..."
        (
            gau --subs "$PHASE1_TARGET" 2>&1 | tee "${RESULTS_DIR}/phase1_gau.txt" | tee -a "$phase1_log"
        ) &
        TOOL_PIDS["gau"]=$!
        TOOL_COMMANDS["gau"]="gau --subs ${PHASE1_TARGET}"
        EXECUTED_TOOLS+=("gau")
    fi
    
    # waybackurls
    if [ "$PHASE1_WAYBACKURLS" = true ]; then
        log_info "Running waybackurls on $PHASE1_TARGET..."
        (
            echo "$PHASE1_TARGET" | waybackurls 2>&1 | tee "${RESULTS_DIR}/phase1_waybackurls.txt" | tee -a "$phase1_log"
        ) &
        TOOL_PIDS["waybackurls"]=$!
        TOOL_COMMANDS["waybackurls"]="echo ${PHASE1_TARGET} | waybackurls"
        EXECUTED_TOOLS+=("waybackurls")
    fi
    
    # Merge results and resolve with dnsx
    wait_for_phase "Phase 1" "subfinder" "assetfinder" "gau" "waybackurls"
    
    if [ "$PHASE1_DNSX" = true ]; then
        log_info "Merging subdomain results..."
        cat "${RESULTS_DIR}/phase1_"*.txt 2>/dev/null | sort -u > "${RESULTS_DIR}/phase1_all_subdomains.txt"
        
        log_info "Resolving subdomains with dnsx..."
        local dnsx_cmd="dnsx -l ${RESULTS_DIR}/phase1_all_subdomains.txt -silent -o ${RESULTS_DIR}/phase1_resolved.txt"
        if [ -n "$PHASE1_RESOLVERS" ] && [ -f "$PHASE1_RESOLVERS" ]; then
            dnsx_cmd="dnsx -l ${RESULTS_DIR}/phase1_all_subdomains.txt -r $PHASE1_RESOLVERS -silent -o ${RESULTS_DIR}/phase1_resolved.txt"
        fi
        
        (
            eval "$dnsx_cmd" 2>&1 | tee -a "$phase1_log"
        ) &
        TOOL_PIDS["dnsx"]=$!
        TOOL_COMMANDS["dnsx"]="$dnsx_cmd"
        EXECUTED_TOOLS+=("dnsx")
        
        wait_for_phase "Phase 1" "dnsx"
    fi
    
    log_success "Phase 1 completed"
}

# ============================================================================
# PHASE 2: PORT & SERVICE FINGERPRINTING
# ============================================================================

phase2_collect_params() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}PHASE 2: PORT & SERVICE FINGERPRINTING${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    if [ -f "${RESULTS_DIR}/phase1_resolved.txt" ]; then
        log_success "Found Phase 1 resolved hosts"
        PHASE2_HOSTS="${RESULTS_DIR}/phase1_resolved.txt"
    else
        PHASE2_HOSTS=$(prompt_input "Path to hosts file" "")
    fi
    
    PHASE2_NAABU=true
    PHASE2_HTTPX=true
    PHASE2_HTTPROBE=true
    
    if prompt_yes_no "Run masscan (requires root)?"; then
        PHASE2_MASSCAN=true
        PHASE2_MASSCAN_RATE=$(prompt_input "Masscan rate (packets/sec)" "1000")
    else
        PHASE2_MASSCAN=false
    fi
    
    log_success "Phase 2 parameters collected"
}

run_phase2() {
    log_info "Starting Phase 2: Port & Service Fingerprinting"
    
    if [ ! -f "$PHASE2_HOSTS" ]; then
        log_error "Hosts file not found: $PHASE2_HOSTS"
        return 1
    fi
    
    local phase2_log="${LOGS_DIR}/phase2.log"
    > "$phase2_log"
    
    # naabu
    if [ "$PHASE2_NAABU" = true ]; then
        log_info "Running naabu on hosts..."
        (
            naabu -l "$PHASE2_HOSTS" -p - -silent -o "${RESULTS_DIR}/phase2_naabu_ports.txt" 2>&1 | tee -a "$phase2_log"
        ) &
        TOOL_PIDS["naabu"]=$!
        TOOL_COMMANDS["naabu"]="naabu -l ${PHASE2_HOSTS} -p - -silent"
        EXECUTED_TOOLS+=("naabu")
    fi
    
    # httpx
    if [ "$PHASE2_HTTPX" = true ]; then
        log_info "Running httpx on hosts..."
        (
            httpx -l "$PHASE2_HOSTS" -silent -title -status-code -o "${RESULTS_DIR}/phase2_httpx.txt" 2>&1 | tee -a "$phase2_log"
        ) &
        TOOL_PIDS["httpx"]=$!
        TOOL_COMMANDS["httpx"]="httpx -l ${PHASE2_HOSTS} -silent -title -status-code"
        EXECUTED_TOOLS+=("httpx")
    fi
    
    # httprobe
    if [ "$PHASE2_HTTPROBE" = true ]; then
        log_info "Running httprobe on hosts..."
        (
            cat "$PHASE2_HOSTS" | httprobe -c 50 2>&1 | tee "${RESULTS_DIR}/phase2_httprobe.txt" | tee -a "$phase2_log"
        ) &
        TOOL_PIDS["httprobe"]=$!
        TOOL_COMMANDS["httprobe"]="cat ${PHASE2_HOSTS} | httprobe -c 50"
        EXECUTED_TOOLS+=("httprobe")
    fi
    
    wait_for_phase "Phase 2" "naabu" "httpx" "httprobe"
    
    # masscan (if enabled and root)
    if [ "$PHASE2_MASSCAN" = true ]; then
        if [ "$EUID" -eq 0 ]; then
            log_info "Running masscan..."
            (
                masscan -iL "$PHASE2_HOSTS" -p0-65535 --rate "$PHASE2_MASSCAN_RATE" -oX "${RESULTS_DIR}/phase2_masscan.xml" 2>&1 | tee -a "$phase2_log"
            ) &
            TOOL_PIDS["masscan"]=$!
            TOOL_COMMANDS["masscan"]="masscan -iL $PHASE2_HOSTS -p0-65535 --rate $PHASE2_MASSCAN_RATE"
            EXECUTED_TOOLS+=("masscan")
            wait_for_phase "Phase 2" "masscan"
        else
            log_warning "Masscan requires root privileges, skipping..."
        fi
    fi
    
    log_success "Phase 2 completed"
}

# ============================================================================
# PHASE 3: PARAMETER & ENDPOINT MINING
# ============================================================================

phase3_collect_params() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}PHASE 3: PARAMETER & ENDPOINT MINING${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    if [ -f "${RESULTS_DIR}/phase2_httpx.txt" ]; then
        log_success "Found Phase 2 HTTP services"
        PHASE3_URLS="${RESULTS_DIR}/phase2_httpx.txt"
    else
        PHASE3_URLS=$(prompt_input "Path to URLs file" "")
    fi
    
    PHASE3_KATANA=true
    PHASE3_GF=true
    PHASE3_NUCLEI=true
    
    if [ "$PHASE3_KATANA" = true ]; then
        PHASE3_KATANA_DEPTH=$(prompt_input "Katana crawl depth" "2")
    fi
    
    if [ "$PHASE3_NUCLEI" = true ]; then
        PHASE3_NUCLEI_TEMPLATES=$(prompt_input "Nuclei template directory" "cves/")
    fi
    
    log_success "Phase 3 parameters collected"
}

run_phase3() {
    log_info "Starting Phase 3: Parameter & Endpoint Mining"
    
    if [ ! -f "$PHASE3_URLS" ]; then
        log_error "URLs file not found: $PHASE3_URLS"
        return 1
    fi
    
    local phase3_log="${LOGS_DIR}/phase3.log"
    > "$phase3_log"
    
    # katana
    if [ "$PHASE3_KATANA" = true ]; then
        log_info "Running katana with depth $PHASE3_KATANA_DEPTH..."
        (
            katana -l "$PHASE3_URLS" -d "$PHASE3_KATANA_DEPTH" -silent -o "${RESULTS_DIR}/phase3_katana_urls.txt" 2>&1 | tee -a "$phase3_log"
        ) &
        TOOL_PIDS["katana"]=$!
        TOOL_COMMANDS["katana"]="katana -l ${PHASE3_URLS} -d ${PHASE3_KATANA_DEPTH} -silent"
        EXECUTED_TOOLS+=("katana")
    fi
    
    wait_for_phase "Phase 3" "katana"
    
    # gf pattern matching
    if [ "$PHASE3_GF" = true ] && [ -f "${RESULTS_DIR}/phase3_katana_urls.txt" ]; then
        log_info "Running gf pattern matching..."
        
        for pattern in lfi sqli xss ssrf rce upload; do
            (
                gf "$pattern" "${RESULTS_DIR}/phase3_katana_urls.txt" > "${RESULTS_DIR}/phase3_gf_${pattern}.txt" 2>&1
            ) &
            TOOL_PIDS["gf_${pattern}"]=$!
            TOOL_COMMANDS["gf_${pattern}"]="gf ${pattern} \${RESULTS_DIR}/phase3_katana_urls.txt"
            EXECUTED_TOOLS+=("gf_${pattern}")
        done
        
        wait_for_phase "Phase 3" "gf_lfi" "gf_sqli" "gf_xss" "gf_ssrf" "gf_rce" "gf_upload"
    fi
    
    # nuclei
    if [ "$PHASE3_NUCLEI" = true ]; then
        log_info "Running nuclei with templates: $PHASE3_NUCLEI_TEMPLATES..."
        (
            nuclei -l "$PHASE3_URLS" -t "$PHASE3_NUCLEI_TEMPLATES" -silent -o "${RESULTS_DIR}/phase3_nuclei_results.txt" 2>&1 | tee -a "$phase3_log"
        ) &
        TOOL_PIDS["nuclei"]=$!
        TOOL_COMMANDS["nuclei"]="nuclei -l ${PHASE3_URLS} -t ${PHASE3_NUCLEI_TEMPLATES} -silent"
        EXECUTED_TOOLS+=("nuclei")
        
        wait_for_phase "Phase 3" "nuclei"
    fi
    
    log_success "Phase 3 completed"
}

# ============================================================================
# EXECUTION HELPERS
# ============================================================================

wait_for_phase() {
    local phase_name="$1"
    shift
    local tools=("$@")
    
    for tool in "${tools[@]}"; do
        if [ -n "${TOOL_PIDS[$tool]}" ]; then
            wait "${TOOL_PIDS[$tool]}"
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                TOOL_STATUS[$tool]="success"
                log_success "$tool completed"
            else
                TOOL_STATUS[$tool]="failed"
                log_error "$tool failed with exit code $exit_code"
            fi
            unset TOOL_PIDS[$tool]
        fi
    done
}

# ============================================================================
# HTML REPORT GENERATION
# ============================================================================

generate_mermaid_diagram() {
    local phase="$1"
    local tools=("${@:2}")
    
    echo "graph LR"
    echo "    Start([Start $phase])"
    
    local prev="Start"
    for tool in "${tools[@]}"; do
        local status="${TOOL_STATUS[$tool]:-unknown}"
        local color="lightblue"
        [ "$status" = "success" ] && color="lightgreen"
        [ "$status" = "failed" ] && color="lightcoral"
        
        echo "    $prev --> $tool[$tool<br/>($status)]"
        echo "    style $tool fill:$color"
        prev="$tool"
    done
    
    echo "    $prev --> End([End $phase])"
}

generate_html_report() {
    log_info "Generating HTML report..."
    
    cat > "$REPORT_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Recon 2025 - Reconnaissance Report</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #e0e0e0;
            line-height: 1.6;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        header {
            background: linear-gradient(135deg, #0f3460 0%, #16213e 100%);
            padding: 40px 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            border-left: 5px solid #00d4ff;
        }
        
        h1 {
            color: #00d4ff;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .subtitle {
            color: #b0b0b0;
            font-size: 1.1em;
        }
        
        .metadata {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #444;
        }
        
        .meta-item {
            background: rgba(0, 212, 255, 0.1);
            padding: 12px;
            border-radius: 5px;
            border-left: 3px solid #00d4ff;
        }
        
        .meta-label {
            color: #00d4ff;
            font-weight: bold;
            font-size: 0.9em;
        }
        
        .meta-value {
            color: #e0e0e0;
            margin-top: 5px;
        }
        
        .phase-section {
            background: #16213e;
            border-radius: 10px;
            padding: 25px;
            margin-bottom: 30px;
            border-left: 5px solid #00d4ff;
        }
        
        .phase-title {
            color: #00d4ff;
            font-size: 1.8em;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
        }
        
        .phase-title::before {
            content: '';
            display: inline-block;
            width: 10px;
            height: 10px;
            background: #00d4ff;
            border-radius: 50%;
            margin-right: 10px;
        }
        
        .mermaid-container {
            background: #0f3460;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            overflow-x: auto;
        }
        
        .tools-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        
        .tool-card {
            background: #0f3460;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #00d4ff;
        }
        
        .tool-name {
            color: #00d4ff;
            font-weight: bold;
            font-size: 1.1em;
            margin-bottom: 8px;
        }
        
        .tool-command {
            background: #1a1a2e;
            padding: 10px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 0.85em;
            color: #00ff00;
            overflow-x: auto;
            word-break: break-all;
        }
        
        .tool-status {
            margin-top: 10px;
            padding: 8px;
            border-radius: 4px;
            font-size: 0.9em;
            font-weight: bold;
        }
        
        .status-success {
            background: rgba(76, 175, 80, 0.2);
            color: #4caf50;
        }
        
        .status-failed {
            background: rgba(244, 67, 54, 0.2);
            color: #f44336;
        }
        
        .status-unknown {
            background: rgba(255, 193, 7, 0.2);
            color: #ffc107;
        }
        
        .results-section {
            margin-top: 20px;
        }
        
        .results-title {
            color: #00d4ff;
            font-size: 1.2em;
            margin-bottom: 15px;
            font-weight: bold;
        }
        
        .result-file {
            background: #0f3460;
            padding: 12px;
            margin-bottom: 10px;
            border-radius: 5px;
            border-left: 3px solid #00ff00;
        }
        
        .result-file-name {
            color: #00ff00;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }
        
        .result-file-size {
            color: #b0b0b0;
            font-size: 0.85em;
            margin-top: 5px;
        }
        
        .summary {
            background: linear-gradient(135deg, #0f3460 0%, #16213e 100%);
            padding: 20px;
            border-radius: 10px;
            margin-top: 30px;
            border-left: 5px solid #00d4ff;
        }
        
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        
        .summary-item {
            text-align: center;
            padding: 15px;
            background: rgba(0, 212, 255, 0.1);
            border-radius: 5px;
        }
        
        .summary-number {
            color: #00d4ff;
            font-size: 2em;
            font-weight: bold;
        }
        
        .summary-label {
            color: #b0b0b0;
            margin-top: 5px;
        }
        
        footer {
            text-align: center;
            padding: 20px;
            color: #666;
            border-top: 1px solid #444;
            margin-top: 40px;
        }
        
        .mermaid {
            display: flex;
            justify-content: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔍 Web Recon 2025</h1>
            <p class="subtitle">Command-Line Intelligence Workflow - Reconnaissance Report</p>
            <div class="metadata">
                <div class="meta-item">
                    <div class="meta-label">Report Generated</div>
                    <div class="meta-value">REPORT_TIMESTAMP</div>
                </div>
                <div class="meta-item">
                    <div class="meta-label">Target Domain</div>
                    <div class="meta-value">TARGET_DOMAIN</div>
                </div>
                <div class="meta-item">
                    <div class="meta-label">Working Directory</div>
                    <div class="meta-value">WORK_DIR_PATH</div>
                </div>
            </div>
        </header>
        
        PHASE_SECTIONS
        
        <div class="summary">
            <h2 style="color: #00d4ff; margin-bottom: 15px;">📊 Execution Summary</h2>
            <div class="summary-grid">
                <div class="summary-item">
                    <div class="summary-number">TOTAL_TOOLS</div>
                    <div class="summary-label">Tools Executed</div>
                </div>
                <div class="summary-item">
                    <div class="summary-number">SUCCESS_COUNT</div>
                    <div class="summary-label">Successful</div>
                </div>
                <div class="summary-item">
                    <div class="summary-number">FAILED_COUNT</div>
                    <div class="summary-label">Failed</div>
                </div>
                <div class="summary-item">
                    <div class="summary-number">RESULT_FILES</div>
                    <div class="summary-label">Result Files</div>
                </div>
            </div>
        </div>
        
        <footer>
            <p>Web Recon 2025 - Automated Reconnaissance Framework</p>
            <p>All tools executed in parallel where possible for optimal performance</p>
        </footer>
    </div>
    
    <script>
        mermaid.initialize({ startOnLoad: true, theme: 'dark' });
        mermaid.contentLoaded();
    </script>
</body>
</html>
EOF

    # Replace placeholders
    sed -i "s|REPORT_TIMESTAMP|$(date)|g" "$REPORT_FILE"
    sed -i "s|TARGET_DOMAIN|${PHASE1_TARGET:-N/A}|g" "$REPORT_FILE"
    sed -i "s|WORK_DIR_PATH|$(pwd)/$WORK_DIR|g" "$REPORT_FILE"
    
    # Generate phase sections
    local phase_sections=""
    
    # Phase 1 section
    phase_sections+=$(generate_phase_html "1" "Surface Maximization" "subfinder" "assetfinder" "gau" "waybackurls" "dnsx")
    
    # Phase 2 section
    phase_sections+=$(generate_phase_html "2" "Port & Service Fingerprinting" "naabu" "httpx" "httprobe" "masscan")
    
    # Phase 3 section
    phase_sections+=$(generate_phase_html "3" "Parameter & Endpoint Mining" "katana" "gf_lfi" "gf_sqli" "gf_xss" "nuclei")
    
    sed -i "s|PHASE_SECTIONS|$phase_sections|g" "$REPORT_FILE"
    
    # Count results
    local total_tools=${#EXECUTED_TOOLS[@]}
    local success_count=0
    local failed_count=0
    for tool in "${EXECUTED_TOOLS[@]}"; do
        [ "${TOOL_STATUS[$tool]}" = "success" ] && ((success_count++))
        [ "${TOOL_STATUS[$tool]}" = "failed" ] && ((failed_count++))
    done
    local result_files=$(find "$RESULTS_DIR" -type f | wc -l)
    
    sed -i "s|TOTAL_TOOLS|$total_tools|g" "$REPORT_FILE"
    sed -i "s|SUCCESS_COUNT|$success_count|g" "$REPORT_FILE"
    sed -i "s|FAILED_COUNT|$failed_count|g" "$REPORT_FILE"
    sed -i "s|RESULT_FILES|$result_files|g" "$REPORT_FILE"
    
    log_success "HTML report generated: $REPORT_FILE"
}

generate_phase_html() {
    local phase_num="$1"
    local phase_name="$2"
    shift 2
    local tools=("$@")
    
    local html="<div class='phase-section'>"
    html+="<h2 class='phase-title'>Phase $phase_num: $phase_name</h2>"
    
    # Mermaid diagram
    html+="<div class='mermaid-container'>"
    html+="<div class='mermaid'>"
    local mermaid_content=$(generate_mermaid_diagram "Phase $phase_num" "${tools[@]}")
    html+="$mermaid_content"
    html+="</div></div>"
    
    # Tools grid
    html+="<div class='tools-grid'>"
    for tool in "${tools[@]}"; do
        local status="${TOOL_STATUS[$tool]:-unknown}"
        local status_class="status-$status"
        local cmd="${TOOL_COMMANDS[$tool]:-N/A}"
        
        html+="<div class='tool-card'>"
        html+="<div class='tool-name'>$tool</div>"
        html+="<div class='tool-command'>$cmd</div>"
        html+="<div class='tool-status $status_class'>Status: $status</div>"
        html+="</div>"
    done
    html+="</div>"
    
    # Results files
    html+="<div class='results-section'>"
    html+="<div class='results-title'>📁 Result Files</div>"
    if ls "$RESULTS_DIR"/phase${phase_num}_* 1> /dev/null 2>&1; then
        for file in "$RESULTS_DIR"/phase${phase_num}_*; do
            if [ -f "$file" ]; then
                local size=$(du -h "$file" | cut -f1)
                html+="<div class='result-file'>"
                html+="<div class='result-file-name'>$(basename "$file")</div>"
                html+="<div class='result-file-size'>Size: $size</div>"
                html+="</div>"
            fi
        done
    else
        html+="<div class='result-file'><div class='result-file-name'>No results generated</div></div>"
    fi
    html+="</div>"
    
    html+="</div>"
    echo "$html"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║        Web Recon 2025 - 3-Phase Reconnaissance Script        ║
║              Command-Line Intelligence Workflow              ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    setup_directories
    
    # Phase 1
    phase1_collect_params
    run_phase1
    
    # Phase 2
    phase2_collect_params
    run_phase2
    
    # Phase 3
    phase3_collect_params
    run_phase3
    
    # Generate report
    generate_html_report
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Reconnaissance Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Working Directory: ${CYAN}$(pwd)/$WORK_DIR${NC}"
    echo -e "Report File: ${CYAN}$(pwd)/$REPORT_FILE${NC}"
    echo -e "Results Directory: ${CYAN}$(pwd)/$RESULTS_DIR${NC}"
    echo -e "Logs Directory: ${CYAN}$(pwd)/$LOGS_DIR${NC}"
    echo ""
    echo -e "Open the report in a browser to view results and diagrams"
    echo ""
}

main "$@"
