# atlassian-mcp

A local MCP (Model Context Protocol) server that connects Claude to **Confluence** and **Jira** using API Token authentication. Works with both **Atlassian Cloud** and **Data Center / Server** deployments.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Getting Your API Token](#getting-your-api-token)
  - [Setting Up .env](#setting-up-env)
- [Build & Run](#build--run)
- [Connecting to Claude Code](#connecting-to-claude-code)
- [Connecting to Claude Desktop](#connecting-to-claude-desktop)
- [Testing with MCP Inspector](#testing-with-mcp-inspector)
- [Available Tools](#available-tools)
  - [Confluence Tools](#confluence-tools)
  - [Jira Tools](#jira-tools)
- [CQL Reference](#cql-reference-confluence-query-language)
- [JQL Reference](#jql-reference-jira-query-language)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)

---

## Overview

This MCP server exposes **18 tools** (9 Confluence + 9 Jira) that allow Claude to:

- Search and read Confluence pages and spaces
- Create and update Confluence pages
- Search Jira issues using JQL
- Create, comment on, and transition Jira issues
- Look up users, projects, and issue types

All communication uses **Basic Auth with API Token** — no OAuth flow required.

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Node.js     | v18+    |
| npm         | v8+     |
| TypeScript  | v5+     |
| Atlassian account with API token | Cloud or DC |

---

## Project Structure

```
atlassian-mcp/
├── src/
│   ├── index.ts              # MCP server entry point — all tools registered here
│   ├── config.ts             # Reads env vars, builds auth headers
│   └── clients/
│       ├── confluence.ts     # Confluence REST API client
│       └── jira.ts           # Jira REST API v3 client
├── .env.example              # Template for your credentials
├── .gitignore
├── package.json
├── tsconfig.json
└── README.md
```

---

## Installation

```bash
# 1. Clone or download this project
cd atlassian-mcp

# 2. Install dependencies
npm install

# 3. Copy env template
cp .env.example .env
```

---

## Configuration

### Getting Your API Token

#### Atlassian Cloud

1. Go to [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click **Create API token**
3. Give it a label (e.g. `claude-mcp`)
4. Copy the token immediately — it won't be shown again

#### Atlassian Data Center / Server

1. Log in to your Atlassian instance
2. Go to your **Profile** → **Personal Access Tokens**
3. Click **Create token**
4. Set an expiry date and copy the token

> **Note:** For Data Center with Personal Access Tokens, you can use Bearer auth instead of Basic. Change the auth header in `src/config.ts` to:
> ```typescript
> authHeader: `Bearer ${requireEnv("CONFLUENCE_API_TOKEN")}`
> ```

---

### Setting Up .env

Edit your `.env` file with real values:

```env
# ─── Confluence ───────────────────────────────────────────────────────────────
# Atlassian Cloud example:
CONFLUENCE_BASE_URL=https://your-company.atlassian.net/wiki
# Data Center example:
# CONFLUENCE_BASE_URL=https://confluence.yourcompany.com

CONFLUENCE_USERNAME=your.email@company.com
CONFLUENCE_API_TOKEN=ATATxxxxxxxxxxxxxxxxxxxxxxxx

# ─── Jira ─────────────────────────────────────────────────────────────────────
# Atlassian Cloud example:
JIRA_BASE_URL=https://your-company.atlassian.net
# Data Center example:
# JIRA_BASE_URL=https://jira.yourcompany.com

JIRA_USERNAME=your.email@company.com
JIRA_API_TOKEN=ATATxxxxxxxxxxxxxxxxxxxxxxxx
```

> **Important:** Never commit `.env` to version control. It is already in `.gitignore`.

---

## Build & Run

```bash
# Compile TypeScript to JavaScript
npm run build

# Start the server directly (for testing)
npm start

# Watch mode (rebuilds on changes during development)
npm run dev
```

The server communicates over **stdio** (standard input/output), which is how MCP clients connect to it. You will not see output in the terminal when running normally — use the Inspector instead (see below).

---

## Connecting to Claude Code

Add the server to your Claude Code config file:

**Location:** `~/.claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "node",
      "args": ["/absolute/path/to/atlassian-mcp/build/index.js"],
      "env": {
        "CONFLUENCE_BASE_URL": "https://your-company.atlassian.net/wiki",
        "CONFLUENCE_USERNAME": "your.email@company.com",
        "CONFLUENCE_API_TOKEN": "your_token_here",
        "JIRA_BASE_URL": "https://your-company.atlassian.net",
        "JIRA_USERNAME": "your.email@company.com",
        "JIRA_API_TOKEN": "your_token_here"
      }
    }
  }
}
```

> **Tip:** You can use env vars in the config OR rely on a `.env` file in the project directory. Both work.

After saving, reload Claude Code. You should see the Atlassian tools available.

---

## Connecting to Claude Desktop

**Location:**
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "node",
      "args": ["C:/absolute/path/to/atlassian-mcp/build/index.js"]
    }
  }
}
```

Restart Claude Desktop after saving the config.

---

## Testing with MCP Inspector

The MCP Inspector lets you visually test all tools in a browser UI before wiring them into Claude:

```bash
npm run inspector
```

Then open: [http://127.0.0.1:6274](http://127.0.0.1:6274)

In the Inspector:
1. Select **stdio** as the transport type
2. Connect to the server
3. Browse and test all 18 tools interactively

---

## Available Tools

### Confluence Tools

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `confluence_list_spaces` | List all accessible spaces | `limit` |
| `confluence_search` | Search pages via CQL | `cql`, `limit` |
| `confluence_get_page` | Get full page content by ID | `pageId` |
| `confluence_get_children` | List child pages of a page | `pageId`, `limit` |
| `confluence_create_page` | Create a new page | `spaceKey`, `title`, `body`, `parentId?` |
| `confluence_update_page` | Update an existing page | `pageId`, `title`, `body` |
| `confluence_add_label` | Add a label to a page | `pageId`, `label` |
| `confluence_get_comments` | Get comments on a page | `pageId`, `limit` |
| `confluence_add_comment` | Add a comment to a page | `pageId`, `comment` |

---

### Jira Tools

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `jira_list_projects` | List all accessible projects | — |
| `jira_search` | Search issues via JQL | `jql`, `limit`, `startAt` |
| `jira_get_issue` | Get full issue details | `issueKey` |
| `jira_create_issue` | Create a new issue | `projectKey`, `summary`, `description`, `issueType`, `assigneeId?`, `labels?` |
| `jira_add_comment` | Add a comment to an issue | `issueKey`, `comment` |
| `jira_get_comments` | Get comments on an issue | `issueKey`, `limit` |
| `jira_get_transitions` | List available status transitions | `issueKey` |
| `jira_transition_issue` | Change issue status | `issueKey`, `transitionId` |
| `jira_search_users` | Find users by name/email | `query` |
| `jira_get_issue_types` | List issue types for a project | `projectKey` |

---

## CQL Reference (Confluence Query Language)

```sql
-- Search in a specific space
space = "ARCH"

-- Search by title
title ~ "PayLink"

-- Search by text content
text ~ "kubernetes"

-- Search by type
type = page

-- Combine conditions
space = "ARCH" AND title ~ "API" AND type = page

-- Recently modified
lastModified > "2024-01-01"

-- By label
label = "architecture"

-- Pages you created
creator = currentUser()
```

Full CQL reference: [Confluence CQL Docs](https://developer.atlassian.com/cloud/confluence/advanced-searching-using-cql/)

---

## JQL Reference (Jira Query Language)

```sql
-- Issues in a project
project = "ARCH"

-- By status
status = "In Progress"
status in ("To Do", "In Progress")

-- Assigned to me
assignee = currentUser()

-- Open sprint
sprint in openSprints()

-- By priority
priority = High

-- Recently updated
updatedDate >= -7d

-- By label
labels = "architecture"

-- Combine
project = ARCH AND status != Done AND assignee = currentUser() ORDER BY updated DESC

-- Issues with no assignee
assignee is EMPTY
```

Full JQL reference: [Jira JQL Docs](https://support.atlassian.com/jira-service-management-cloud/docs/use-advanced-search-with-jira-query-language-jql/)

---

## Troubleshooting

### "Missing required environment variable"
Ensure your `.env` file exists and all 6 variables are filled in. Run `cat .env` to verify.

### "Confluence API 401 Unauthorized"
- Verify your API token is correct and not expired
- Confirm `CONFLUENCE_USERNAME` is your **email address**, not your display name
- For Data Center PAT: switch to Bearer auth (see [Configuration](#configuration))

### "Confluence API 403 Forbidden"
Your account does not have permission to access that space or page. Check your Confluence space permissions.

### "Jira API 400 Bad Request" on create
- Check `issueType` matches exactly what the project supports (use `jira_get_issue_types`)
- Ensure `projectKey` is uppercase and correct

### Tools not appearing in Claude
- Verify the absolute path in your config is correct: `ls /absolute/path/to/atlassian-mcp/build/index.js`
- Rebuild the project: `npm run build`
- Restart Claude Code / Claude Desktop after config changes

### "Cannot use console.log" / garbled output
Never use `console.log()` in stdio MCP servers — it corrupts the JSON-RPC stream. Use `console.error()` for all debug output.

---

## Security Notes

- **Never commit `.env`** — it is already in `.gitignore`
- **API tokens have your full permissions** — treat them like passwords
- **Rotate tokens regularly** in your Atlassian profile settings
- If using CI/CD or shared environments, use environment-level secrets (e.g. GitHub Secrets, Azure Key Vault) instead of `.env` files
- The server runs locally — no data leaves your machine except to the Atlassian API

---

## License

MIT
