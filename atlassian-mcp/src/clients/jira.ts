import { jiraConfig } from "../config.js";

const BASE = `${jiraConfig.baseUrl}/rest/api/3`;

const defaultHeaders: Record<string, string> = {
  Authorization: jiraConfig.authHeader,
  "Content-Type": "application/json",
  Accept: "application/json",
};

// ─── Core HTTP helper ─────────────────────────────────────────────────────────

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const url = `${BASE}${path}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      ...defaultHeaders,
      ...(options.headers as Record<string, string> | undefined),
    },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Jira API ${res.status} ${res.statusText} — ${url}\n${body}`);
  }

  // 204 No Content (e.g. transitions)
  if (res.status === 204) return undefined as unknown as T;

  return res.json() as Promise<T>;
}

// ─── ADF helper (Atlassian Document Format) ───────────────────────────────────

export function textToAdf(text: string) {
  return {
    type: "doc",
    version: 1,
    content: [
      {
        type: "paragraph",
        content: [{ type: "text", text }],
      },
    ],
  };
}

// ─── Projects ─────────────────────────────────────────────────────────────────

export interface JiraProject {
  id: string;
  key: string;
  name: string;
  projectTypeKey: string;
  description?: string;
}

export async function listProjects(): Promise<{ values: JiraProject[] }> {
  return request("/project/search?expand=description&maxResults=50");
}

export async function getProject(projectKey: string): Promise<JiraProject> {
  return request(`/project/${projectKey}`);
}

// ─── Issues ───────────────────────────────────────────────────────────────────

export interface JiraIssue {
  id: string;
  key: string;
  fields: {
    summary: string;
    description?: unknown;
    status: { name: string; statusCategory: { name: string } };
    priority?: { name: string };
    assignee?: { displayName: string; accountId: string };
    reporter?: { displayName: string };
    issuetype: { name: string };
    project: { key: string; name: string };
    created: string;
    updated: string;
    labels?: string[];
    components?: Array<{ name: string }>;
    fixVersions?: Array<{ name: string }>;
    customfield_10014?: string; // Epic link (common custom field)
  };
}

export async function searchIssues(
  jql: string,
  limit = 20,
  startAt = 0
): Promise<{ issues: JiraIssue[]; total: number; startAt: number }> {
  const fields = [
    "summary", "status", "assignee", "reporter", "priority",
    "issuetype", "project", "created", "updated",
    "labels", "components", "fixVersions",
  ].join(",");

  return request(
    `/search?jql=${encodeURIComponent(jql)}&maxResults=${limit}&startAt=${startAt}&fields=${fields}`
  );
}

export async function getIssue(issueKey: string): Promise<JiraIssue> {
  return request(`/issue/${issueKey}`);
}

export async function createIssue(
  projectKey: string,
  summary: string,
  description: string,
  issueType = "Task",
  assigneeId?: string,
  labels?: string[]
): Promise<{ id: string; key: string; self: string }> {
  const payload: Record<string, unknown> = {
    fields: {
      project: { key: projectKey },
      summary,
      description: textToAdf(description),
      issuetype: { name: issueType },
      ...(labels?.length ? { labels } : {}),
      ...(assigneeId ? { assignee: { id: assigneeId } } : {}),
    },
  };

  return request("/issue", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export async function updateIssue(
  issueKey: string,
  fields: Record<string, unknown>
): Promise<void> {
  return request(`/issue/${issueKey}`, {
    method: "PUT",
    body: JSON.stringify({ fields }),
  });
}

// ─── Comments ─────────────────────────────────────────────────────────────────

export interface JiraComment {
  id: string;
  author: { displayName: string };
  body: unknown;
  created: string;
  updated: string;
}

export async function getComments(
  issueKey: string,
  limit = 20
): Promise<{ comments: JiraComment[]; total: number }> {
  return request(`/issue/${issueKey}/comment?maxResults=${limit}`);
}

export async function addComment(
  issueKey: string,
  comment: string
): Promise<JiraComment> {
  return request(`/issue/${issueKey}/comment`, {
    method: "POST",
    body: JSON.stringify({ body: textToAdf(comment) }),
  });
}

// ─── Transitions (status changes) ─────────────────────────────────────────────

export interface JiraTransition {
  id: string;
  name: string;
  to: { name: string };
}

export async function getTransitions(
  issueKey: string
): Promise<{ transitions: JiraTransition[] }> {
  return request(`/issue/${issueKey}/transitions`);
}

export async function transitionIssue(
  issueKey: string,
  transitionId: string
): Promise<void> {
  return request(`/issue/${issueKey}/transitions`, {
    method: "POST",
    body: JSON.stringify({ transition: { id: transitionId } }),
  });
}

// ─── Users ────────────────────────────────────────────────────────────────────

export interface JiraUser {
  accountId: string;
  displayName: string;
  emailAddress: string;
  active: boolean;
}

export async function searchUsers(query: string): Promise<JiraUser[]> {
  return request(`/user/search?query=${encodeURIComponent(query)}&maxResults=10`);
}

// ─── Issue Types & Statuses ───────────────────────────────────────────────────

export async function getIssueTypes(
  projectKey: string
): Promise<Array<{ id: string; name: string; description: string }>> {
  const project = await request<{ issueTypes: Array<{ id: string; name: string; description: string }> }>(
    `/project/${projectKey}`
  );
  return project.issueTypes ?? [];
}
