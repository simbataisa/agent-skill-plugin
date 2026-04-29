# Incident Response Plan Template

> Template file for the BMAD InfoSec Architect agent.
> Use this template to document your organization's incident response program.

---

## Document Header

**Organization**: MyCompany  
**Version**: 2.0  
**Last Updated**: 2026-04-11  
**Owner**: Bob Martinez (CISO)  
**Review Date**: 2026-07-11 (Quarterly)  
**Approval**: CISO, COO

---

## IR Team Roster

| Role | Name | Title | Contact | Backup |
|------|------|-------|---------|--------|
| **IR Lead** | Bob Martinez | CISO | bob@example.com, 555-0101 | Carol Singh |
| **Incident Commander** | Alice Chen | Security Lead | alice@example.com, 555-0102 | Bob Martinez |
| **Technical Lead** | David Lee | Platform Architect | david@example.com, 555-0103 | Eve Johnson |
| **Communications** | Eve Johnson | PR Director | eve@example.com, 555-0104 | Frank Williams |
| **Legal** | Frank Williams | General Counsel | frank@example.com, 555-0105 | Carol Singh |
| **Forensics** | Carol Singh | Security Engineer | carol@example.com, 555-0106 | Alice Chen |

---

## Severity Classification

| Level | Definition | Examples | Response Time | Escalation |
|-------|-----------|----------|---------------|-----------|
| **P1** CRITICAL | Active breach, data exfil, critical service down | Ransomware, customer data theft, total outage | 0 min | All senior leadership |
| **P2** HIGH | Significant impact, contained | Attacker inside network, major system degraded | 1 hour | IR Lead + VP Eng |
| **P3** MEDIUM | Limited impact, isolated | Single account compromised | 4 hours | IR Lead |
| **P4** LOW | No real impact | Suspicious log entry, policy violation | 24 hours | On-call analyst |

---

## Detection & Reporting

**Who Reports Incidents**:
- Automated monitoring (SIEM, IDS)
- Employees (suspicious activity)
- Customers (access issues, data concerns)
- Third parties (breach notification)
- Law enforcement

**Reporting Channel**:
- Email: security-incident@example.com
- Chat: #security-incident (Slack)
- Phone: 555-SECURITY (24/7)
- Web: incident-report.example.com

---

## Initial Triage Checklist

**Analyst** receives report → Validate:

- [ ] **Is this real?** (Not false positive)
  - Check monitoring dashboards
  - Try to reproduce issue
  - Check for known scheduled maintenance
  
- [ ] **What system is affected?**
  - Production, staging, development, personal?
  - How critical is that system?
  
- [ ] **What data might be involved?**
  - Customer PII, financial, health?
  - How many records?
  
- [ ] **What's the impact?**
  - Services down? Data leaked? Performance degraded?
  
- [ ] **Severity classification**: P1/P2/P3/P4?

- [ ] **Escalate** if P1 or P2

---

## Severity-Specific Procedures

### P1: CRITICAL

**Immediate (0–15 minutes)**:
```
1. Analyst creates JIRA ticket (P1-CRITICAL-[date]-[id])
2. Activates IR war room (Slack #incident-p1)
3. Notifies:
   - IR Lead (phone call)
   - VP Engineering (chat + email)
   - CISO (chat + email)
4. Begins initial investigation (asset affected, scope)
```

**Team Assembly (15–30 minutes)**:
```
1. IR Lead joins war room
2. IC (Incident Commander) takes charge
3. Assemble technical team: eng, security, devops
4. Assign roles: Incident Commander, Technical Lead, Scribe
5. All comms through war room
```

**Containment (0–2 hours)**:
```
1. Short-term: Stop bleeding
   - Revoke compromised credentials
   - Block attacker IP addresses
   - Isolate affected systems (if safe to do so)
   
2. Investigation parallel path:
   - Preserve forensics (don't power off)
   - Query logs (when did this start?)
   - Assess scope (what was accessed?)
   
3. External comms:
   - Legal notified (breach?)
   - Communications team begins prep (statement?)
   - Customers notified (if data breach, must comply with timeline)
```

### P2: HIGH

**Response (0–1 hour)**:
- IR Lead acknowledged
- 2–3 senior engineers assigned
- Investigation begins (root cause, scope)
- Mitigation plan drafted

### P3/P4

- On-call analyst handles
- Document in JIRA
- Close if resolved

---

## Communication Templates

### Internal Escalation Template (P1)

```
INCIDENT: P1-CRITICAL-2026-0411-001

System: Payment Processing Service
Severity: CRITICAL
First Alert: 2026-04-11 09:15 UTC
Status: ACTIVE

Initial Assessment:
- Attacker detected inside network (compromised credentials)
- Attempting access to customer database
- Data exfiltration risk: HIGH

Immediate Actions:
- Compromised user credentials revoked
- Attacker IP blocked at firewall
- Database access logs being reviewed

Next Steps:
- Forensics team investigating compromise timeline
- Security team identifying other affected systems
- Legal team prepared for potential breach notification

IR War Room: #incident-p1 (Slack)
IC: Alice Chen (alice@example.com)

Next Update: In 30 minutes
```

### Customer Notification Template

```
Dear [Customer Name],

We are writing to inform you that MyCompany discovered unauthorized 
access to our systems on [date]. We take your security seriously and 
have taken the following actions:

What Happened:
We identified unauthorized access to our production environment. While 
our investigation is ongoing, we believe the following data may have 
been accessed:
- Your name and email address
- Payment method (masked): ***-***-***-1234
- NOT exposed: Password, credit card numbers, SSN

What We're Doing:
- We've secured the environment and prevented further access
- We're offering 12 months of free credit monitoring
- Your account password has been reset (check email for new login link)

What You Should Do:
- Change your password immediately
- Monitor your credit reports (link: _____)
- Don't click suspicious links or reply to unexpected emails
- Call us if you have questions

Questions? Contact: security@example.com or 1-800-SECURITY

Sincerely,
Bob Martinez
Chief Information Security Officer
```

---

## Evidence Preservation Checklist

**During Investigation**:
- [ ] Take filesystem snapshots (don't modify)
- [ ] Dump memory image (before power-off)
- [ ] Export logs (before rotation)
- [ ] Screenshot dashboards (anomalies)
- [ ] Chain of custody (who handled what, when)

**Preserve**:
- [ ] Firewall logs (30 days minimum)
- [ ] Database audit logs (immutable)
- [ ] Application logs (centralized, no deletion)
- [ ] CloudTrail/AWS logs (immutable S3)

---

## Regulatory Notification Obligations

| Regulation | Trigger | Timeline | Notify | Notes |
|-----------|---------|----------|--------|-------|
| **GDPR** | PII of EU resident exposed | 72 hours | Regulators + affected people | No delay finding |
| **HIPAA** | PHI disclosed | 60 days | HHS + affected people | No unreasonable delay |
| **CCPA** | CA resident PII exposed | As soon as practicable | Attorney General (if >500 CA residents) | Includes children data |
| **NY SHIELD** | NY resident data exposed | Without unreasonable delay | Attorney General | Consumer notification |
| **PCI-DSS** | Cardholder data breach | 30 days | Card brands | Detailed forensics required |

---

## Post-Incident Review Meeting

**Schedule**: Within 1 week of incident resolution

**Attendees**: Full IR team + engineering leads

**Agenda** (90 minutes):

1. **Timeline** (20 min): What happened, minute by minute
2. **Root Cause** (15 min): Why did this happen?
3. **Contributing Factors** (10 min): What made it worse?
4. **What Went Well** (10 min): Positive actions, good decisions
5. **What Could Be Better** (15 min): Gaps in response
6. **Action Items** (10 min): Who, what, when

**Output**:
- PIR document (posted to wiki)
- JIRA tickets for action items (with owners + deadlines)
- Lessons learned shared with team

---

## Incident Response Drill Schedule

| Drill | Frequency | Scenario | Participants |
|------|-----------|----------|--------------|
| **Tabletop** | Quarterly | Simulate incident (no systems affected) | IR team |
| **Simulation** | Semi-annual | Full response on staging (parallel systems) | IR team + engineers |
| **Full Scale** | Annual | Production incident (under controlled conditions) | All relevant teams |

**Success Criteria**:
- [ ] All team members informed within target time
- [ ] Incident properly classified
- [ ] Containment actions executed
- [ ] Root cause identified
- [ ] Communication sent (internal + external if applicable)

---

## Approvals

- **Prepared By**: Alice Chen (Security Lead)
- **Reviewed By**: Bob Martinez (CISO)
- **Approved By**: Carol Singh (Chief Operating Officer)
- **Effective Date**: 2026-04-11
- **Annual Review Date**: 2026-04-11

