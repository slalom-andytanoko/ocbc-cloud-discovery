# MCP Server Equivalent Access

GitHub Copilot does not natively support MCP (Model Context Protocol).
The following MCP servers are used by other agent frameworks in this
toolkit. Below is guidance for achieving equivalent functionality.

## atlassian

**Purpose:** Confluence and Jira access — read pages, search content, publish deliverables

**Command:** `npx -y mcp-remote https://mcp.atlassian.com/v1/mcp`

**Required credentials:**
- `CONFLUENCE_EMAIL`
- `CONFLUENCE_API_TOKEN`

**Setup:**

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Create a new API token (label: "Discovery Toolkit")
3. Set CONFLUENCE_EMAIL and CONFLUENCE_API_TOKEN in .env
4. Find your Cloud ID: visit <site>.atlassian.net/_edge/tenant_info
5. Set CONFLUENCE_CLOUD_ID in .env

**Workaround:** Use the corresponding CLI tools directly
or install a compatible VS Code extension that provides
equivalent functionality.

## aws-api

**Purpose:** Read-only AWS account access — query Organizations, GuardDuty, Config, VPCs, IAM

**Command:** `uvx awslabs.aws-api-mcp-server@latest`

**Required credentials:**
- `AWS_PROFILE`

**Setup:**

1. Run: aws configure --profile <engagement-name>
2. Enter the Access Key ID and Secret Access Key for read-only access
3. Set default region to your engagement's primary region
4. The setup wizard will set AWS_PROFILE automatically from your engagement config

**Workaround:** Use the corresponding CLI tools directly
or install a compatible VS Code extension that provides
equivalent functionality.
