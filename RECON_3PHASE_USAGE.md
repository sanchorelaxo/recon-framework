# Web Recon 2025 - 3-Phase Reconnaissance Script

## Overview

The `recon-3phase.sh` script automates the complete Web Recon 2025 workflow with three phases:

1. **Phase 1: Surface Maximization** - Subdomain and asset discovery
2. **Phase 2: Port & Service Fingerprinting** - Port scanning and service detection
3. **Phase 3: Parameter & Endpoint Mining** - URL crawling and vulnerability scanning

The script features:
- Interactive parameter collection for each phase
- Parallel tool execution for performance
- Comprehensive HTML report with Mermaid diagrams
- Detailed logging and result tracking

---

## Quick Start

### Basic Usage

```bash
export PATH="$HOME/go/bin:$PATH"
./recon-3phase.sh
```

The script will guide you through each phase interactively.

### Example Session

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

## Phase 1: Surface Maximization

### Parameters Collected

- **Target Domain**: The domain to enumerate (e.g., `example.com`)
- **Custom Resolvers**: Optional custom DNS resolver file for dnsx

### Tools Used

| Tool | Purpose |
|------|---------|
| **subfinder** | Passive subdomain enumeration |
| **assetfinder** | Certificate transparency subdomain discovery |
| **gau** | Historical URLs from Wayback Machine, Common Crawl, URLScan |
| **waybackurls** | URLs from Internet Archive |
| **dnsx** | DNS resolution and validation |

### Output Files

```
results/
├── phase1_subfinder.txt          # Subdomains from subfinder
├── phase1_assetfinder.txt        # Subdomains from assetfinder
├── phase1_gau.txt                # URLs from gau
├── phase1_waybackurls.txt        # URLs from waybackurls
├── phase1_all_subdomains.txt     # Merged subdomains
└── phase1_resolved.txt           # Resolved subdomains (A records)
```

### Example Commands

```bash
# Discover subdomains
subfinder -d target.com -silent

# Get historical URLs
gau --subs target.com
waybackurls target.com

# Resolve discovered subdomains
dnsx -l subdomains.txt -silent
```

---

## Phase 2: Port & Service Fingerprinting

### Parameters Collected

- **Hosts File**: Path to resolved hosts from Phase 1 (auto-detected)
- **Masscan Rate**: Packets per second for masscan (if enabled)
- **Enable Masscan**: Optional (requires root)

### Tools Used

| Tool | Purpose |
|------|---------|
| **naabu** | Fast port scanning with service detection |
| **httpx** | HTTP/HTTPS probe with title and status codes |
| **httprobe** | Verify HTTP/HTTPS services |
| **masscan** | Internet-scale port scanning (optional, requires root) |

### Output Files

```
results/
├── phase2_naabu_ports.txt        # Open ports discovered
├── phase2_httpx.txt              # HTTP services with titles
├── phase2_httprobe.txt           # Verified HTTP services
└── phase2_masscan.xml            # Masscan results (if enabled)
```

### Example Commands

```bash
# Fast port scanning
naabu -l hosts.txt -p - -silent

# Probe for HTTP services
httpx -l hosts.txt -silent -title -status-code

# Verify with httprobe
cat hosts.txt | httprobe -c 50
```

---

## Phase 3: Parameter & Endpoint Mining

### Parameters Collected

- **URLs File**: Path to HTTP services from Phase 2 (auto-detected)
- **Katana Depth**: Web crawl depth (default: 2)
- **Nuclei Templates**: Template directory for vulnerability scanning (default: cves/)

### Tools Used

| Tool | Purpose |
|------|---------|
| **katana** | Web crawler for endpoint discovery |
| **gf** | Pattern matching for vulnerabilities (LFI, SQLi, XSS, SSRF, RCE, Upload) |
| **nuclei** | Template-based vulnerability scanning |

### Output Files

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

### Example Commands

```bash
# Crawl for URLs
katana -u https://target.com -d 2 -silent

# Find vulnerable patterns
gf lfi urls.txt
gf sqli urls.txt
gf xss urls.txt

# Scan for vulnerabilities
nuclei -l urls.txt -t cves/ -silent
```

---

## HTML Report

### Features

The generated HTML report includes:

- **Metadata**: Report timestamp, target domain, working directory
- **Phase Sections**: One section per phase with:
  - Mermaid flowchart showing tool execution flow
  - Tool cards with executed commands and status
  - Result files with sizes
- **Execution Summary**: Total tools, success/failure counts
- **Dark Theme**: Professional dark UI with cyan accents

### Mermaid Diagrams

Each phase includes a flowchart showing:
- Tool execution order
- Success/failure status (color-coded)
- Data flow between tools

Example diagram:
```
Start → subfinder → assetfinder → gau → waybackurls → dnsx → End
```

### Accessing the Report

```bash
# Open in default browser
open recon_20260114_115700/report.html

# Or with specific browser
firefox recon_20260114_115700/report.html
```

---

## Directory Structure

```
recon_20260114_115700/
├── report.html                   # HTML report with diagrams
├── results/                      # All tool outputs
│   ├── phase1_*.txt
│   ├── phase2_*.txt
│   └── phase3_*.txt
└── logs/                         # Execution logs
    ├── phase1.log
    ├── phase2.log
    └── phase3.log
```

---

## Parallel Execution

The script runs tools in parallel where possible:

### Phase 1
- subfinder, assetfinder, gau, waybackurls run in parallel
- dnsx runs after subdomain discovery completes

### Phase 2
- naabu, httpx, httprobe run in parallel
- masscan runs separately (if enabled)

### Phase 3
- katana runs first
- gf patterns (lfi, sqli, xss, ssrf, rce, upload) run in parallel
- nuclei runs after katana completes

This approach significantly reduces total execution time.

---

## Advanced Usage

### Skip Phases

To run only specific phases, modify the script or use:

```bash
# Run only Phase 1
sed -n '/run_phase1/,/log_success "Phase 1/p' recon-3phase.sh
```

### Custom Parameters

Edit the script to set default parameters:

```bash
# In phase1_collect_params()
PHASE1_TARGET="your-domain.com"
PHASE1_SUBFINDER=true
PHASE1_ASSETFINDER=true
```

### Increase Verbosity

Remove `-silent` flags from tool commands to see detailed output:

```bash
# In run_phase1()
subfinder -d "$PHASE1_TARGET" -o "${RESULTS_DIR}/phase1_subfinder.txt"
```

---

## Troubleshooting

### Tools Not Found

Ensure PATH is set:
```bash
export PATH="$HOME/go/bin:$PATH"
```

### Permission Denied

Make script executable:
```bash
chmod +x recon-3phase.sh
```

### Masscan Requires Root

Run with sudo or skip masscan:
```bash
sudo ./recon-3phase.sh
```

### Out of Memory

Reduce rate limiting or skip intensive tools:
- Reduce naabu rate: `-rate 1000`
- Skip masscan: Answer 'n' when prompted

### DNS Resolution Fails

Provide custom resolvers:
```bash
# When prompted, answer 'y' and provide resolvers file
# File should contain one resolver per line (e.g., 8.8.8.8)
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

---

## Integration with Other Tools

### Export Results

```bash
# Extract unique URLs
cat recon_*/results/phase3_katana_urls.txt | sort -u > all_urls.txt

# Extract vulnerable endpoints
cat recon_*/results/phase3_gf_*.txt | sort -u > vulnerable_endpoints.txt

# Extract open ports
cat recon_*/results/phase2_naabu_ports.txt | cut -d: -f2 | sort -u > open_ports.txt
```

### Feed to Other Tools

```bash
# Use results with other security tools
cat recon_*/results/phase3_katana_urls.txt | burpsuite-import

# Scan with custom tools
cat recon_*/results/phase2_httpx.txt | your-custom-scanner
```

---

## Example Workflow

### Complete Reconnaissance

```bash
# 1. Run the 3-phase script
./recon-3phase.sh

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
katana -u https://target.com -d 3
```

---

## Notes

- All tools run with appropriate flags for automation
- Results are deduplicated where applicable
- Logs are saved for debugging
- Report includes execution status for each tool
- Mermaid diagrams are embedded (no external dependencies)
- Script is idempotent (safe to run multiple times)

---

## Support

For issues with specific tools, refer to their documentation:
- Subfinder: https://github.com/projectdiscovery/subfinder
- Nuclei: https://github.com/projectdiscovery/nuclei
- Katana: https://github.com/projectdiscovery/katana
- Naabu: https://github.com/projectdiscovery/naabu
