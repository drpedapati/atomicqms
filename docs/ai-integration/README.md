# AI Integration

AtomicQMS integrates with Large Language Models (LLMs) to accelerate documentation workflows while maintaining human oversight and quality control.

## Overview

AI integration in AtomicQMS serves as a **writing assistant** that:

- Generates first drafts of SOPs and procedures
- Summarizes review comments and discussions
- Populates standard forms and templates
- Checks consistency across documents
- Enhances semantic search capabilities

**Key Principle**: AI assists, humans approve. All AI-generated content requires human review and sign-off.

## Supported AI Services

AtomicQMS can integrate with:

### Claude (Anthropic)

**Best for**:
- Long-form SOP drafting
- Complex technical documentation
- Multi-step procedure generation
- Compliance-aware content

**API**: Claude API v1

### OpenAI (GPT-4)

**Best for**:
- Quick document generation
- Template population
- Content summarization
- General writing assistance

**API**: OpenAI API v1

### Self-Hosted Models

**Best for**:
- Air-gapped environments
- Sensitive/confidential content
- Custom fine-tuning
- Cost control

**Options**:
- LLaMA 2/3
- Mistral
- Code Llama
- Custom models

## Configuration

### API Keys

Set environment variables:

```bash
# For Claude
export ANTHROPIC_API_KEY="sk-ant-..."

# For OpenAI
export OPENAI_API_KEY="sk-..."

# Configure in docker-compose.yml
services:
  atomicqms:
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
```

### Integration Setup

1. **Install AI Plugin**:
```bash
# Inside container
docker exec -it atomicqms /bin/bash
cd /data/gitea/plugins
git clone https://github.com/atomicqms/ai-plugin.git
```

2. **Enable Plugin**:
Edit `/data/gitea/conf/app.ini`:
```ini
[plugin]
ENABLED = true
AI_PROVIDER = claude  # or openai, self-hosted
AI_MODEL = claude-3-sonnet-20240229
MAX_TOKENS = 4096
```

3. **Restart Container**:
```bash
docker compose restart atomicqms
```

## Use Cases

### 1. SOP Drafting

Generate first draft from outline:

**Input**:
```markdown
# SOP-042: Equipment Calibration

## Outline
- Purpose: Define calibration procedures
- Scope: All lab equipment requiring calibration
- Frequency: Annual or per manufacturer
- Responsibilities: QA Manager, Lab Technicians
- Procedure: [Generate detailed steps]
```

**AI Prompt**:
```
Generate detailed calibration procedure steps for lab equipment including:
- Pre-calibration checks
- Calibration execution
- Documentation requirements
- Out-of-spec handling
Follow FDA 21 CFR Part 11 requirements.
```

**Output**: Complete first draft with detailed steps

### 2. Review Summarization

Condense lengthy review discussions:

**Input**: 25 comments across 5 reviewers on SOP pull request

**AI Prompt**:
```
Summarize the key review comments into:
1. Required changes (must fix)
2. Suggested improvements (should consider)
3. Questions requiring clarification
Group by document section.
```

**Output**: Organized summary for author action

### 3. Template Population

Fill standard forms from inputs:

**Template**: CAPA Form
**Inputs**:
- Issue description
- Root cause analysis
- Corrective actions
- Timeline

**AI fills**:
- Related procedures
- Risk assessment
- Verification plan
- Regulatory references

### 4. Consistency Checking

Compare documents for alignment:

**Check**:
- Does SOP-042 align with Policy-003?
- Are referenced procedures consistent?
- Do definitions match glossary?

**AI Output**:
- Inconsistencies found
- Suggested alignments
- References to update

### 5. Semantic Search

Find documents by concept, not keywords:

**Query**: "How do we handle equipment failures during production?"

**AI Search**:
- Understands intent
- Finds relevant SOPs
- Surfaces related CAPAs
- Suggests procedures

**Results**: Ranked by relevance with context

## Workflows

### AI-Assisted SOP Creation

```
1. User creates outline →
2. AI generates first draft →
3. User reviews and edits →
4. Create pull request →
5. AI summarizes reviews →
6. User addresses comments →
7. Human approval →
8. Merge to main
```

### CAPA with AI Support

```
1. User describes issue →
2. AI suggests root causes →
3. User selects/refines →
4. AI generates action plan →
5. User customizes →
6. Track implementation →
7. AI drafts verification →
8. User approves closure
```

## Quality Controls

### Attribution

All AI-generated content must be marked:

```markdown
<!-- AI-GENERATED: Claude 3 Sonnet -->
<!-- Date: 2024-10-26 -->
<!-- Prompt: [summary of prompt] -->
<!-- Reviewer: [human reviewer name] -->

[AI-generated content here]
```

### Review Requirements

AI-generated documents require:
- ✅ Technical review by SME
- ✅ Quality review by QA
- ✅ Approval by document owner
- ✅ Verification of references
- ✅ Compliance check

### Version Control

Track AI involvement:
```yaml
# In document metadata
ai_assistance:
  provider: claude
  model: claude-3-sonnet-20240229
  date: 2024-10-26
  sections: [procedure, definitions]
  review_status: approved
```

## Best Practices

### Prompt Engineering

**Good prompts**:
- Specific and detailed
- Include context (regulatory requirements)
- Specify format and structure
- Define any constraints

**Example**:
```
Generate a calibration procedure for pH meters used in
pharmaceutical QC testing. Must comply with USP <1058>
and 21 CFR Part 11. Include:
- Pre-use verification steps
- Buffer selection and preparation
- Multi-point calibration protocol
- Acceptance criteria
- Documentation requirements
Output in Markdown format with numbered steps.
```

### Human Oversight

**Required reviews**:
1. **Technical accuracy**: Does it make sense?
2. **Completeness**: Are all steps included?
3. **Compliance**: Does it meet requirements?
4. **Clarity**: Is it understandable?
5. **Safety**: Are hazards addressed?

### Limitations

AI cannot replace:
- Expert judgment
- Regulatory knowledge
- Hands-on experience
- Critical decision-making
- Legal accountability

## Privacy and Security

### Data Handling

**API calls**:
- Only send necessary context
- Redact sensitive information
- Use secure connections (HTTPS)
- Log all AI interactions

**Self-hosted option**:
For maximum security, use self-hosted models:
- No data leaves your infrastructure
- Complete control over models
- Air-gap compatible
- Custom training possible

### Compliance Considerations

**21 CFR Part 11**:
- AI assistance is a "tool"
- Human remains "author of record"
- Full audit trail maintained
- Electronic signatures required

**ISO 13485**:
- Document AI use in procedures
- Validate AI outputs
- Maintain human oversight
- Include in training

## Cost Management

### API Costs

Typical costs (as of 2024):

**Claude 3 Sonnet**:
- Input: $3 / million tokens
- Output: $15 / million tokens
- Typical SOP draft: $0.10-0.50

**GPT-4**:
- Input: $30 / million tokens
- Output: $60 / million tokens
- Typical SOP draft: $1-5

### Cost Control

Strategies:
- Use AI selectively (long docs, complex procedures)
- Cache common prompts
- Batch operations
- Set token limits
- Monitor usage

### Self-Hosted Savings

**One-time costs**:
- GPU server: $5,000-50,000
- Model training: Time investment
- Maintenance: Ongoing

**Benefits**:
- No per-use fees
- Unlimited usage
- Complete privacy
- Custom tuning

## Future Roadmap

Planned AI enhancements:

- **Automated CAPA suggestions** from trend analysis
- **Real-time consistency checking** during document editing
- **Multilingual translation** of procedures
- **Voice-to-text** for verbal procedure drafting
- **Compliance validation** against regulatory databases
- **Training material generation** from SOPs

## Next Steps

- [Document Drafting Guide](./document-drafting.md)
- [Review Automation](./review-automation.md)
- [Self-Hosted Setup](./self-hosted-models.md)
