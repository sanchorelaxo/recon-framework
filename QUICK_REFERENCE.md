# Web Recon Tools - Quick Reference Guide

## Essential Setup

Ensure PATH is set in your current session:
```bash
export PATH="$HOME/go/bin:$PATH"
```

Or verify tools are accessible:
```bash
/home/rjodouin/verify_recon_tools.sh
```

---

## One-Liner Commands

### Subdomain Discovery
```bash
subfinder -d example.com -silent | dnsx -silent | httprobe -c 50
```

### Get Historical URLs
```bash
waybackurls example.com | sort -u > urls.txt
gau example.com >> urls.txt
```

### Find Parameters
```bash
cat urls.txt | gf lfi
cat urls.txt | gf sqli
cat urls.txt | gf xss
```

### Port Scanning
```bash
naabu -host example.com -p - -silent | httpx -silent
```

### Web Crawling
```bash
katana -u https://example.com -d 3 -silent
```

### Vulnerability Scanning
```bash
nuclei -u https://example.com -t cves/ -silent
```

---

## Common Workflows

### Complete Reconnaissance
```bash
# 1. Discover subdomains
subfinder -d example.com -o subs.txt

# 2. Resolve and probe
dnsx -l subs.txt -silent | httprobe -c 50 > live-hosts.txt

# 3. Crawl for URLs
katana -l live-hosts.txt -d 2 -o urls.txt

# 4. Extract parameters
gf lfi urls.txt > lfi-params.txt
gf sqli urls.txt > sqli-params.txt

# 5. Scan for vulnerabilities
nuclei -l live-hosts.txt -t cves/ -o results.txt
```

### Parameter Fuzzing
```bash
cat urls.txt | qsreplace "FUZZ" > fuzz-urls.txt
# Use with your favorite fuzzer
```

### Asset Discovery
```bash
assetfinder --subs-only example.com | anew subdomains.txt
```

### Historical Analysis
```bash
waybackurls example.com | gf lfi
waybackurls example.com | gf sqli
```

---

## Tool Combinations

### Find Exposed Files
```bash
gau example.com | gf aws-keys
gau example.com | gf slack-tokens
gau example.com | gf github-tokens
```

### Parameter Analysis
```bash
katana -u https://example.com -d 3 | gf xss | qsreplace "alert(1)"
```

### DNS Enumeration
```bash
subfinder -d example.com | dnsx -a -aaaa -cname -mx -ns -soa
```

### Service Discovery
```bash
naabu -host example.com -p 80,443,8080,8443 | httpx -title -status-code
```

---

## Useful Patterns with GF

```bash
gf lfi          # Local File Inclusion
gf sqli         # SQL Injection
gf xss          # Cross-Site Scripting
gf ssrf         # Server-Side Request Forgery
gf rce          # Remote Code Execution
gf upload       # File Upload
gf aws-keys     # AWS Keys
gf slack-tokens # Slack Tokens
gf github-tokens # GitHub Tokens
```

---

## Output Formatting

### JSON Processing with JQ
```bash
# Extract URLs from JSON
cat results.json | jq '.[] | .url'

# Filter by status code
cat results.json | jq '.[] | select(.status_code == 200)'

# Count occurrences
cat results.json | jq 'length'
```

### Deduplication with Anew
```bash
cat new-urls.txt | anew all-urls.txt
# Only adds new lines to all-urls.txt
```

### Fast Searching with Ripgrep
```bash
rg "admin" urls.txt
rg "api" urls.txt
rg "\.php" urls.txt
```

---

## Performance Tips

### Parallel Processing
```bash
# Use xargs for parallel execution
cat hosts.txt | xargs -I {} -P 10 nuclei -u {} -t cves/
```

### Rate Limiting
```bash
# Most tools support rate limiting
dnsx -l domains.txt -rate 1000
naabu -host example.com -rate 5000
```

### Output Filtering
```bash
# Filter by status code
httpx -l hosts.txt -status-code 200,301,302

# Filter by title
httpx -l hosts.txt -title "Admin"
```

---

## Nuclei Template Usage

### Scan with Specific Templates
```bash
nuclei -u https://example.com -t cves/
nuclei -u https://example.com -t exposures/
nuclei -u https://example.com -t vulnerabilities/
```

### Update Templates
```bash
nuclei -update-templates
```

### Custom Template Scanning
```bash
nuclei -u https://example.com -t /path/to/custom/template.yaml
```

---

## Troubleshooting

### Tools Not in PATH
```bash
export PATH="$HOME/go/bin:$PATH"
source ~/.bashrc
```

### Permission Issues
```bash
# Some tools need root
sudo masscan -p0-65535 192.168.1.0/24
sudo zmap -p 443
```

### DNS Resolution Issues
```bash
# Use custom resolvers with dnsx
dnsx -l domains.txt -r resolvers.txt
```

### Memory Issues
```bash
# Reduce rate for large scans
naabu -host example.com -rate 1000 -p -
```

---

## Useful Aliases

Add to `~/.bashrc`:
```bash
alias recon='export PATH="$HOME/go/bin:$PATH"'
alias verify-tools='/home/rjodouin/verify_recon_tools.sh'
alias subs='subfinder -d'
alias resolve='dnsx -l'
alias crawl='katana -u'
alias scan='nuclei -u'
```

Then reload:
```bash
source ~/.bashrc
```

---

## File Organization

Recommended directory structure:
```
recon/
├── targets.txt
├── subdomains/
│   ├── all-subs.txt
│   └── live-subs.txt
├── urls/
│   ├── all-urls.txt
│   ├── lfi-urls.txt
│   └── sqli-urls.txt
├── ports/
│   └── open-ports.txt
├── screenshots/
└── results/
    ├── nuclei-results.txt
    └── vulnerabilities.txt
```

---

## Documentation Links

- **Subfinder**: https://github.com/projectdiscovery/subfinder
- **Nuclei**: https://github.com/projectdiscovery/nuclei
- **Katana**: https://github.com/projectdiscovery/katana
- **Naabu**: https://github.com/projectdiscovery/naabu
- **DNSX**: https://github.com/projectdiscovery/dnsx
- **GF**: https://github.com/tomnomnom/gf
- **Masscan**: https://github.com/robertdavidgraham/masscan
- **Zmap**: https://github.com/zmap/zmap

---

## Notes

- All tools are installed and verified ✓
- PATH is configured in ~/.bashrc and ~/.profile
- Tools are ready for immediate use
- Run `verify_recon_tools.sh` to check status anytime
- See `RECON_TOOLS_SETUP.md` for detailed documentation
