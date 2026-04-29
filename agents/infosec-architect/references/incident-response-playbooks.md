# Incident Response Playbooks Reference

> Reference file for the BMAD InfoSec Architect agent.
> Read this file when designing incident response plans, creating playbooks, and establishing IR team structures.

---

## Incident Response Lifecycle

```
PREPARATION
├─ Build IR team, tools, playbooks
└─ Train + drill quarterly

    ↓

DETECTION & ANALYSIS
├─ Alert triggered (monitoring, customer, threat intel)
├─ Triage: Is this a real incident?
└─ Initial severity classification (P1–P4)

    ↓

CONTAINMENT
├─ Short-term: Stop the bleeding (block attacker)
├─ Long-term: Prevent recurrence
└─ Goal: Limit blast radius

    ↓

ERADICATION
├─ Remove attacker from all systems
├─ Patch/remediate root cause
└─ Verify attacker is fully removed

    ↓

RECOVERY
├─ Restore systems from clean backup
├─ Monitor for recurrence
└─ Return to normal operations

    ↓

POST-INCIDENT REVIEW
├─ Timeline: What happened, when?
├─ Root cause: Why did this happen?
├─ Contributing factors: What made impact worse?
├─ Lessons learned: What do we do differently?
└─ Action items: Owner + deadline

    ↓

PREPARATION (cycle repeats)
```

---

## Severity Classification

| Severity | Definition | Examples | Response Time |
|----------|-----------|----------|----------------|
| **P1** CRITICAL | Active breach, data exfiltration, critical system down | Ransomware encrypting DB, customer data being stolen | Immediate (0 min) |
| **P2** HIGH | Significant impact, contained incident, no data loss yet | Attacker inside network but contained, major system degraded | 1 hour |
| **P3** MEDIUM | Limited impact, isolated, minor data exposure | Single user's account compromised, false positive | 4 hours |
| **P4** LOW | False alarm, no impact | Suspicious log entry, benign policy violation | 24 hours |

**Criteria for Escalation**:
- Confirmed unauthorized access
- Data exfiltration detected
- Multiple systems affected
- Critical business system impacted

---

## Communication Tree

### P1 (Critical Escalation)

```
Detection
  ├─ Alert fires (monitoring system)
  └─ Analyst validates (is this real?)
  
Escalation
  ├─ Notify on-call security lead (phone call)
  ├─ Notify VP Engineering (email + chat)
  └─ Notify CISO (email + chat)

Activation
  ├─ Activate IR war room (Slack #incident-response-p1)
  ├─ Notify affected teams (Backend, DevOps, Product)
  └─ Notify communications team (prepare external statement)

External Communication
  ├─ Legal: Breach notification requirements
  ├─ PR: Media management (if public)
  ├─ Customers: Notification of affected customers (if applicable)
  └─ Regulators: GDPR 72-hour notification, PCI breach reporting
```

### P2 (High Escalation)

```
Validation
  └─ On-call analyst confirms incident type

Escalation
  ├─ Notify VP Engineering (email)
  └─ Notify security team lead (chat)

Team Assembly
  ├─ Activate IR core team (analysts, engineers, DevOps)
  └─ Open Slack thread for coordination
```

### P3/P4 (Routine)

```
Analyst
  ├─ Investigate
  ├─ Remediate or close
  └─ Document in JIRA
```

---

## Data Breach Playbook

**Scenario**: Attacker exfiltrates customer personal information

### Phase 1: Detection & Triage (0–30 min)

**Initial Actions**:
- [ ] Confirm exfiltration actually occurred
  - Query DLP tool (Data Loss Prevention) — was data actually sent out?
  - Check firewall logs — egress traffic to external IPs?
  - Check user activity logs — did user intentionally upload?
- [ ] Scope assessment
  - How much data? (100 records vs 10 million)
  - What type? (names + emails vs SSNs + passwords)
  - Which customers? (1 customer vs all)
- [ ] Severity classification → P1

**Initial Containment**:
- [ ] Revoke compromised user credentials
- [ ] Block external IP addresses
- [ ] Disable API keys (if API abuse)
- [ ] Revoke session tokens

### Phase 2: Full Investigation (30 min – 4 hours)

**Determine Blast Radius**:
```sql
-- Query: Which data left the network?
SELECT user_id, data_type, size_mb, destination_ip, timestamp
FROM dataloss_events
WHERE timestamp > '2026-04-11 09:00'
ORDER BY timestamp DESC;

-- Query: Which customers affected?
SELECT DISTINCT customer_id, count(*) as record_count
FROM exfiltrated_data
GROUP BY customer_id;
```

**Root Cause**:
- [ ] How did attacker gain access?
  - Compromised credential?
  - Unpatched vulnerability?
  - Insider threat?
  - Misconfigured access control?
- [ ] Timeline: When did access occur?
  - First suspicious activity?
  - When did exfiltration start?
  - How long had access?

**Eradication**:
- [ ] Patch vulnerabilities (if exploited)
- [ ] Rotate all potentially compromised credentials
- [ ] Audit all access (who else has access?)
- [ ] Verify attacker cannot re-enter (different password, GEOBLOCK)

### Phase 3: Notification (Parallel to Investigation)

**GDPR Timeline**: 72 hours from discovery to notification

**Notification Content**:
```
We discovered that your personal information may have been 
accessed by an unauthorized party.

Data exposed:
- Name, email address, phone number
- Payment method (masked): ***-***-***-1234
- NOT exposed: Password, security questions

What we're doing:
- We've secured the breach and verified it's contained
- We're offering 12 months of free credit monitoring
- Your password has been reset (check email for new login link)

What you should do:
- Change your password immediately
- Monitor your credit report (link provided)
- Do NOT click suspicious links or reply to unexpected emails

Questions? Contact: security@example.com or 1-800-SECURITY
```

**Regulatory Notification**:
- [ ] GDPR: EU regulators (France, Germany)
- [ ] State Laws: California (CCPA), NY, Texas, etc.
- [ ] Industry: HIPAA breach notification (health data)

---

## Ransomware Playbook

**Scenario**: Attacker encrypts database and demands payment

### Phase 1: Detection (Immediate)

**Indicators**:
- [ ] Users report inability to access files/systems
- [ ] File extensions changed (`.exe` → `.encrypted`)
- [ ] Ransom note appears on screen
- [ ] Unusual CPU/disk activity (encryption process)

**Immediate Actions**:
```
DO:
- [ ] Isolate affected systems (disconnect network, don't power off)
- [ ] Document everything (screenshots, ransom note, timestamps)
- [ ] Preserve forensics (disk, memory snapshots)
- [ ] Notify IR team (P1 activation)

DO NOT:
- [ ] Pay ransom (FBI recommends against)
- [ ] Restore from backup yet (verify attacker gone first)
- [ ] Delete ransom note (evidence)
- [ ] Attempt to decrypt (wrong key, time wasted)
```

### Phase 2: Containment (1–4 hours)

**Assess Scope**:
- [ ] How many systems encrypted?
- [ ] Is backup affected? (Can we still recover?)
- [ ] Is ongoing encryption happening (attacker still present)?

**Isolation**:
- [ ] Unplug compromised servers from network
- [ ] Disable admin access (attacker might have credentials)
- [ ] Block known malware IPs at firewall
- [ ] Shut down services (prevent encryption spread)

**Backup Verification**:
```
Critical check: Is backup clean and restorable?
- [ ] Verify backup is immutable (attacker cannot delete)
- [ ] Test restore from backup (known-good snapshot)
- [ ] Confirm backup not encrypted (if connected, backup could be affected)
- [ ] Identify earliest clean backup point
```

### Phase 3: Eradication (Hours – Days)

**Root Cause**:
- [ ] How did attacker get in?
  - RDP exposed to internet (weak password)?
  - Phishing email (malicious attachment)?
  - VPN vulnerability (outdated Citrix)?
  - Supply chain attack?
- [ ] What's the persistence mechanism?
  - Backdoor account created?
  - Scheduled task?
  - Registry modification?

**Cleanup**:
- [ ] Remove malware from all systems
- [ ] Patch vulnerability that allowed entry
- [ ] Audit all user accounts (remove unauthorized)
- [ ] Disable RDP (if that was attack vector)

### Phase 4: Recovery (Days – Weeks)

**Rebuild Systems**:
1. Obtain clean OS media (from reputable source, verify integrity)
2. Fresh OS install (not restore from backup that might contain malware)
3. Patch to current version
4. Restore data from clean backup
5. Verify: System functions normally + no infection

**Monitoring**:
- [ ] Monitor systems for 1 week post-recovery
- [ ] Watch for re-infection attempts
- [ ] Verify no new backdoors created

---

## Credential Compromise Playbook

**Scenario**: Attacker's stolen credentials found in breach dump

### Immediate Actions (0–1 hour)

- [ ] Verify credentials work (are they actually valid?)
  - Test login → if fails, false alarm
- [ ] Determine credential type
  - SSH key for production server?
  - AWS access keys?
  - GitHub personal access token?
  - Database credentials?
- [ ] Revoke immediately
  ```bash
  # SSH: Remove public key
  sed -i '/key-to-revoke/d' ~/.ssh/authorized_keys
  
  # AWS: Deactivate access keys
  aws iam update-access-key --access-key-id AKIAIOSFODNN7EXAMPLE --status Inactive
  
  # GitHub: Revoke personal access token
  # (via GitHub UI: Settings → Developer Settings → Personal access tokens)
  ```

### Investigation (1–4 hours)

**Access Timeline**:
- [ ] When were credentials created?
- [ ] When was last legitimate use?
- [ ] Any suspicious activity after legitimate use?
- [ ] Who else has access to this credential? (shared? stored in code?)

**Check for Misuse**:
```bash
# SSH: Check auth log for unauthorized logins
grep "Accepted\|Failed" /var/log/auth.log | grep -v username

# AWS: Check CloudTrail
aws cloudtrail lookup-events --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=AKIAIOSFODNN7EXAMPLE

# Database: Check audit logs
SELECT * FROM audit_log WHERE user = 'db_user' AND timestamp > '2 days ago'
```

**Actions if Misused**:
- [ ] P1: Attacker accessed production systems (compromised data?)
- [ ] Check for lateral movement (did attacker jump to other systems?)
- [ ] Restore from backup if necessary

---

## DDoS Attack Playbook

**Scenario**: Application becomes unreachable due to DDoS

### Phase 1: Detection & Validation

**Indicators**:
- [ ] Monitoring alerts: Spike in requests, high latency
- [ ] Customers: "Site is down"
- [ ] Network: Incoming bandwidth surge

**Validation**:
- [ ] Is this DDoS or legitimate traffic spike?
  - Check traffic source (many IPs vs few?)
  - Check request patterns (random IPs vs botnet?)
  - Check geographic distribution (expected?)

### Phase 2: Mitigation

**Automated Response**:
- [ ] CloudFlare DDoS detection (already active)
- [ ] AWS Shield advanced (rate limiting)
- [ ] Auto-scaling triggered (increase capacity)

**Manual Escalation** (if automated fails):
- [ ] Contact cloud provider (AWS, CDN)
- [ ] Activate DDoS mitigation service (Akamai, Cloudflare)
- [ ] Rate limit aggressively (drop requests after N/second)
- [ ] Block detected attacker IPs

**Continued Monitoring**:
- [ ] Monitor success (is traffic returning to normal?)
- [ ] Check if attack shifts (targets different endpoint?)

### Phase 3: Post-Attack Analysis

- [ ] What was attacked? (API endpoint, static content, login)
- [ ] Duration: How long did attack last?
- [ ] Peak traffic: How many requests/second?
- [ ] Root cause: Why successful? (DDoS protection misconfigured?)

**Improvements**:
- [ ] Increase DDoS protection capacity
- [ ] Add more geographical redundancy
- [ ] Improve rate limiting rules

---

## Post-Incident Review (PIR) Template

```
INCIDENT POST-INCIDENT REVIEW

Incident ID: INC-2026-004-DataBreach
Date: 2026-04-11
Severity: P1 (Critical)
Duration: 2 hours 15 minutes (09:00 – 11:15 UTC)

TIMELINE:
09:00 - DLP alert triggered (unusual egress traffic)
09:05 - On-call analyst acknowledges alert
09:08 - Analyst escalates to VP Engineering (P1)
09:15 - Full IR team assembled
09:30 - Root cause identified: Attacker used stolen credentials
09:45 - Attacker credentials revoked
10:00 - Full database export detected (forensics preserved)
10:15 - Backup restoration initiated
11:15 - Service restored to normal

ROOT CAUSE ANALYSIS (5 Whys):
1. Why was data exfiltrated?
   → Attacker had database credentials
2. Why did attacker have credentials?
   → Credentials were stored in shared 1Password vault
3. Why were they in shared vault?
   → Practice for quick disaster recovery
4. Why not rotated?
   → No automated credential rotation in place
5. Why no detection?
   → DLP only checks HTTP, not SSH tunnel (attacker used SSH)

WHAT WENT WELL:
✓ DLP alert triggered quickly
✓ Team assembled in <15 minutes
✓ Accurate blast radius assessment
✓ Backup was clean and restorable
✓ Public notification done correctly

WHAT COULD BE BETTER:
✗ Took 8 minutes to validate alert (could be faster)
✗ Automated playbook for credential revocation would help
✗ DLP doesn't cover SSH (need endpoint monitoring)
✗ Communications took 30 min to draft (template needed)

ACTION ITEMS:
1. Implement automated credential rotation (Owner: DevOps, Due: 2026-05-11)
2. Deploy EDR to detect SSH exfiltration (Owner: SecOps, Due: 2026-05-11)
3. Create incident communication template (Owner: Communications, Due: 2026-04-18)
4. Run incident response drill (Owner: Security, Due: 2026-05-01)
5. Review all shared credentials in 1Password (Owner: DevOps, Due: 2026-04-15)

LESSONS LEARNED:
- Shared credentials are a liability (move to Vault, revoke shared access)
- DLP needs to cover all egress channels (HTTP + SSH + DNS)
- Pre-written communication templates save critical time
- Automated playbooks reduce manual steps + human error

Prepared By: Alice Chen (Security Lead)
Approved By: Bob Martinez (CISO)
Date: 2026-04-13
```

