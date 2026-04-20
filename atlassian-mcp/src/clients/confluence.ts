import { confluenceConfig } from "../config.js";

const BASE = `${confluenceConfig.baseUrl}/rest/api`;

const defaultHeaders: Record<string, string> = {
  Authorization: confluenceConfig.authHeader,
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
    throw new Error(`Confluence API ${res.status} ${res.statusText} — ${url}\n${body}`);
  }

  return res.json() as Promise<T>;
}

// ─── Spaces ───────────────────────────────────────────────────────────────────

export interface Space {
  key: string;
  name: string;
  type: string;
  description?: { plain?: { value: string } };
  _links: { webui: string };
}

export async function listSpaces(limit = 25): Promise<{ results: Space[]; size: number }> {
  return request(`/space?limit=${limit}&expand=description.plain`);
}

// ─── Pages / Content ──────────────────────────────────────────────────────────

export interface PageSummary {
  id: string;
  title: string;
  type: string;
  space: { key: string; name: string };
  version: { number: number };
  _links: { webui: string };
}

export interface PageFull extends PageSummary {
  body: {
    storage: { value: string; representation: string };
  };
  ancestors: Array<{ id: string; title: string }>;
}

export async function searchPages(
  cql: string,
  limit = 10
): Promise<{ results: PageSummary[]; totalSize: number }> {
  return request(
    `/content/search?cql=${encodeURIComponent(cql)}&limit=${limit}&expand=space,version`
  );
}

export async function getPage(pageId: string): Promise<PageFull> {
  return request(
    `/content/${pageId}?expand=body.storage,space,version,ancestors`
  );
}

export async function getPageChildren(
  pageId: string,
  limit = 25
): Promise<{ results: PageSummary[] }> {
  return request(
    `/content/${pageId}/child/page?limit=${limit}&expand=space,version`
  );
}

export async function createPage(
  spaceKey: string,
  title: string,
  body: string,
  parentId?: string
): Promise<PageFull> {
  const payload: Record<string, unknown> = {
    type: "page",
    title,
    space: { key: spaceKey },
    body: { storage: { value: body, representation: "storage" } },
  };
  if (parentId) payload.ancestors = [{ id: parentId }];

  return request("/content", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export async function updatePage(
  pageId: string,
  title: string,
  body: string,
  currentVersion: number
): Promise<PageFull> {
  return request(`/content/${pageId}`, {
    method: "PUT",
    body: JSON.stringify({
      type: "page",
      title,
      version: { number: currentVersion + 1 },
      body: { storage: { value: body, representation: "storage" } },
    }),
  });
}

export async function deletePage(pageId: string): Promise<void> {
  await fetch(`${BASE}/content/${pageId}`, {
    method: "DELETE",
    headers: defaultHeaders,
  });
}

// ─── Labels ───────────────────────────────────────────────────────────────────

export async function addLabel(pageId: string, label: string): Promise<unknown> {
  return request(`/content/${pageId}/label`, {
    method: "POST",
    body: JSON.stringify([{ prefix: "global", name: label }]),
  });
}

// ─── Comments ─────────────────────────────────────────────────────────────────

export interface Comment {
  id: string;
  title: string;
  body: { storage: { value: string } };
  version: { number: number };
}

export async function getPageComments(
  pageId: string,
  limit = 25
): Promise<{ results: Comment[] }> {
  return request(
    `/content/${pageId}/child/comment?limit=${limit}&expand=body.storage,version`
  );
}

export async function addComment(
  pageId: string,
  commentBody: string
): Promise<Comment> {
  return request("/content", {
    method: "POST",
    body: JSON.stringify({
      type: "comment",
      container: { id: pageId, type: "page" },
      body: { storage: { value: commentBody, representation: "storage" } },
    }),
  });
}
