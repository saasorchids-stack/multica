/**
 * Live Smoke Tests — Comprehensive E2E tests against the deployed Aurion app.
 *
 * These tests verify the full user journey against the production deployment
 * (no-auth mode). They don't require database access or login flow.
 *
 * Run: PLAYWRIGHT_BASE_URL=https://multica-main-gules.vercel.app npx playwright test e2e/live-smoke.spec.ts
 */
import { test, expect, type Page } from "@playwright/test";

const BASE_URL =
  process.env.PLAYWRIGHT_BASE_URL ||
  process.env.FRONTEND_ORIGIN ||
  "https://multica-main-gules.vercel.app";

// Helper: navigate to workspace page
async function goto(page: Page, path: string) {
  await page.goto(`${BASE_URL}${path}`, { waitUntil: "domcontentloaded" });
}

// ─── Navigation & Layout ─────────────────────────────────────────────

test.describe("Navigation & Layout", () => {
  test("root redirects to /main/agents", async ({ page }) => {
    await goto(page, "/");
    await page.waitForURL(/\/main\/agents/, { timeout: 15000 });
    expect(page.url()).toContain("/main/agents");
  });

  test("agents page shows header and create button", async ({ page }) => {
    await goto(page, "/main/agents");
    await expect(page.getByRole("heading", { name: "Agents" })).toBeVisible({ timeout: 10000 });
    await expect(page.getByRole("button", { name: /Create Agent/ })).toBeVisible();
  });

  test("sidebar has all navigation links", async ({ page }) => {
    await goto(page, "/main/agents");
    // Open sidebar
    await page.getByRole("button", { name: "Toggle Sidebar" }).click();
    await expect(page.getByRole("dialog", { name: "Sidebar" })).toBeVisible();

    // Check all nav items
    const sidebar = page.getByRole("dialog", { name: "Sidebar" });
    await expect(sidebar.getByRole("link", { name: "Inbox" })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: "My Issues" })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: "Issues" })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: "Projects" })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: "Autopilot" })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: "Agents" })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: "Runtimes" })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: "Skills" })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: "Settings" })).toBeVisible();
  });

  test("sidebar shows current user", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByRole("button", { name: "Toggle Sidebar" }).click();
    const sidebar = page.getByRole("dialog", { name: "Sidebar" });
    await expect(sidebar.getByText("admin@aurion.studio")).toBeVisible();
    await expect(sidebar.getByText("Admin")).toBeVisible();
  });

  test("sidebar navigation works for all pages", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByRole("button", { name: "Toggle Sidebar" }).click();

    // Navigate to Issues
    await page.getByRole("dialog", { name: "Sidebar" }).getByRole("link", { name: "Issues" }).click();
    await page.waitForURL(/\/main\/issues/, { timeout: 10000 });

    // Navigate to Projects
    await page.getByRole("button", { name: "Toggle Sidebar" }).click();
    await page.getByRole("dialog", { name: "Sidebar" }).getByRole("link", { name: "Projects" }).click();
    await page.waitForURL(/\/main\/projects/, { timeout: 10000 });

    // Navigate to Settings
    await page.getByRole("button", { name: "Toggle Sidebar" }).click();
    await page.getByRole("dialog", { name: "Sidebar" }).getByRole("link", { name: "Settings" }).click();
    await page.waitForURL(/\/main\/settings/, { timeout: 10000 });
  });
});

// ─── Issues ──────────────────────────────────────────────────────────

test.describe("Issues", () => {
  test("issues page loads with board columns", async ({ page }) => {
    await goto(page, "/main/issues");
    // Board view columns should be visible
    await expect(page.getByText("Backlog")).toBeVisible({ timeout: 10000 });
    await expect(page.getByText("Todo")).toBeVisible();
    await expect(page.getByText("In Progress")).toBeVisible();
    await expect(page.getByText("In Review")).toBeVisible();
    await expect(page.getByText("Done")).toBeVisible();
  });

  test("issues page has filter tabs", async ({ page }) => {
    await goto(page, "/main/issues");
    await expect(page.getByRole("button", { name: "All" })).toBeVisible({ timeout: 10000 });
    await expect(page.getByRole("button", { name: "Members" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Agents" })).toBeVisible();
  });

  test("can open new issue dialog with keyboard shortcut", async ({ page }) => {
    await goto(page, "/main/issues");
    await page.waitForTimeout(1000);
    await page.keyboard.press("c");
    await expect(page.getByRole("dialog", { name: "New Issue" })).toBeVisible({ timeout: 5000 });
    await expect(page.getByRole("textbox", { name: "Issue title" })).toBeVisible();
  });

  test("can create a new issue", async ({ page }) => {
    await goto(page, "/main/issues");
    await page.waitForTimeout(1000);
    await page.keyboard.press("c");
    await expect(page.getByRole("dialog", { name: "New Issue" })).toBeVisible({ timeout: 5000 });

    const title = `E2E Test Issue ${Date.now()}`;
    await page.getByRole("textbox", { name: "Issue title" }).fill(title);
    await page.getByRole("button", { name: "Create Issue" }).click();

    // Issue should appear in the board
    await expect(page.getByText(title)).toBeVisible({ timeout: 10000 });
  });

  test("new issue dialog has all property pickers", async ({ page }) => {
    await goto(page, "/main/issues");
    await page.waitForTimeout(1000);
    await page.keyboard.press("c");
    const dialog = page.getByRole("dialog", { name: "New Issue" });
    await expect(dialog).toBeVisible({ timeout: 5000 });

    // All pickers should be present
    await expect(dialog.getByRole("button", { name: /Todo|Backlog/ })).toBeVisible();
    await expect(dialog.getByRole("button", { name: /priority/i })).toBeVisible();
    await expect(dialog.getByRole("button", { name: /Unassigned/ })).toBeVisible();
    await expect(dialog.getByRole("button", { name: /Due date/ })).toBeVisible();
    await expect(dialog.getByRole("button", { name: /No project/ })).toBeVisible();
  });

  test("priority picker works in issue dialog", async ({ page }) => {
    await goto(page, "/main/issues");
    await page.waitForTimeout(1000);
    await page.keyboard.press("c");
    const dialog = page.getByRole("dialog", { name: "New Issue" });
    await expect(dialog).toBeVisible({ timeout: 5000 });

    // Click priority button
    await dialog.getByRole("button", { name: /priority/i }).click();
    // Picker should show all priority options
    await expect(page.getByRole("button", { name: "Urgent" })).toBeVisible();
    await expect(page.getByRole("button", { name: "High" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Medium" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Low" })).toBeVisible();

    // Select "Medium"
    await page.getByRole("button", { name: "Medium" }).click();
  });
});

// ─── Issue Detail ────────────────────────────────────────────────────

test.describe("Issue Detail", () => {
  test("can open issue detail and see activity", async ({ page }) => {
    // First create an issue
    await goto(page, "/main/issues");
    await page.waitForTimeout(1000);
    await page.keyboard.press("c");
    await expect(page.getByRole("dialog", { name: "New Issue" })).toBeVisible({ timeout: 5000 });

    const title = `E2E Detail Test ${Date.now()}`;
    await page.getByRole("textbox", { name: "Issue title" }).fill(title);
    await page.getByRole("button", { name: "Create Issue" }).click();

    // Wait for issue to appear then click it
    const issueLink = page.getByText(title);
    await expect(issueLink).toBeVisible({ timeout: 10000 });
    await issueLink.click();

    // Should show issue detail
    await expect(page.getByRole("heading", { name: "Activity" })).toBeVisible({ timeout: 10000 });
    await expect(page.getByText("created this issue")).toBeVisible();
    await expect(page.getByText("Leave a comment...")).toBeVisible();
  });

  test("can add a comment to an issue", async ({ page }) => {
    // Create an issue
    await goto(page, "/main/issues");
    await page.waitForTimeout(1000);
    await page.keyboard.press("c");
    await expect(page.getByRole("dialog", { name: "New Issue" })).toBeVisible({ timeout: 5000 });

    const title = `E2E Comment Test ${Date.now()}`;
    await page.getByRole("textbox", { name: "Issue title" }).fill(title);
    await page.getByRole("button", { name: "Create Issue" }).click();

    // Click the issue to open detail
    await expect(page.getByText(title)).toBeVisible({ timeout: 10000 });
    await page.getByText(title).click();

    // Wait for comment field
    await expect(page.getByText("Leave a comment...")).toBeVisible({ timeout: 10000 });

    // Type a comment
    const commentText = `Test comment ${Date.now()}`;
    await page.locator("[data-placeholder='Leave a comment...']").click();
    await page.locator("[data-placeholder='Leave a comment...']").fill(commentText);

    // Find and click submit button (arrow icon button that becomes enabled after typing)
    const submitButtons = page.locator("button").filter({ has: page.locator("svg") });
    // The submit button is the last one near the comment field
    await page.waitForTimeout(500);
    await page.keyboard.press("Meta+Enter"); // Try Cmd+Enter shortcut

    // Verify comment appears (try both approaches)
    await expect(page.getByText(commentText)).toBeVisible({ timeout: 10000 });
  });
});

// ─── Agents ──────────────────────────────────────────────────────────

test.describe("Agents", () => {
  test("agents page loads", async ({ page }) => {
    await goto(page, "/main/agents");
    await expect(page.getByRole("heading", { name: "Agents" })).toBeVisible({ timeout: 10000 });
  });

  test("create agent dialog opens", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByRole("button", { name: /Create Agent/ }).first().click();
    await expect(page.getByRole("dialog", { name: "Create Agent" })).toBeVisible({ timeout: 5000 });
    await expect(page.getByText("Create a new AI agent")).toBeVisible();
  });

  test("create agent dialog has Cloud mode", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByRole("button", { name: /Create Agent/ }).first().click();
    const dialog = page.getByRole("dialog", { name: "Create Agent" });
    await expect(dialog).toBeVisible({ timeout: 5000 });

    // Should show Cloud/Self-hosted toggle
    await expect(dialog.getByText("Cloud")).toBeVisible();
    await expect(dialog.getByText("Claude Opus 4.6")).toBeVisible();
    await expect(dialog.getByText("OpenRouter")).toBeVisible();
  });

  test("can create a cloud agent", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByRole("button", { name: /Create Agent/ }).first().click();
    const dialog = page.getByRole("dialog", { name: "Create Agent" });
    await expect(dialog).toBeVisible({ timeout: 5000 });

    // Fill name
    const agentName = `E2E Cloud Agent ${Date.now()}`;
    await dialog.getByPlaceholder("e.g. Deep Research Agent").fill(agentName);

    // Fill description
    await dialog.getByPlaceholder("What does this agent do?").fill("E2E test agent using Cloud mode");

    // Cloud mode should be selected by default (no runtimes available)
    await expect(dialog.getByText("Claude Opus 4.6")).toBeVisible();

    // Create button should be enabled
    const createBtn = dialog.getByRole("button", { name: "Create" });
    await expect(createBtn).toBeEnabled();
    await createBtn.click();

    // Agent should appear in the list
    await expect(page.getByText(agentName)).toBeVisible({ timeout: 10000 });
  });

  test("agent detail shows tabs after creation", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByRole("button", { name: /Create Agent/ }).first().click();
    const dialog = page.getByRole("dialog", { name: "Create Agent" });
    await expect(dialog).toBeVisible({ timeout: 5000 });

    const agentName = `E2E Agent Detail ${Date.now()}`;
    await dialog.getByPlaceholder("e.g. Deep Research Agent").fill(agentName);
    await dialog.getByRole("button", { name: "Create" }).click();

    // Should auto-select the new agent and show detail view
    await expect(page.getByText(agentName)).toBeVisible({ timeout: 10000 });

    // Detail tabs should be visible
    await expect(page.getByRole("tab", { name: /Instructions/i }).or(page.getByText("Instructions"))).toBeVisible({ timeout: 10000 });
  });
});

// ─── Projects ────────────────────────────────────────────────────────

test.describe("Projects", () => {
  test("projects page loads", async ({ page }) => {
    await goto(page, "/main/projects");
    await expect(page.getByText(/Projects/)).toBeVisible({ timeout: 10000 });
  });
});

// ─── Autopilots ──────────────────────────────────────────────────────

test.describe("Autopilots", () => {
  test("autopilots page loads", async ({ page }) => {
    await goto(page, "/main/autopilots");
    await expect(page.getByText(/Autopilot/)).toBeVisible({ timeout: 10000 });
  });
});

// ─── Runtimes ────────────────────────────────────────────────────────

test.describe("Runtimes", () => {
  test("runtimes page loads", async ({ page }) => {
    await goto(page, "/main/runtimes");
    await expect(page.getByText(/Runtime/i)).toBeVisible({ timeout: 10000 });
  });
});

// ─── Skills ──────────────────────────────────────────────────────────

test.describe("Skills", () => {
  test("skills page loads", async ({ page }) => {
    await goto(page, "/main/skills");
    await expect(page.getByText(/Skill/i)).toBeVisible({ timeout: 10000 });
  });
});

// ─── Settings ────────────────────────────────────────────────────────

test.describe("Settings", () => {
  test("settings page loads", async ({ page }) => {
    await goto(page, "/main/settings");
    await expect(page.getByText(/Settings/i)).toBeVisible({ timeout: 10000 });
  });

  test("settings shows workspace name", async ({ page }) => {
    await goto(page, "/main/settings");
    await expect(page.getByText("Main")).toBeVisible({ timeout: 10000 });
  });
});

// ─── Chat ────────────────────────────────────────────────────────────

test.describe("Chat", () => {
  test("chat panel has welcome message", async ({ page }) => {
    await goto(page, "/main/agents");
    await expect(page.getByText("Welcome to Aurion")).toBeVisible({ timeout: 10000 });
    await expect(page.getByText("Tell me what to do")).toBeVisible();
  });

  test("chat panel has suggestion buttons", async ({ page }) => {
    await goto(page, "/main/agents");
    await expect(page.getByRole("button", { name: /List my open tasks/ })).toBeVisible({ timeout: 10000 });
    await expect(page.getByRole("button", { name: /Summarize what I did/ })).toBeVisible();
    await expect(page.getByRole("button", { name: /Plan what to work on/ })).toBeVisible();
  });
});

// ─── Search ──────────────────────────────────────────────────────────

test.describe("Search", () => {
  test("search opens with keyboard shortcut", async ({ page }) => {
    await goto(page, "/main/issues");
    await page.waitForTimeout(1000);
    await page.keyboard.press("Meta+k");
    // Command palette should appear (it's the search dialog)
    await expect(page.getByPlaceholder(/Search/i).or(page.getByRole("dialog"))).toBeVisible({ timeout: 5000 });
  });
});
