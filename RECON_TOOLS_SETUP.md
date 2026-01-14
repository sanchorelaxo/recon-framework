# Web Reconnaissance Tools Setup Guide

## Installation Complete ✓

All tools have been installed on your system for long-term use. This guide documents the setup and provides usage examples.

### System Information
- **OS**: Pop!_OS 24.04
- **Go Version**: 1.22
- **Installation Date**: Jan 14, 2026

---

## Phase 1: Surface Maximization (Subdomain & Asset Discovery)

### Installed Tools

#### 1. **subfinder** - Subdomain Discovery
- **Location**: `~/.local/bin/subfinder` or `~/go/bin/subfinder`
- **Usage**: `subfinder -d example.com`
- **Features**: Passive subdomain enumeration from multiple sources
- **Version**: v2.12.0

#### 2. **assetfinder** - Asset Discovery
- **Location**: `~/go/bin/assetfinder`
- **Usage**: `assetfinder --subs-only example.com`
- **Features**: Find subdomains and assets from certificate transparency
- **Version**: Latest

#### 3. **anew** - Deduplication Tool
- **Location**: `~/go/bin/anew`
- **Usage**: `cat subdomains.txt | anew`
- **Features**: Add only new lines to a file
- **Version**: Latest

#### 4. **dnsx** - DNS Resolver
- **Location**: `~/go/bin/dnsx`
- **Usage**: `dnsx -l subdomains.txt -o resolved.txt`
- **Features**: Fast DNS resolution with multiple query types
- **Version**: Latest

#### 5. **gau** - Get All URLs
- **Location**: `~/go/bin/gau`
- **Usage**: `gau example.com`
- **Features**: Fetch URLs from Wayback Machine, Common Crawl, URLScan
- **Version**: Latest

#### 6. **waybackurls** - Wayback Machine URLs
- **Location**: `~/go/bin/waybackurls`
- **Usage**: `echo example.com | waybackurls`
- **Features**: Retrieve URLs from Internet Archive
- **Version**: Latest

#### 7. **jq** - JSON Query Tool
- **Location**: `/usr/bin/jq`
- **Usage**: `cat data.json | jq '.[] | .url'`
- **Features**: Parse and manipulate JSON data
- **Version**: 1.7.1

#### 8. **ripgrep** - Fast Grep
- **Location**: `/usr/bin/rg`
- **Usage**: `rg "pattern" directory/`
- **Features**: Fast recursive search
- **Version**: 14.1.0

---

## Phase 2: Port & Service Fingerprinting

### Installed Tools

#### 1. **masscan** - Fast Port Scanner
- **Location**: `/usr/bin/masscan`
- **Usage**: `sudo masscan -p0-65535 --rate=1000 192.168.1.0/24`
- **Features**: Internet-scale port scanner (requires root)
- **Version**: 1.3.2

#### 2. **naabu** - Port Discovery
- **Location**: `~/go/bin/naabu`
- **Usage**: `naabu -host example.com -p - -o ports.txt`
- **Features**: Fast port scanning with service detection
- **Version**: 2.3.7

#### 3. **massdns** - Bulk DNS Resolver
- **Location**: `/usr/local/bin/massdns`
- **Usage**: `massdns -r resolvers.txt -t A domains.txt`
- **Features**: High-performance DNS resolution
- **Version**: 1.1.0

#### 4. **zmap** - Network Scanner
- **Location**: `/usr/bin/zmap`
- **Usage**: `sudo zmap -p 443 -o results.csv`
- **Features**: Fast network-wide scanning
- **Version**: 2.1.1

#### 5. **httpx** - HTTP Probe
- **Location**: `~/.local/bin/httpx`
- **Usage**: `httpx -l hosts.txt -o http-hosts.txt`
- **Features**: Probe for HTTP/HTTPS services
- **Version**: Latest (Python-based)

#### 6. **httprobe** - HTTP Status Checker
- **Location**: `~/go/bin/httprobe`
- **Usage**: `cat hosts.txt | httprobe`
- **Features**: Probe hosts for HTTP/HTTPS
- **Version**: Latest

---

## Phase 3: Parameter & Endpoint Mining

### Installed Tools

#### 1. **katana** - Web Crawler
- **Location**: `~/go/bin/katana`
- **Usage**: `katana -u https://example.com -o urls.txt`
- **Features**: Fast web crawler for endpoint discovery
- **Version**: Latest

#### 2. **hakrawler** - Web Crawler
- **Location**: `~/go/bin/hakrawler`
- **Usage**: `echo https://example.com | hakrawler -d 2`
- **Features**: Simple web crawler for URL extraction
- **Note**: Installation may require retry due to network timeouts

#### 3. **gf** - Grep Patterns
- **Location**: `~/go/bin/gf`
- **Usage**: `gf lfi urls.txt`
- **Features**: Grep for patterns in URLs (LFI, SQLi, XSS, etc.)
- **Version**: Latest

#### 4. **qsreplace** - Query String Replacer
- **Location**: `~/go/bin/qsreplace`
- **Usage**: `cat urls.txt | qsreplace "PAYLOAD"`
- **Features**: Replace query string values with payloads
- **Version**: Latest

#### 5. **nuclei** - Vulnerability Scanner
- **Location**: `~/go/bin/nuclei`
- **Usage**: `nuclei -u https://example.com -t cves/`
- **Features**: Template-based vulnerability scanning
- **Version**: 3.6.2

---

## PATH Configuration

The Go binaries are installed in `~/go/bin/`. This has been added to your PATH in:
- `~/.bashrc`
- `~/.profile`

To use these tools immediately in a new terminal, run:
```bash
export PATH="$HOME/go/bin:$PATH"
```

Or reload your shell:
```bash
source ~/.bashrc
```

---

## Quick Start Examples

### Basic Reconnaissance Workflow

```bash
# 1. Discover subdomains
subfinder -d example.com -o subdomains.txt

# 2. Resolve DNS
dnsx -l subdomains.txt -o resolved.txt

# 3. Probe for HTTP services
cat resolved.txt | httprobe -o http-hosts.txt

# 4. Crawl for URLs
katana -l http-hosts.txt -o urls.txt

# 5. Find interesting parameters
gf lfi urls.txt > lfi-urls.txt
gf sqli urls.txt > sqli-urls.txt

# 6. Scan for vulnerabilities
nuclei -l http-hosts.txt -t cves/ -o results.txt
```

### Port Scanning Workflow

```bash
# 1. Fast port scan with naabu
naabu -host example.com -p - -o ports.txt

# 2. Probe discovered ports
cat ports.txt | httpx -o web-services.txt

# 3. Scan with nuclei
nuclei -l web-services.txt -t cves/
```

---

## Tool Categories

### Discovery Tools
- subfinder, assetfinder, gau, waybackurls, dnsx

### Scanning Tools
- masscan, naabu, massdns, zmap, httpx, httprobe

### Crawling Tools
- katana, hakrawler

### Analysis Tools
- gf, qsreplace, jq, ripgrep, nuclei

### Utility Tools
- anew (deduplication)

---

## Configuration Files

Some tools use configuration files:

- **subfinder**: `~/.config/subfinder/config.yaml`
- **nuclei**: `~/.config/nuclei/config.yaml`
- **katana**: `~/.config/katana/config.yaml`

---

## Updating Tools

All Go-based tools can be updated with:
```bash
go install github.com/projectdiscovery/[tool]/cmd/[tool]@latest
```

For system packages:
```bash
sudo apt update && sudo apt upgrade
```

---

## Troubleshooting

### Tools Not Found in PATH
If tools aren't found, ensure `~/go/bin` is in your PATH:
```bash
echo $PATH | grep go/bin
```

If not, add to `~/.bashrc`:
```bash
export PATH="$HOME/go/bin:$PATH"
```

### Permission Denied
Some tools (masscan, zmap) require root:
```bash
sudo masscan -p0-65535 192.168.1.0/24
```

### Network Timeouts
If installations timeout, retry:
```bash
go install -v github.com/[repo]/[tool]@latest
```

---

## Additional Resources

- ProjectDiscovery Tools: https://github.com/projectdiscovery
- Tom Nomnom Tools: https://github.com/tomnomnom
- Nuclei Templates: https://github.com/projectdiscovery/nuclei-templates

---

## Installed Versions Summary

| Tool | Type | Location | Version |
|------|------|----------|---------|
| subfinder | Go | ~/go/bin | v2.12.0 |
| assetfinder | Go | ~/go/bin | Latest |
| anew | Go | ~/go/bin | Latest |
| dnsx | Go | ~/go/bin | Latest |
| gau | Go | ~/go/bin | Latest |
| waybackurls | Go | ~/go/bin | Latest |
| katana | Go | ~/go/bin | Latest |
| httprobe | Go | ~/go/bin | Latest |
| gf | Go | ~/go/bin | Latest |
| qsreplace | Go | ~/go/bin | Latest |
| nuclei | Go | ~/go/bin | v3.6.2 |
| naabu | Go | ~/go/bin | v2.3.7 |
| httpx | Python | ~/.local/bin | Latest |
| masscan | C | /usr/bin | 1.3.2 |
| massdns | C | /usr/local/bin | 1.1.0 |
| zmap | C | /usr/bin | 2.1.1 |
| jq | System | /usr/bin | 1.7.1 |
| ripgrep | System | /usr/bin | 14.1.0 |

---

## Notes

- All tools are configured for long-term use
- PATH has been permanently updated in shell configuration files
- Tools are ready to use in new terminal sessions
- Some tools require root privileges for certain operations
- Regular updates recommended for security patches
