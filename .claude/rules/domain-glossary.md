# Domain Glossary: OCBC Cloud discovery engagement for OCBC covering AWS environments

This glossary is loaded by `process-session-transcript` and other skills to correct speech-to-text errors and ensure consistent terminology across the wiki.

## How to Use This File

- **Skills read this automatically** — no manual action needed
- **Add new entries** when `process-session-transcript` reports corrections not in the glossary
- **Format matters** — keep the table structure so skills can parse it programmatically

---

## Known Speakers

These are people who appear in discovery sessions. Use for speaker identification and name correction.

| Name | Organisation | Role | Common STT Errors |
|------|-------------|------|-------------------|

> Add new speakers as they appear in sessions. Include common STT errors for their names.

---

## Client-Specific Terms

| STT Error Pattern | Correct Term | Notes |
|---|---|---|

> Add client-specific terminology and common STT errors as they emerge during sessions.

---

## Platform Terms

<!-- This section is populated based on activated skill packs during setup. -->
<!-- e.g., AWS terms if the aws/ pack is active, Azure terms if azure/ is active. -->
<!-- Run `python setup.py --refresh --pick-skills` to update after changing packs. -->

### AWS Terms

| Pattern | Correct |
|---|---|
| aft, AFT, a.f.t. | AFT (Account Factory for Terraform) |
| control tower, control Tower | Control Tower |
| landing zone, LZ | Landing Zone |
| oh you, OU, oh use | OU (Organizational Unit) |
| SCP, S.C.P. | SCP (Service Control Policy) |
| guard rails, guard rail | Guardrails |
| I am, IAM, I.A.M. | IAM (Identity and Access Management) |
| VPC, V.P.C. | VPC (Virtual Private Cloud) |
| EC2, easy two, E.C.2 | EC2 |
| S3, S.3 | S3 |
| SNS, S.N.S. | SNS (Simple Notification Service) |
| SQS | SQS (Simple Queue Service) |
| cloud formation, CloudFormation | CloudFormation |
| terraform, terra form | Terraform |
| WAF, waf, war | WAF (Web Application Firewall) |
| transit gateway, TGW | Transit Gateway |
| route 53, Route53 | Route 53 |
| cloud trail, CloudTrail | CloudTrail |
| config, AWS config | AWS Config |
| SSO, single sign on | SSO (AWS IAM Identity Center) |
| organisations, organizations | Organizations |
| EBA, E.B.A. | EBA (Experience-Based Acceleration) |
| IPAM, I.P.A.M. | IPAM (IP Address Management) |
| Palo Alto, palo alto | Palo Alto |
| cloud watch, CloudWatch | CloudWatch |
| lambda, Lambda | Lambda |
| dynamo DB, DynamoDB | DynamoDB |
| EKS, E.K.S. | EKS (Elastic Kubernetes Service) |
| ECS, E.C.S. | ECS (Elastic Container Service) |

---

## Common Speech-to-Text Patterns

These are general STT artefacts that appear regardless of domain:

| Pattern | Action |
|---|---|
| "you know", "like", "sort of like" | Remove when pure filler; keep when qualifying a statement |
| "and so on and so forth" | Remove — adds no specificity |
| "things like that", "that sort of stuff" | Remove unless the preceding list is incomplete and this signals more items |
| "I think", "I believe" | Keep — signals uncertainty vs certainty in a requirement |
| "basically" | Remove when filler; keep when genuinely simplifying |
| Repeated words: "we we we", "the the" | Collapse to single instance |
| False starts: "So I'll, I'll stop" | Keep the completed version only |

---

## Maintenance

After each session processing, `process-session-transcript` will report corrections it applied that aren't in this glossary. Review them and add confirmed ones here.

**Last updated:** (setup date)
**Sessions covered:** (none yet)
