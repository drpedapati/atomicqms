# QMS Workflows with AI Assistant

## Overview

The AtomicQMS AI Assistant enhances quality management workflows by providing intelligent document review, CAPA guidance, change impact assessment, and compliance checking. This guide shows practical examples of how to use the assistant in common QMS scenarios.

## Workflow 1: SOP Review and Approval

### Scenario
You've drafted a new SOP and need it reviewed before approval.

### Process

**1. Create Branch and Draft SOP**

```bash
git checkout -b sop/sample-processing-v2
# Edit your SOP in docs/sops/SOP-001-Sample-Processing.md
git add docs/sops/SOP-001-Sample-Processing.md
git commit -m "Draft: Update sample processing procedure"
git push origin sop/sample-processing-v2
```

**2. Open Pull Request**

Create a PR with:
- **Title**: `SOP-001 v2.0: Enhanced Sample Processing Procedure`
- **Description**:
  ```markdown
  ## Changes
  - Added temperature monitoring requirements
  - Clarified chain of custody procedures
  - Updated sample acceptance criteria

  ## Impact
  - Requires training update
  - New temperature log form needed
  - Equipment validation not affected

  ## Compliance
  - Meets ISO 13485 requirements
  - Addresses last audit finding #45
  ```

**3. Request AI Review**

Add comment to PR:

```markdown
@qms-assistant Please review this SOP for:
1. Completeness and clarity
2. Compliance with ISO 13485
3. Training implications
4. Missing cross-references
```

**4. AI Assistant Response**

Claude will analyze and respond with structured feedback:

```markdown
## SOP Review: SOP-001 v2.0 Sample Processing

### ✅ Strengths
- Clear procedural steps with numbered sequence
- Appropriate safety warnings (Section 3.2)
- Well-defined acceptance criteria (Section 4.3)
- Proper version control block

### ⚠️ Recommendations

**Completeness:**
1. **Section 4.2** - Add specific temperature range (you mention monitoring but not the range)
2. **Section 5.1** - Clarify who performs daily temperature checks
3. **Section 7** - Missing "Troubleshooting" section for common issues

**Compliance:**
1. **ISO 13485 Clause 7.5.3** - Document control: Add document review frequency
2. **Chain of Custody** - Consider adding sample custody form reference
3. **Training** - Explicitly state training requirements in Section 2.3

**Cross-References:**
- Link to SOP-002 (Sample Receipt) in Section 4.1
- Reference FORM-001 (Temperature Log) in Section 5.1
- Connect to CAPA-023 (audit finding) in change notes

### 📋 Missing Elements

**Training Requirements Section:**
```markdown
## 8. Training Requirements

Personnel performing this procedure must:
- Complete SOP-001 training module
- Demonstrate proficiency in sample handling
- Complete refresher training annually
- Document training in Training Log (FORM-050)
```

**Related Documents Section:**
```markdown
## 9. Related Documents

- SOP-002: Sample Receipt and Logging
- SOP-015: Laboratory Safety
- FORM-001: Temperature Monitoring Log
- FORM-025: Sample Chain of Custody
```

### 🎯 Action Items

Before approval:
- [ ] Add missing temperature range (2-8°C per lab specs?)
- [ ] Add Training Requirements section
- [ ] Add Related Documents section
- [ ] Update change log to reference CAPA-023
- [ ] Create/update FORM-001 if temperature log changed

### 📊 Compliance Assessment

**Status:** Substantially compliant with minor gaps

**ISO 13485 Mapping:**
- ✅ Clause 4.2.4: Document control requirements met
- ⚠️ Clause 6.2.2: Training competence - add training section
- ✅ Clause 7.5.3: Traceability - chain of custody addressed

Would you like me to draft the missing sections?
```

**5. Address Feedback and Approve**

Make requested changes, then quality manager approves and merges PR.

---

## Workflow 2: CAPA Documentation

### Scenario
Temperature excursion detected in sample storage—need to document CAPA.

### Process

**1. Create CAPA Issue**

```markdown
Title: CAPA-2025-042: Sample Storage Temperature Excursion

Labels: capa, corrective-action, investigation

## Problem Statement

**Date/Time:** 2025-10-25 14:30
**Discovered By:** Lab Technician (J. Smith)
**Severity:** Medium

Temperature monitoring system alerted to temperature of 12°C in sample refrigerator (SN-RF-001), exceeding acceptable range of 2-8°C for approximately 45 minutes.

**Affected Samples:**
- Batch 2025-1020 through 2025-1025 (25 samples)
- All samples marked for temperature evaluation

**Immediate Actions:**
- Samples quarantined
- Refrigerator taken offline
- Backup refrigerator activated
- Maintenance notified
```

**2. Request AI Assistance**

Comment on issue:

```markdown
@qms-assistant Help me structure the root cause analysis and corrective actions for this temperature excursion CAPA.
```

**3. AI Assistant Response**

```markdown
## CAPA Structure Guidance: Temperature Excursion

I'll help structure your CAPA investigation. Here's a framework:

### Root Cause Analysis (Section 2)

**Investigation Approach:**
Use 5 Whys method for systematic root cause analysis:

```
1. Why did temperature exceed limits?
   → Refrigerator compressor failed to cycle properly

2. Why did the compressor fail to cycle?
   → [Investigate: Mechanical failure? Control failure? Power?]

3. Why wasn't this caught earlier?
   → [Check: Maintenance schedule, previous alerts, logs]

4. Why did it take 45 minutes to discover?
   → Alert system worked, but response time review needed

5. Why...
   → [Continue based on findings]
```

**Data to Collect:**
- [ ] Refrigerator maintenance logs (last 6 months)
- [ ] Temperature monitoring data (last 30 days)
- [ ] Alert system logs (verify alert timing)
- [ ] Previous temperature deviations
- [ ] Maintenance schedule compliance

### Potential Root Causes to Investigate

**Equipment:**
- Compressor age/service history
- Thermostat calibration status
- Door seal integrity
- Recent maintenance activities

**Process:**
- Maintenance schedule adequacy
- Preventive maintenance execution
- Temperature check frequency
- Alert response procedures

**Human Factors:**
- Staff training on alert response
- Maintenance technician qualifications
- Monitoring system interpretation

### Corrective Actions (Section 3)

**Immediate (Containment):**
- ✅ Samples quarantined
- ✅ Unit taken offline
- ✅ Backup unit activated
- [ ] Sample impact assessment (see below)

**Short-term (Address root cause):**
*After root cause determined, consider:*

If mechanical failure:
- [ ] Repair or replace refrigerator
- [ ] Inspect similar units for signs of failure
- [ ] Review maintenance schedule adequacy

If process failure:
- [ ] Update maintenance SOP
- [ ] Enhance alert response protocol
- [ ] Additional staff training

**Sample Impact Assessment:**
```markdown
## 3.5 Sample Integrity Evaluation

For affected samples (Batch 2025-1020 to 2025-1025):

**Evaluation Criteria:**
- Sample type stability data at 12°C
- Duration of exposure (45 minutes)
- Criticality of samples
- Availability of re-test material

**Decision Matrix:**
| Sample Type | Stability at 12°C | Duration Tolerance | Decision |
|-------------|-------------------|-------------------|----------|
| Serum | Stable 4 hours | 45 min < 4 hr | Accept* |
| Plasma | Stable 2 hours | 45 min < 2 hr | Accept* |
| Whole Blood | Stable 1 hour | 45 min < 1 hr | Re-collect |

*Accept with notation in lab report
```

### Preventive Actions (Section 4)

**System-Level Improvements:**
- [ ] Implement redundant temperature monitoring
- [ ] Add predictive maintenance for critical equipment
- [ ] Review alert escalation procedures
- [ ] Create equipment replacement schedule

**Procedural Enhancements:**
- [ ] Update SOP-015 (Equipment Maintenance)
- [ ] Create refrigerator qualification protocol
- [ ] Enhance staff training on alert response
- [ ] Add weekly equipment checks

### Verification Plan (Section 5)

**Verification Activities:**

```markdown
## Verification of Corrective Actions

**Activity 1: Equipment Verification**
- Method: Temperature mapping study of repaired/replaced unit
- Success Criteria: Maintains 2-8°C for 72 hours continuous monitoring
- Responsible: Lab Manager
- Timeline: Within 5 days of repair

**Activity 2: Process Verification**
- Method: Audit maintenance logs for 3 months
- Success Criteria: 100% on-time preventive maintenance
- Responsible: Quality Manager
- Timeline: 90 days post-implementation

**Activity 3: Training Verification**
- Method: Quiz and practical demonstration
- Success Criteria: 100% staff pass training assessment
- Responsible: Training Coordinator
- Timeline: Within 30 days

**Activity 4: Effectiveness Check**
- Method: Review temperature excursion rate
- Success Criteria: Zero excursions for 6 months
- Responsible: Quality Manager
- Timeline: 6-month review
```

### Closure Criteria

Close CAPA only when:
- ✅ Root cause identified and documented
- ✅ Corrective actions implemented
- ✅ Preventive actions implemented
- ✅ All verifications completed successfully
- ✅ Related documents updated
- ✅ Management review completed
- ✅ Effectiveness confirmed (typically 6 months)

### Related Documentation

**Link to these records:**
- SOP-015: Equipment Maintenance and Calibration
- FORM-010: Temperature Monitoring Log
- PR #[number]: Updates to maintenance procedures
- Deviation #2025-042: Initial temperature excursion report

---

Would you like me to:
1. Draft specific sections based on your findings?
2. Create a sample impact assessment template?
3. Help draft the verification plan in detail?

Comment with your investigation findings and I can help complete the CAPA documentation.
```

---

## Workflow 3: Change Impact Assessment

### Scenario
Updating reagent supplier—need to assess impact on validated processes.

### Process

**1. Open Change Control Issue**

```markdown
Title: Change Control: Switch to Alternative Reagent Supplier

Labels: change-control, validation

## Change Description

**Current Supplier:** BioSupply Corp
**Proposed Supplier:** LabChem Industries
**Reagent:** PBS Buffer Solution (Cat# PBS-1000)
**Reason:** Current supplier discontinuing product line

## Proposed Implementation Date
2025-11-15

## Initial Impact Assessment Needed
```

**2. Request AI Analysis**

```markdown
@qms-assistant Analyze the impact of changing our PBS buffer supplier. Consider validation, qualification, documentation, and regulatory implications.
```

**3. AI Assistant Response**

Provides comprehensive change impact analysis covering all affected areas.

---

## Workflow 4: Compliance Check

### Scenario
Quarterly review of QMS documentation for compliance gaps.

### Process

**1. Create Review Issue**

```markdown
Title: Q4 2025 QMS Documentation Compliance Review

Labels: compliance-review, audit

## Scope
Review all SOPs, CAPAs, and change controls updated in Q4 2025 for:
- FDA 21 CFR Part 11 compliance
- ISO 13485 requirements
- Internal audit findings

## Documents in Scope
- SOPs updated: 12
- CAPAs closed: 8
- Change controls: 5
```

**2. Request AI Review**

```markdown
@qms-assistant Review the following SOPs for 21 CFR Part 11 compliance:
- SOP-001 through SOP-012

Check for:
1. Audit trail adequacy
2. Electronic signature compliance
3. Access control documentation
4. Data integrity controls
```

**3. AI Assistant Response**

Systematic compliance gap analysis with recommendations.

---

## Best Practices

### Effective Prompts

**Good:**
```markdown
@qms-assistant Review SOP-015 Section 4.2 for ISO 13485 Clause 7.5.3 compliance.
Focus on traceability requirements and document any gaps.
```

**Better:**
```markdown
@qms-assistant Review SOP-015 Section 4.2 for ISO 13485 Clause 7.5.3 compliance.

Context:
- This is a manufacturing SOP for Class II medical device
- Last audit flagged traceability gaps
- Updates should address audit finding #2025-A-023

Check for:
1. Lot traceability to raw materials
2. Serial number assignment procedure
3. DHR linkage requirements
4. Rework traceability

Provide specific section recommendations.
```

### Iterative Refinement

Use follow-up comments to refine AI responses:

```markdown
@qms-assistant Thanks for the review. Can you elaborate on the DHR linkage requirements? Specifically:
1. What information must be captured?
2. How should we cross-reference between documents?
3. Are there template examples you can provide?
```

### Review History

AI maintains context within a PR/Issue thread. Reference earlier discussions:

```markdown
@qms-assistant Based on your earlier recommendation in comment #3,
I've updated Section 4.2. Please review the changes and confirm
the traceability requirements are now met.
```

## Limitations

### What AI Can Do
- ✅ Review and analyze documentation
- ✅ Suggest improvements and identify gaps
- ✅ Provide compliance guidance
- ✅ Draft sections and templates
- ✅ Identify related documents
- ✅ Explain regulatory requirements

### What AI Cannot Do
- ❌ Formally approve documents
- ❌ Replace quality manager judgment
- ❌ Make final compliance determinations
- ❌ Execute physical process changes
- ❌ Access external databases
- ❌ Override regulatory requirements

## Next Steps

- [Gitea Actions Setup](./gitea-actions-setup.md) - Configure the AI assistant
- [Core Concepts](../guide/core-concepts.md) - Understand AtomicQMS architecture
- [Quick Start](../guide/quick-start.md) - Get started with AtomicQMS

## Templates

Find workflow templates in:
- `.gitea/workflows/` - Automation examples
- `.claude/` - AI context and prompts
- `docs/templates/` - Document templates

## Support

Questions about QMS workflows? Open an issue with the `question` label.
