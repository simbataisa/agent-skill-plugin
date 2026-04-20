import "dotenv/config";

function requireEnv(key: string): string {
  const val = process.env[key];
  if (!val) {
    throw new Error(
      `Missing required environment variable: ${key}\n` +
      `Please copy .env.example to .env and fill in your credentials.`
    );
  }
  return val;
}

// ─── Confluence ───────────────────────────────────────────────────────────────
const confluenceUsername  = requireEnv("CONFLUENCE_USERNAME");
const confluenceApiToken  = requireEnv("CONFLUENCE_API_TOKEN");

export const confluenceConfig = {
  baseUrl: requireEnv("CONFLUENCE_BASE_URL").replace(/\/$/, ""), // strip trailing slash
  authHeader: `Basic ${Buffer.from(`${confluenceUsername}:${confluenceApiToken}`).toString("base64")}`,
};

// ─── Jira ─────────────────────────────────────────────────────────────────────
const jiraUsername  = requireEnv("JIRA_USERNAME");
const jiraApiToken  = requireEnv("JIRA_API_TOKEN");

export const jiraConfig = {
  baseUrl: requireEnv("JIRA_BASE_URL").replace(/\/$/, ""),
  authHeader: `Basic ${Buffer.from(`${jiraUsername}:${jiraApiToken}`).toString("base64")}`,
};
