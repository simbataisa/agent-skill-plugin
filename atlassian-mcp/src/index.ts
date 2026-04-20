import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import * as confluence from "./clients/confluence.js";
import * as jira from "./clients/jira.js";
import { confluenceConfig, jiraConfig } from "./config.js";

// ─── Server ───────────────────────────────────────────────────────────────────

const server = new McpServer({
  name: "atlassian-mcp",
  version: "1.0.0",
});

// ════════════════════════════════════════════════════════════════════════════
//  CONFLUENCE TOOLS
// ════════════════════════════════════════════════════════════════════════════

// ── List Spaces ───────────────────────────────────────────────────────────────
server.tool(
  "confluence_list_spaces",
  "List all accessible Confluence spaces",
  {
    limit: z.number().int().min(1).max(50).optional().default(25)
      .describe("Max spaces to return (default: 25)"),
  },
  async ({ limit }) => {
    const data = await confluence.listSpaces(limit);
    const lines = data.results.map(
      (s) => `[${s.key}] ${s.name}${s.description?.plain?.value ? ` — ${s.description.plain.value.slice(0, 80)}` : ""}`
    );
    return {
      content: [{ type: "text", text: lines.join("\n") || "No spaces found." }],
    };
  }
);

// ── Search Pages ──────────────────────────────────────────────────────────────
server.tool(
  "confluence_search",
  "Search Confluence pages using CQL (Confluence Query Language)",
  {
    cql: z.string()
      .describe('CQL query. Examples: "space=ARCH AND title~PayLink", "text~kubernetes AND type=page"'),
    limit: z.number().int().min(1).max(50).optional().default(10)
      .describe("Max results (default: 10)"),
  },
  async ({ cql, limit }) => {
    const data = await confluence.searchPages(cql, limit);
    if (data.results.length === 0) {
      return { content: [{ type: "text", text: "No pages found matching your query." }] };
    }
    const lines = data.results.map(
      (p) =>
        `[${p.space.key}] ${p.title} (ID: ${p.id}) v${p.version.number}\n  URL: ${confluenceConfig.baseUrl}${p._links.webui}`
    );
    return {
      content: [
        { type: "text", text: `Found ${data.totalSize} result(s) (showing ${data.results.length}):\n\n${lines.join("\n\n")}` },
      ],
    };
  }
);

// ── Get Page ──────────────────────────────────────────────────────────────────
server.tool(
  "confluence_get_page",
  "Get the full content of a Confluence page by its ID",
  {
    pageId: z.string().describe("Numeric Confluence page ID (e.g. 123456789)"),
  },
  async ({ pageId }) => {
    const p = await confluence.getPage(pageId);
    const ancestors = p.ancestors?.map((a) => a.title).join(" > ") || "—";
    return {
      content: [
        {
          type: "text",
          text: [
            `# ${p.title}`,
            `Space: ${p.space.key} | Version: ${p.version.number}`,
            `Breadcrumb: ${ancestors}`,
            `URL: ${confluenceConfig.baseUrl}${p._links.webui}`,
            ``,
            `## Content (Storage Format)`,
            p.body.storage.value,
          ].join("\n"),
        },
      ],
    };
  }
);

// ── Get Page Children ─────────────────────────────────────────────────────────
server.tool(
  "confluence_get_children",
  "List all child pages of a given Confluence page",
  {
    pageId: z.string().describe("Parent page ID"),
    limit: z.number().int().min(1).max(50).optional().default(25),
  },
  async ({ pageId, limit }) => {
    const data = await confluence.getPageChildren(pageId, limit);
    const lines = data.results.map(
      (p) => `[${p.space.key}] ${p.title} (ID: ${p.id})`
    );
    return {
      content: [{ type: "text", text: lines.join("\n") || "No child pages found." }],
    };
  }
);

// ── Create Page ───────────────────────────────────────────────────────────────
server.tool(
  "confluence_create_page",
  "Create a new Confluence page in a given space",
  {
    spaceKey: z.string().describe("Space key (e.g. ARCH, DEV, INFRA)"),
    title: z.string().describe("Page title"),
    body: z.string().describe("Page content in Confluence storage format (HTML-like)"),
    parentId: z.string().optional()
      .describe("Optional parent page ID to nest this page under"),
  },
  async ({ spaceKey, title, body, parentId }) => {
    const p = await confluence.createPage(spaceKey, title, body, parentId);
    return {
      content: [
        {
          type: "text",
          text: `✅ Page created successfully!\nTitle: ${p.title}\nID: ${p.id}\nURL: ${confluenceConfig.baseUrl}${p._links.webui}`,
        },
      ],
    };
  }
);

// ── Update Page ───────────────────────────────────────────────────────────────
server.tool(
  "confluence_update_page",
  "Update the content of an existing Confluence page (auto-increments version)",
  {
    pageId: z.string().describe("Page ID to update"),
    title: z.string().describe("New title (can be same as current)"),
    body: z.string().describe("New page body in Confluence storage format"),
  },
  async ({ pageId, title, body }) => {
    const current = await confluence.getPage(pageId);
    const updated = await confluence.updatePage(pageId, title, body, current.version.number);
    return {
      content: [
        {
          type: "text",
          text: `✅ Page updated!\nTitle: ${updated.title}\nNew version: ${updated.version.number}\nURL: ${confluenceConfig.baseUrl}${updated._links.webui}`,
        },
      ],
    };
  }
);

// ── Add Label ─────────────────────────────────────────────────────────────────
server.tool(
  "confluence_add_label",
  "Add a label/tag to a Confluence page",
  {
    pageId: z.string().describe("Page ID"),
    label: z.string().describe("Label to add (lowercase, no spaces)"),
  },
  async ({ pageId, label }) => {
    await confluence.addLabel(pageId, label);
    return {
      content: [{ type: "text", text: `✅ Label "${label}" added to page ${pageId}` }],
    };
  }
);

// ── Get Comments ──────────────────────────────────────────────────────────────
server.tool(
  "confluence_get_comments",
  "Get comments on a Confluence page",
  {
    pageId: z.string().describe("Page ID"),
    limit: z.number().int().min(1).max(50).optional().default(25),
  },
  async ({ pageId, limit }) => {
    const data = await confluence.getPageComments(pageId, limit);
    if (data.results.length === 0) {
      return { content: [{ type: "text", text: "No comments on this page." }] };
    }
    const lines = data.results.map(
      (c) => `Comment ID: ${c.id} (v${c.version.number})\n${c.body.storage.value}`
    );
    return { content: [{ type: "text", text: lines.join("\n\n---\n\n") }] };
  }
);

// ── Add Comment ───────────────────────────────────────────────────────────────
server.tool(
  "confluence_add_comment",
  "Add a comment to a Confluence page",
  {
    pageId: z.string().describe("Page ID"),
    comment: z.string().describe("Comment text (plain text or HTML storage format)"),
  },
  async ({ pageId, comment }) => {
    const c = await confluence.addComment(pageId, comment);
    return {
      content: [{ type: "text", text: `✅ Comment added (ID: ${c.id}) to page ${pageId}` }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
//  JIRA TOOLS
// ════════════════════════════════════════════════════════════════════════════

// ── List Projects ─────────────────────────────────────────────────────────────
server.tool(
  "jira_list_projects",
  "List all accessible Jira projects",
  {},
  async () => {
    const data = await jira.listProjects();
    const lines = data.values.map(
      (p) => `[${p.key}] ${p.name} (${p.projectTypeKey})`
    );
    return {
      content: [{ type: "text", text: lines.join("\n") || "No projects found." }],
    };
  }
);

// ── Search Issues ─────────────────────────────────────────────────────────────
server.tool(
  "jira_search",
  "Search Jira issues using JQL (Jira Query Language)",
  {
    jql: z.string()
      .describe('JQL query. Examples: "project=ARCH AND status=\\"In Progress\\"", "assignee=currentUser() AND sprint in openSprints()"'),
    limit: z.number().int().min(1).max(50).optional().default(20)
      .describe("Max results (default: 20)"),
    startAt: z.number().int().min(0).optional().default(0)
      .describe("Offset for pagination (default: 0)"),
  },
  async ({ jql, limit, startAt }) => {
    const data = await jira.searchIssues(jql, limit, startAt);
    if (data.issues.length === 0) {
      return { content: [{ type: "text", text: "No issues found matching your JQL." }] };
    }
    const lines = data.issues.map(
      (i) =>
        `${i.key} [${i.fields.status.name}] [${i.fields.issuetype.name}] ${i.fields.summary}\n  Assignee: ${i.fields.assignee?.displayName ?? "Unassigned"} | Priority: ${i.fields.priority?.name ?? "—"}`
    );
    return {
      content: [
        {
          type: "text",
          text: `Found ${data.total} issue(s) (showing ${data.issues.length} from offset ${data.startAt}):\n\n${lines.join("\n\n")}`,
        },
      ],
    };
  }
);

// ── Get Issue ─────────────────────────────────────────────────────────────────
server.tool(
  "jira_get_issue",
  "Get full details of a specific Jira issue",
  {
    issueKey: z.string().describe('Issue key (e.g. "PROJ-123", "ARCH-456")'),
  },
  async ({ issueKey }) => {
    const i = await jira.getIssue(issueKey);
    const f = i.fields;
    const text = [
      `# ${i.key}: ${f.summary}`,
      ``,
      `Type:     ${f.issuetype.name}`,
      `Status:   ${f.status.name} (${f.status.statusCategory.name})`,
      `Priority: ${f.priority?.name ?? "—"}`,
      `Project:  [${f.project.key}] ${f.project.name}`,
      `Assignee: ${f.assignee?.displayName ?? "Unassigned"}`,
      `Reporter: ${f.reporter?.displayName ?? "—"}`,
      `Labels:   ${f.labels?.join(", ") || "—"}`,
      `Created:  ${new Date(f.created).toLocaleString()}`,
      `Updated:  ${new Date(f.updated).toLocaleString()}`,
      `URL:      ${jiraConfig.baseUrl}/browse/${i.key}`,
    ].join("\n");
    return { content: [{ type: "text", text }] };
  }
);

// ── Create Issue ──────────────────────────────────────────────────────────────
server.tool(
  "jira_create_issue",
  "Create a new Jira issue",
  {
    projectKey: z.string().describe("Project key (e.g. ARCH, DEV)"),
    summary: z.string().describe("Issue title/summary"),
    description: z.string().describe("Issue description (plain text)"),
    issueType: z.enum(["Task", "Story", "Bug", "Epic", "Subtask"]).optional().default("Task")
      .describe("Issue type (default: Task)"),
    assigneeId: z.string().optional()
      .describe("Assignee account ID (use jira_search_users to find)"),
    labels: z.array(z.string()).optional()
      .describe("Labels to apply (e.g. ['architecture', 'urgent'])"),
  },
  async ({ projectKey, summary, description, issueType, assigneeId, labels }) => {
    const created = await jira.createIssue(
      projectKey, summary, description, issueType, assigneeId, labels
    );
    return {
      content: [
        {
          type: "text",
          text: `✅ Issue created!\nKey: ${created.key}\nURL: ${jiraConfig.baseUrl}/browse/${created.key}`,
        },
      ],
    };
  }
);

// ── Add Comment ───────────────────────────────────────────────────────────────
server.tool(
  "jira_add_comment",
  "Add a comment to a Jira issue",
  {
    issueKey: z.string().describe("Issue key (e.g. PROJ-123)"),
    comment: z.string().describe("Comment text (plain text)"),
  },
  async ({ issueKey, comment }) => {
    const c = await jira.addComment(issueKey, comment);
    return {
      content: [{ type: "text", text: `✅ Comment added to ${issueKey} (Comment ID: ${c.id})` }],
    };
  }
);

// ── Get Comments ──────────────────────────────────────────────────────────────
server.tool(
  "jira_get_comments",
  "Get comments on a Jira issue",
  {
    issueKey: z.string().describe("Issue key (e.g. PROJ-123)"),
    limit: z.number().int().min(1).max(50).optional().default(20),
  },
  async ({ issueKey, limit }) => {
    const data = await jira.getComments(issueKey, limit);
    if (data.comments.length === 0) {
      return { content: [{ type: "text", text: `No comments on ${issueKey}.` }] };
    }
    const lines = data.comments.map(
      (c) =>
        `[${new Date(c.created).toLocaleString()}] ${c.author.displayName} (ID: ${c.id})\n${JSON.stringify(c.body)}`
    );
    return {
      content: [{ type: "text", text: `${data.total} comment(s) on ${issueKey}:\n\n${lines.join("\n\n---\n\n")}` }],
    };
  }
);

// ── Get Transitions ───────────────────────────────────────────────────────────
server.tool(
  "jira_get_transitions",
  "Get available status transitions for a Jira issue",
  {
    issueKey: z.string().describe("Issue key (e.g. PROJ-123)"),
  },
  async ({ issueKey }) => {
    const data = await jira.getTransitions(issueKey);
    const lines = data.transitions.map(
      (t) => `ID: ${t.id} | ${t.name} → ${t.to.name}`
    );
    return {
      content: [{ type: "text", text: `Available transitions for ${issueKey}:\n\n${lines.join("\n")}` }],
    };
  }
);

// ── Transition Issue ──────────────────────────────────────────────────────────
server.tool(
  "jira_transition_issue",
  "Change the status of a Jira issue using a transition ID (get IDs with jira_get_transitions)",
  {
    issueKey: z.string().describe("Issue key (e.g. PROJ-123)"),
    transitionId: z.string().describe("Transition ID from jira_get_transitions"),
  },
  async ({ issueKey, transitionId }) => {
    await jira.transitionIssue(issueKey, transitionId);
    return {
      content: [{ type: "text", text: `✅ ${issueKey} transitioned successfully (transition ID: ${transitionId})` }],
    };
  }
);

// ── Search Users ──────────────────────────────────────────────────────────────
server.tool(
  "jira_search_users",
  "Search for Jira users by name or email (useful for finding assignee account IDs)",
  {
    query: z.string().describe("Name or email to search for"),
  },
  async ({ query }) => {
    const users = await jira.searchUsers(query);
    if (users.length === 0) {
      return { content: [{ type: "text", text: "No users found." }] };
    }
    const lines = users.map(
      (u) => `${u.displayName} <${u.emailAddress}>\n  Account ID: ${u.accountId} | Active: ${u.active}`
    );
    return { content: [{ type: "text", text: lines.join("\n\n") }] };
  }
);

// ── Get Issue Types ───────────────────────────────────────────────────────────
server.tool(
  "jira_get_issue_types",
  "List available issue types for a Jira project",
  {
    projectKey: z.string().describe("Project key (e.g. ARCH)"),
  },
  async ({ projectKey }) => {
    const types = await jira.getIssueTypes(projectKey);
    const lines = types.map((t) => `[${t.id}] ${t.name}${t.description ? ` — ${t.description}` : ""}`);
    return { content: [{ type: "text", text: lines.join("\n") }] };
  }
);

// ════════════════════════════════════════════════════════════════════════════
//  START SERVER
// ════════════════════════════════════════════════════════════════════════════

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // IMPORTANT: Use console.error (stderr) — console.log corrupts stdio JSON-RPC
  console.error("✅ Atlassian MCP server running (Confluence + Jira)");
}

main().catch((err) => {
  console.error("Fatal error starting MCP server:", err);
  process.exit(1);
});
