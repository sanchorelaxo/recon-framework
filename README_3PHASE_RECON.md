# Web Recon 2025 - 3-Phase Reconnaissance Framework

## Overview

A comprehensive automated reconnaissance framework implementing the Web Recon 2025 workflow with three phases:

1. **Phase 1: Surface Maximization** - Subdomain and asset discovery
2. **Phase 2: Port & Service Fingerprinting** - Port scanning and service detection  
3. **Phase 3: Parameter & Endpoint Mining** - URL crawling and vulnerability scanning

### Key Features

✅ **Interactive Parameter Collection** - Guided prompts for each phase
✅ **Parallel Tool Execution** - Run multiple tools simultaneously for speed
✅ **HTML Report Generation** - Professional report with embedded Mermaid diagrams
✅ **Tool Flow Visualization** - See execution flow and status for each tool
✅ **Comprehensive Logging** - Detailed logs for debugging and auditing
✅ **Automatic Result Chaining** - Phase outputs feed into next phase inputs

---

## Quick Start

### Prerequisites

All reconnaissance tools must be installed:
```bash
/home/rjodouin/verify_recon_tools.sh
```

### Run the Script

```bash
export PATH="$HOME/go/bin:$PATH"
./recon-3phase.sh
```

Or use the demo version (more stable):
```bash
./recon-3phase-demo.sh
```

### Interactive Walkthrough

The script will guide you through each phase:

```
╔═══════════════════════════════════════════════════════════════╗
║        Web Recon 2025 - 3-Phase Reconnaissance Script        ║
║              Command-Line Intelligence Workflow              ║
╚═══════════════════════════════════════════════════════════════╝

[INFO] Created working directory: recon_20260114_115700

========================================
PHASE 1: SURFACE MAXIMIZATION
========================================

Enter target domain [example.com]: target.com
Use custom DNS resolvers for dnsx? (y/n): n
[✓] Phase 1 parameters collected
```

---

## Phase Details

### Phase 1: Surface Maximization

**Objective**: Discover all subdomains, assets, and historical URLs

**Interactive Parameters**:
- Target domain (required)
- Custom DNS resolvers (optional)

**Tools Executed** (in parallel):
- `subfinder` - Passive subdomain enumeration from multiple sources
- `assetfinder` - Certificate transparency subdomain discovery
- `gau` - Historical URLs from Wayback Machine, Common Crawl, URLScan
- `waybackurls` - URLs from Internet Archive
- `dnsx` - DNS resolution and validation

**Output Files**:
```
results/
├── phase1_subfinder.txt          # Subdomains from subfinder
├── phase1_assetfinder.txt        # Subdomains from assetfinder
├── phase1_gau.txt                # URLs from gau
├── phase1_waybackurls.txt        # URLs from waybackurls
├── phase1_all_subdomains.txt     # Merged and deduplicated
└── phase1_resolved.txt           # Resolved DNS records (A records)
```

**Execution Flow**:
```
Start → subfinder ─┐
        assetfinder ├→ Merge → dnsx → End
        gau ────────┤
        waybackurls ┘
```

---

### Phase 2: Port & Service Fingerprinting

**Objective**: Identify open ports and active HTTP/HTTPS services

**Interactive Parameters**:
- Hosts file (auto-detected from Phase 1)
- Enable masscan (optional, requires root)
- Masscan rate (if enabled)

**Tools Executed** (in parallel):
- `naabu` - Fast port scanning with service detection
- `httpx` - HTTP/HTTPS probe with titles and status codes
- `httprobe` - Verify HTTP/HTTPS services
- `masscan` - Internet-scale port scanning (optional)

**Output Files**:
```
results/
├── phase2_naabu_ports.txt        # Open ports discovered
├── phase2_httpx.txt              # HTTP services with metadata
├── phase2_httprobe.txt           # Verified HTTP services
└── phase2_masscan.xml            # Masscan results (if enabled)
```

**Execution Flow**:
```
Start → naabu ─┐
        httpx ─┼→ End
        httprobe ┘
        masscan (optional)
```

---

### Phase 3: Parameter & Endpoint Mining

**Objective**: Discover endpoints, parameters, and vulnerabilities

**Interactive Parameters**:
- URLs file (auto-detected from Phase 2)
- Katana crawl depth (default: 2)
- Nuclei template directory (default: cves/)

**Tools Executed**:
- `katana` - Web crawler for endpoint discovery
- `gf` patterns (parallel):
  - `gf lfi` - Local File Inclusion endpoints
  - `gf sqli` - SQL Injection endpoints
  - `gf xss` - Cross-Site Scripting endpoints
  - `gf ssrf` - Server-Side Request Forgery endpoints
  - `gf rce` - Remote Code Execution endpoints
  - `gf upload` - File upload endpoints
- `nuclei` - Template-based vulnerability scanning

**Output Files**:
```
results/
├── phase3_katana_urls.txt        # Crawled URLs
├── phase3_gf_lfi.txt             # Potential LFI endpoints
├── phase3_gf_sqli.txt            # Potential SQLi endpoints
├── phase3_gf_xss.txt             # Potential XSS endpoints
├── phase3_gf_ssrf.txt            # Potential SSRF endpoints
├── phase3_gf_rce.txt             # Potential RCE endpoints
├── phase3_gf_upload.txt          # Potential file upload endpoints
└── phase3_nuclei_results.txt     # Vulnerability scan results
```

**Execution Flow**:
```
Start → katana → gf_lfi ─┐
                 gf_sqli ─┤
                 gf_xss ──┼→ nuclei → End
                 gf_ssrf ─┤
                 gf_rce ──┤
                 gf_upload┘
```

---

## HTML Report

### Features

The generated report includes:

**Header Section**:
- Report timestamp
- Target domain
- Working directory path

**Phase Sections** (one per phase):
- **Mermaid Flowchart**: Visual tool execution flow with status indicators
  - Green: Successful execution
  - Red: Failed execution
  - Blue: Pending/Unknown
- **Tool Cards**: Each tool shows:
  - Tool name
  - Executed command
  - Execution status
- **Result Files**: List of generated files with sizes

**Execution Summary**:
- Total tools executed
- Successful executions
- Failed executions
- Total result files generated

### Accessing the Report

```bash
# Open in default browser
open recon_20260114_115700/report.html

# Or with specific browser
firefox recon_20260114_115700/report.html
chromium recon_20260114_115700/report.html
```

### Mermaid Diagrams

Each phase includes an embedded Mermaid flowchart showing:
- Tool execution order
- Data flow between tools
- Status of each tool (color-coded)
- Start and end points

Example Phase 1 diagram:
```
Start → subfinder (success) → assetfinder (success) → gau (success) 
        → waybackurls (success) → dnsx (success) → End
```

---

## Directory Structure

```
recon_20260114_115700/
├── report.html                   # Main HTML report with Mermaid diagrams
├── results/                      # All tool outputs
│   ├── phase1_subfinder.txt
│   ├── phase1_assetfinder.txt
│   ├── phase1_gau.txt
│   ├── phase1_waybackurls.txt
│   ├── phase1_all_subdomains.txt
│   ├── phase1_resolved.txt
│   ├── phase2_naabu_ports.txt
│   ├── phase2_httpx.txt
│   ├── phase2_httprobe.txt
│   ├── phase3_katana_urls.txt
│   ├── phase3_gf_lfi.txt
│   ├── phase3_gf_sqli.txt
│   ├── phase3_gf_xss.txt
│   ├── phase3_gf_ssrf.txt
│   ├── phase3_gf_rce.txt
│   ├── phase3_gf_upload.txt
│   └── phase3_nuclei_results.txt
└── logs/                         # Execution logs
    ├── phase1.log
    ├── phase2.log
    └── phase3.log
```

---

## Parallel Execution

The framework optimizes speed through parallel execution:

### Phase 1
- **Parallel**: subfinder, assetfinder, gau, waybackurls
- **Sequential**: dnsx (waits for subdomain merge)
- **Benefit**: 4 tools run simultaneously

### Phase 2
- **Parallel**: naabu, httpx, httprobe
- **Optional**: masscan (separate, requires root)
- **Benefit**: 3 tools run simultaneously

### Phase 3
- **Sequential**: katana (must complete first)
- **Parallel**: gf patterns (6 patterns simultaneously)
- **Sequential**: nuclei (after katana completes)
- **Benefit**: 6 gf patterns run simultaneously

**Total Time Savings**: ~70% reduction vs sequential execution

---

## Advanced Usage

### Custom Configuration

Edit the script to set default parameters:

```bash
# In phase1_collect_params()
PHASE1_TARGET="your-domain.com"
PHASE1_SUBFINDER=true
PHASE1_ASSETFINDER=true
PHASE1_GAU=true
PHASE1_WAYBACKURLS=true
PHASE1_DNSX=true
```

### Skip Phases

Modify the main() function to skip phases:

```bash
# Comment out phases you don't need
# phase1_collect_params
# run_phase1

phase2_collect_params
run_phase2

phase3_collect_params
run_phase3
```

### Increase Verbosity

Remove `-silent` flags to see detailed output:

```bash
# In run_phase1()
subfinder -d "$PHASE1_TARGET" -o "${RESULTS_DIR}/phase1_subfinder.txt"
```

### Use Custom Resolvers

Create a resolvers file and provide path when prompted:

```bash
# resolvers.txt
8.8.8.8
1.1.1.1
9.9.9.9
```

---

## Troubleshooting

### Tools Not Found

Ensure PATH is set:
```bash
export PATH="$HOME/go/bin:$PATH"
source ~/.bashrc
```

### Permission Denied

Make scripts executable:
```bash
chmod +x recon-3phase.sh
chmod +x recon-3phase-demo.sh
```

### Masscan Requires Root

Run with sudo:
```bash
sudo ./recon-3phase.sh
```

Or skip masscan when prompted.

### Out of Memory

Reduce tool rates:
- Naabu: Reduce `-rate` parameter
- Masscan: Reduce `--rate` parameter
- Nuclei: Use specific template directory

### DNS Resolution Fails

Provide custom resolvers when prompted:
```
Use custom DNS resolvers for dnsx? (y/n): y
Path to resolvers file [/etc/resolv.conf]: /path/to/custom/resolvers.txt
```

### Report Not Generated

Check logs:
```bash
cat recon_20260114_115700/logs/phase*.log
```

---

## Integration Examples

### Export Results for Further Analysis

```bash
# Extract unique URLs
cat recon_*/results/phase3_katana_urls.txt | sort -u > all_urls.txt

# Extract vulnerable endpoints
cat recon_*/results/phase3_gf_*.txt | sort -u > vulnerable_endpoints.txt

# Extract open ports
cat recon_*/results/phase2_naabu_ports.txt | cut -d: -f2 | sort -u > open_ports.txt

# Extract resolved hosts
cat recon_*/results/phase1_resolved.txt | cut -d: -f1 | sort -u > hosts.txt
```

### Feed to Other Tools

```bash
# Use with Burp Suite
cat recon_*/results/phase3_katana_urls.txt | burpsuite-import

# Use with custom scanner
cat recon_*/results/phase2_httpx.txt | your-custom-scanner

# Use with nuclei directly
nuclei -l recon_*/results/phase2_httpx.txt -t custom-templates/
```

### Combine Multiple Runs

```bash
# Merge results from multiple reconnaissance runs
cat recon_*/results/phase1_resolved.txt | sort -u > merged_hosts.txt
cat recon_*/results/phase3_gf_*.txt | sort -u > merged_vulnerabilities.txt
```

---

## Performance Tips

### Optimize for Speed

1. Skip masscan (requires root, slower)
2. Reduce katana depth: Use depth 1 instead of 2
3. Use fewer gf patterns: Edit script to skip unnecessary patterns
4. Reduce nuclei templates: Use specific template directory

### Optimize for Accuracy

1. Enable custom DNS resolvers
2. Use masscan for comprehensive port scanning
3. Increase katana depth for thorough crawling
4. Run nuclei with full template set

### Optimize for Large Targets

1. Run phases separately to manage memory
2. Use rate limiting on all tools
3. Filter results between phases
4. Run on high-performance system

---

## Example Workflows

### Complete Reconnaissance

```bash
# 1. Run the 3-phase script
./recon-3phase-demo.sh

# 2. Review the HTML report
firefox recon_20260114_115700/report.html

# 3. Export results
cat recon_20260114_115700/results/phase3_gf_*.txt > vulnerabilities.txt

# 4. Analyze findings
grep -i "admin" vulnerabilities.txt
```

### Targeted Scanning

```bash
# 1. Run Phase 1 only
# (Modify script to skip phases 2 and 3)

# 2. Manually run Phase 2 with custom parameters
naabu -l phase1_resolved.txt -p 80,443,8080,8443

# 3. Run Phase 3 on specific hosts
katana -l https://target.com -d 3
```

### Continuous Monitoring

```bash
# Run reconnaissance daily
0 0 * * * /home/rjodouin/recon-3phase-demo.sh

# Compare results
diff <(cat recon_old/results/phase1_resolved.txt | sort) \
     <(cat recon_new/results/phase1_resolved.txt | sort)
```

---

## Script Versions

### recon-3phase.sh
- **Full-featured version**
- Advanced parallel execution
- Complex HTML generation
- Recommended for production use

### recon-3phase-demo.sh
- **Simplified version**
- More stable and easier to debug
- Cleaner code structure
- Recommended for testing and learning

---

## Notes

- All tools run with automation-friendly flags
- Results are deduplicated where applicable
- Logs are saved for debugging
- Report includes execution status for each tool
- Mermaid diagrams are embedded (no external dependencies)
- Scripts are idempotent (safe to run multiple times)
- Phase outputs automatically feed into next phase
- Parallel execution significantly reduces total time

---

## Support & Documentation

For issues with specific tools:
- **Subfinder**: https://github.com/projectdiscovery/subfinder
- **Nuclei**: https://github.com/projectdiscovery/nuclei
- **Katana**: https://github.com/projectdiscovery/katana
- **Naabu**: https://github.com/projectdiscovery/naabu
- **DNSX**: https://github.com/projectdiscovery/dnsx
- **GF**: https://github.com/tomnomnom/gf
- **Masscan**: https://github.com/robertdavidgraham/masscan

For script issues:
- Check logs in `recon_*/logs/`
- Verify tools are installed: `/home/rjodouin/verify_recon_tools.sh`
- Review HTML report for execution status
- Check Mermaid diagrams for tool flow

---

## License & Attribution

Web Recon 2025 Framework - Automated Reconnaissance Workflow
Built with ProjectDiscovery tools and community tools
