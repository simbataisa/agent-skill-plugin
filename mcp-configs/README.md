# MCP Configurations for BMAD Agents

This directory contains Model Context Protocol (MCP) server configurations that extend AI assistants with specialized tools and integrations.

## What is MCP?

The Model Context Protocol allows Claude and other AI assistants to interact with external tools, services, and data sources. MCP configurations define how to connect to these services.

Each MCP server provides tools that agents can use:
- **GitHub**: Repository access, issues, PRs, code search
- **Linear/Jira**: Issue tracking and project management
- **Notion/Confluence**: Documentation and knowledge bases
- **Databases**: Schema inspection, query assistance
- **Slack**: Team notifications
- **Playwright**: Web automation and testing

## Global vs. Project Configurations

### Global Configs
Located in `mcp-configs/global/`. These are always available across all projects and tools:
- `pencil.json` – Design canvas integration
- `github.json` – GitHub repository access
- `filesystem.json` – Extended file system access
- `browser.json` – Web automation (Playwright)

### Project Configs
Located in `mcp-configs/project/`. These are project-specific and integrated into individual projects:
- `linear.json` – Linear issue tracker
- `jira.json` – Jira (alternative to Linear)
- `notion.json` – Notion documentation
- `confluence.json` – Confluence (alternative to Notion)
- `postgres.json` – PostgreSQL database
- `mongodb.json` – MongoDB database
- `slack.json` – Slack integration

## How to Merge an MCP Config

MCP configurations are merged into your tool's MCP configuration file:

### For Claude Desktop
Location: `~/.claude/claude_desktop_config.json`

**To merge a config**:
1. Open the MCP config file (e.g., `github.json`)
2. Copy the `mcpServers` object
3. Paste into your `~/.claude/claude_desktop_config.json` under `mcpServers`

Example:
```bash
# Start with your existing config
cat ~/.claude/claude_desktop_config.json

# Merge in a new MCP server, e.g., GitHub
# Copy the mcpServers.github section into your config
```

Complete merged config structure:
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${HOME}/projects"],
      "env": {}
    },
    "linear": {
      "command": "npx",
      "args": ["-y", "@linear/mcp-server"],
      "env": {
        "LINEAR_API_KEY": "${LINEAR_API_KEY}"
      }
    }
  }
}
```

### For Windsurf
Location: `.windsurf/mcp.json` (project root) or `~/.windsurf/mcp.json` (global)

Windsurf uses the same JSON structure as Claude Desktop.

### For Cursor
Cursor uses the same structure as Claude Desktop in `.cursor/mcp.json` or `~/.cursor/mcp.json`.

## Available MCP Servers

### Global Servers

#### GitHub (`global/github.json`)
- **Purpose**: Repository access, issues, PRs, code search
- **Required**: Set `GITHUB_TOKEN` environment variable with a personal access token
- **Used by**: Tech Lead, Backend Engineer, Code Reviewer
- **Scopes needed**: `repo`, `read:org`

#### Pencil (`global/pencil.json`)
- **Purpose**: Design canvas for UI prototyping
- **Required**: Pencil.app installed at `/Applications/Pencil.app`
- **Used by**: Frontend Engineer, System Designer
- **Note**: macOS only

#### Filesystem (`global/filesystem.json`)
- **Purpose**: Extended file system access
- **Allowed dirs**: `${HOME}/projects`, `${HOME}/documents` (customize as needed)
- **Used by**: All agents
- **Security note**: Restrict to directories you want accessible

#### Playwright (`global/browser.json`)
- **Purpose**: Web automation and testing
- **Used by**: QE Agent for E2E test recording
- **Capabilities**: Browser control, screenshot, recording

### Project Servers

#### Linear (`project/linear.json`)
- **Purpose**: Issue tracking and project management
- **Required**: Set `LINEAR_API_KEY` environment variable
- **Used by**: Tech Lead, Product Owner
- **Alternative**: Jira (use only one)

#### Jira (`project/jira.json`)
- **Purpose**: Jira issue tracking (alternative to Linear)
- **Required**: Set `JIRA_HOST`, `JIRA_EMAIL`, `JIRA_API_TOKEN`
- **Used by**: Tech Lead, Product Owner
- **Note**: Use either Linear or Jira, not both

#### Notion (`project/notion.json`)
- **Purpose**: Documentation and knowledge base
- **Required**: Set `NOTION_TOKEN`
- **Used by**: Business Analyst, Product Owner, System Designer
- **Alternative**: Confluence (use only one)

#### Confluence (`project/confluence.json`)
- **Purpose**: Confluence documentation (alternative to Notion)
- **Required**: Set `CONFLUENCE_HOST`, `CONFLUENCE_EMAIL`, `CONFLUENCE_API_TOKEN`
- **Used by**: Business Analyst, Product Owner, System Designer
- **Note**: Use either Notion or Confluence, not both

#### PostgreSQL (`project/postgres.json`)
- **Purpose**: Database schema inspection and query assistance
- **Required**: Set `DATABASE_URL` (PostgreSQL connection string)
- **Used by**: Backend Engineer, Solution Architect
- **Recommendation**: Use READ-ONLY database credentials for safety
- **Format**: `postgresql://user:password@host:port/database`

#### MongoDB (`project/mongodb.json`)
- **Purpose**: MongoDB schema inspection and query assistance
- **Required**: Set `MONGODB_URI`
- **Used by**: Backend Engineer
- **Format**: `mongodb://user:password@host:port/database`

#### Slack (`project/slack.json`)
- **Purpose**: Team notifications for handoffs and releases
- **Required**: Set `SLACK_BOT_TOKEN` and `SLACK_TEAM_ID`
- **Used by**: Tech Lead for deployment notifications
- **Scopes needed**: `chat:write`, `channels:read`, `users:read`

## Setup Instructions

### 1. Install Global Configs

```bash
# Copy global MCP configs to your home directory
# For Claude Desktop:
cp mcp-configs/global/github.json ~/.claude/mcp-servers/
cp mcp-configs/global/filesystem.json ~/.claude/mcp-servers/
cp mcp-configs/global/browser.json ~/.claude/mcp-servers/
cp mcp-configs/global/pencil.json ~/.claude/mcp-servers/  # macOS only

# Then merge into ~/.claude/claude_desktop_config.json
```

### 2. Set Environment Variables

Global variables in your shell config (~/.bashrc, ~/.zshrc, etc.):
```bash
export GITHUB_TOKEN="your-github-personal-access-token"
export HOME="/Users/yourname"  # Already set
```

### 3. Configure Project MCPs

In each project:
```bash
# Copy project MCPs to .claude/ or .windsurf/
cp mcp-configs/project/linear.json .claude/mcp.json
# OR
cp mcp-configs/project/jira.json .claude/mcp.json

# Copy the MCP template to .bmad/ for team reference
cp mcp-configs/project/template.mcp.json .bmad/mcp-servers-template.json
```

### 4. Set Project-Specific Secrets

In `.env` (never commit this!):
```bash
LINEAR_API_KEY=lin_...
JIRA_API_TOKEN=...
NOTION_TOKEN=...
POSTGRES_URL=postgresql://...
SLACK_BOT_TOKEN=xoxb-...
```

Then reference in your MCP config with `${VAR_NAME}`.

### 5. Verify Setup

```bash
# Test MCP connections in Claude Desktop
# Go to Settings → MCPs and click "Test"
```

## Security Best Practices

### Environment Variables

**NEVER commit secrets to version control.** Always use environment variables:
```json
{
  "env": {
    "GITHUB_TOKEN": "${GITHUB_TOKEN}",
    "LINEAR_API_KEY": "${LINEAR_API_KEY}"
  }
}
```

### Database Credentials

For database MCPs, always use:
- **READ-ONLY credentials** when possible
- **Limited database access** (not full admin)
- **Connection pooling** to prevent resource exhaustion

Example safe PostgreSQL setup:
```bash
# Create a read-only role
CREATE ROLE ai_reader WITH LOGIN PASSWORD 'password';
GRANT CONNECT ON DATABASE mydb TO ai_reader;
GRANT USAGE ON SCHEMA public TO ai_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ai_reader;
```

### API Tokens

- **GitHub**: Use a personal access token with minimal scopes
- **Linear**: Create an API key with limited team/project access
- **Slack**: Create a bot user with minimal permissions
- **Rotate tokens** regularly

## MCP Config Template

Projects can use `template.mcp.json` as a starting point:
```bash
cp mcp-configs/project/template.mcp.json .bmad/mcp-servers-template.json
```

Edit it to uncomment the servers your project needs, then merge into your MCP config.

## Troubleshooting

### MCP Server Not Connecting

1. **Check environment variables**: `echo $GITHUB_TOKEN`
2. **Verify credentials**: Test API key/token directly
3. **Check command availability**: `which npx` or `which node`
4. **Restart Claude Desktop** after changing environment variables

### Too Many MCP Servers

Only enable servers your team actually uses. Too many servers can slow down Claude:
- Start with GitHub + Filesystem + Database
- Add others as needed
- Disable unused servers in config

### Database Connection Issues

- **Test connection**: `psql $DATABASE_URL` or `mongosh $MONGODB_URI`
- **Check firewall**: Ensure database is accessible
- **Check credentials**: Verify user/password/host/port
- **IP whitelisting**: Database may require your IP address

## Related Documentation

- **BMAD Agent Roster**: See `rules/README.md` for which agents use which MCPs
- **Agent Skills**: See `agents/*/SKILL.md` for agent-specific MCP usage
- **MCP Documentation**: https://modelcontextprotocol.io/
