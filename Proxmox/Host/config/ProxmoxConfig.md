# 🖥️ Add Domain and SSL

## Step 1: Create a Cloudflare API Token

- Go to Cloudflare Dashboard → Profile → API Tokens
- Click "Create Token"
- Select "Use template" → Edit zone DNS
- Under Permissions, make sure it says:
- Zone → DNS → Edit
- Under Zone Resources, choose:
- Include → Specific Zone → domain
- Click Continue to summary, then Create Token
- Copy the token. Keep it safe.

## Step 2: Add ACME Account in Proxmox UI

- Login with Host root or equivalent user for ACME to be visible
- Go to Datacenter → ACME → Accounts Tab
- Click "Add"
- Use Let’s Encrypt as the CA
- Email can be anything
- Click Register Account

## Step 3: Add Cloudflare DNS Plugin in Proxmox

- Still under Datacenter → ACME, go to Challenge Plugins tab
- Click Add
  - Plugin ID: cloudflare
  - Validation Delay: 30
  - DNS API: Cloudflare Managed DNS
  - CF_Email: Cloudflare account Email
  - CF_Token: Same token stored in /root/.secrets/cloudflare.ini
  - Click Add

## Step 4: Request the Certificate

- Go to Datacenter → Node → System → Certificates → ACME Tab
- Click Add
- Challenge Type: DNS
- Plugin:  Challenge created in Step 3
- Domain: Domain configured for Proxmox IP on Cloudflare
- Click Create
- Using Account(Same line as Add button): Account created in Step 2
- Click Oder Certificates Now

## Datacenter Firewall Rules

Add the following rules to allow necessary traffic:

- Action: ACCEPT
  Direction: IN
  Protocol: TCP
  Destination Port: 8006
- Action: ACCEPT
  Direction: IN
  Protocol: TCP
  Destination Port: 443
- Action: ACCEPT
  Direction: IN
  Protocol: TCP
  Destination Port: 123
- Action: ACCEPT
  Direction: IN
  Protocol: ICMP
- Action: ACCEPT
  Direction: IN
  Protocol: IPv6-ICMP
