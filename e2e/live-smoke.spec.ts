/**
 * Live Smoke Tests — Comprehensive E2E tests against the deployed Aurion app.
 *
 * Desktop viewport (1280×720): sidebar is a permanent <div data-slot="sidebar">,
 * NOT a dialog. On mobile it becomes a Sheet/dialog, but we test at desktop width.
 * Agent detail tabs are buttons (not role="tab").
 *
 * Run:
 *   PLAYWRIGHT_BASE_URL=https://multica-main-gules.vercel.app npx playwright test e2e/live-smoke.spec.ts
 */
import { test, expect, type Page } from "@playwright/test";

const BASE =
  process.env.PLAYWRIGHT_BASE_URL ??
  process.env.FRONTEND_ORIGIN ??
  "https://multica-main-gules.vercel.app";

async function goto(page: Page, path: string) {
  await page.goto(`${BASE}${path}`, { waitUntil: "domcontentloaded" });
}

/** Return a locator scoped to the permanent desktop sidebar. */
function sidebar(page: Page) {
  return page.locator('[data-sidebar="sidebar"]').first();
}

/** Ensure the sidebar is expanded (not collapsed). */
async function ensureSidebarOpen(page: Page) {
  const sb = sidebar(page);
  // If sidebar is not visible, click the trigger to expand it
  if (!(await sb.isVisible())) {
    await page.getByRole("button", { name: "Toggle Sidebar" }).first().click();
    await expect(sb).toBeVisible({ timeout: 5000 });
  }
  return sb;
}

// ─── Navigation & Layout ─────────────────────────────────────────────

test.describe("Navigation & Layout", () => {
  test("root redirects to workspace", async ({ page }) => {
    await goto(page, "/");
    await page.waitForURL(/\/main\//, { timeout: 15000 });
    expect(page.url()).toContain("/main/");
  });

  test("agents page shows heading", async ({ page }) => {
    await goto(page, "/main/agents");
    await expect(
      page.getByRole("heading", { name: "Agents", level: 1 }),
    ).toBeVisible({ timeout: 10000 });
  });

  test("sidebar has all workspace nav links", async ({ page }) => {
    await goto(page, "/main/agents");
    const sb = await ensureSidebarOpen(page);

    // Personal
    await expect(sb.getByRole("link", { name: "Inbox" })).toBeVisible({ timeout: 10000 });
    await expect(sb.getByRole("link", { name: "My Issues" })).toBeVisible();

    // Workspace
    await expect(sb.getByRole("link", { name: "Issues", exact: true })).toBeVisible();
    await expect(sb.getByRole("link", { name: "Projects" })).toBeVisible();
    await expect(sb.getByRole("link", { name: "Autopilot" })).toBeVisible();
    await expect(sb.getByRole("link", { name: "Agents" })).toBeVisible();
    await expect(sb.getByRole("link", { name: "Executions" })).toBeVisible();

    // Configure
    await expect(sb.getByRole("link", { name: "Runtimes" })).toBeVisible();
    await expect(sb.getByRole("link", { name: "Skills", exact: true })).toBeVisible();
    await expect(sb.getByRole("link", { name: "Settings" })).toBeVisible();
  });

  test("sidebar shows user info", async ({ page }) => {
    await goto(page, "/main/agents");
    const sb = await ensureSidebarOpen(page);
    // The user button displays name + email
    await expect(
      sb.getByRole("button", { name: /Admin/i }),
    ).toBeVisible({ timeout: 10000 });
  });

  test("sidebar has workspace switcher", async ({ page }) => {
    await goto(page, "/main/agents");
    const sb = await ensureSidebarOpen(page);
    await expect(
      sb.getByRole("button", { name: /Main/ }),
    ).toBeVisible({ timeout: 10000 });
  });

  test("sidebar has search and new-issue shortcuts", async ({ page }) => {
    await goto(page, "/main/agents");
    const sb = await ensureSidebarOpen(page);
    await expect(sb.getByRole("button", { name: /Search/ })).toBeVisible({ timeout: 10000 });
    await expect(sb.getByRole("button", { name: /New Issue/ })).toBeVisible();
  });

  test("can navigate between pages via sidebar", async ({ page }) => {
    await goto(page, "/main/agents");

    // Use dispatchEvent to bypass viewport check on sidebar items in nested scroll
    let sb = await ensureSidebarOpen(page);
    await sb.getByRole("link", { name: "Issues", exact: true }).dispatchEvent("click");
    await page.waitForURL(/\/main\/issues/, { timeout: 10000 });

    // → Settings
    sb = await ensureSidebarOpen(page);
    await sb.getByRole("link", { name: "Settings" }).dispatchEvent("click");
    await page.waitForURL(/\/main\/settings/, { timeout: 10000 });
  });
});

// ─── Issues Board ────────────────────────────────────────────────────

test.describe("Issues Board", () => {
  test("board shows all status columns", async ({ page }) => {
    await goto(page, "/main/issues");
    await expect(page.getByText("Backlog")).toBeVisible({ timeout: 10000 });
    await expect(page.getByText("Todo")).toBeVisible();
    await expect(page.getByText("In Progress")).toBeVisible();
    await expect(page.getByText("In Review")).toBeVisible();
    await expect(page.getByText("Done")).toBeVisible();
  });

  test("filter tabs are present", async ({ page }) => {
    await goto(page, "/main/issues");
    await expect(page.getByRole("button", { name: "All" })).toBeVisible({
      timeout: 10000,
    });
    await expect(page.getByRole("button", { name: "Members" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Agents" })).toBeVisible();
  });

  test("can create a new issue via sidebar shortcut", async ({ page }) => {
    await goto(page, "/main/issues");
    const sb = await ensureSidebarOpen(page);
    await sb.getByRole("button", { name: /New Issue/ }).dispatchEvent("click");

    // A dialog should appear for creating an issue
    await expect(page.getByRole("dialog")).toBeVisible({
      timeout: 5000,
    });
  });
});

// ─── Agents ──────────────────────────────────────────────────────────

test.describe("Agents", () => {
  test("page loads with heading", async ({ page }) => {
    await goto(page, "/main/agents");
    await expect(
      page.getByRole("heading", { name: "Agents" }),
    ).toBeVisible({ timeout: 10000 });
  });

  test("existing agent is listed", async ({ page }) => {
    await goto(page, "/main/agents");
    await expect(page.getByText("Aurion AI Assistant").first()).toBeVisible({
      timeout: 10000,
    });
  });

  test("agent detail shows all tabs", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByText("Aurion AI Assistant").first().click();

    const detail = page.getByTestId("detail");
    const expectedTabs = [
      "Instructions",
      "Skills",
      "Tasks",
      "MCP Servers",
      "Environment",
      "Custom Args",
      "Settings",
    ];

    for (const tab of expectedTabs) {
      await expect(
        detail.getByRole("button", { name: tab }),
      ).toBeVisible({ timeout: 10000 });
    }
  });

  test("Instructions tab is default and has text area", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByText("Aurion AI Assistant").first().click();

    await expect(page.getByText("Agent Instructions")).toBeVisible({
      timeout: 10000,
    });
    await expect(
      page.getByText("Define this agent's identity"),
    ).toBeVisible();
  });

  test("agent shows Idle status and Cloud badge", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByText("Aurion AI Assistant").first().click();

    const detail = page.getByTestId("detail");
    await expect(detail.getByText("Idle")).toBeVisible({ timeout: 10000 });
    await expect(detail.getByText("Cloud")).toBeVisible();
  });

  test("can navigate all agent tabs without errors", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByText("Aurion AI Assistant").first().click();

    const detail = page.getByTestId("detail");
    const tabs = [
      "Instructions",
      "Skills",
      "Tasks",
      "MCP Servers",
      "Environment",
      "Custom Args",
      "Settings",
    ];

    for (const tabName of tabs) {
      await detail.getByRole("button", { name: tabName }).click();
      await page.waitForTimeout(500);
      // Page didn't crash
      expect(page.url()).toContain("/main/agents");
    }
  });

  test("MCP Servers tab loads", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByText("Aurion AI Assistant").first().click();
    await page.getByRole("button", { name: "MCP Servers" }).click();
    await expect(page.getByText(/MCP/i)).toBeVisible({ timeout: 10000 });
  });

  test("Settings tab loads", async ({ page }) => {
    await goto(page, "/main/agents");
    await page.getByText("Aurion AI Assistant").first().click();
    await page.getByRole("button", { name: "Settings" }).click();
    // Settings tab should show some settings content
    await page.waitForTimeout(1000);
    expect(page.url()).toContain("/main/agents");
  });
});

// ─── Chat Panel ──────────────────────────────────────────────────────

test.describe("Chat Panel", () => {
  test("chat input is visible on agents page", async ({ page }) => {
    await goto(page, "/main/agents");
    // Chat input uses tiptap with data-placeholder attribute (rendered via CSS)
    await expect(
      page.locator("[data-placeholder*='what to do']"),
    ).toBeVisible({ timeout: 10000 });
  });

  test("chat panel shows agent selector", async ({ page }) => {
    await goto(page, "/main/agents");
    // Agent name appears in the chat panel selector
    await expect(
      page.getByText("Aurion AI Assistant").last(),
    ).toBeVisible({ timeout: 10000 });
  });
});

// ─── Other Pages ─────────────────────────────────────────────────────

test.describe("Other Pages", () => {
  test("projects page loads", async ({ page }) => {
    await goto(page, "/main/projects");
    await expect(page.getByText(/Projects/i).first()).toBeVisible({
      timeout: 10000,
    });
  });

  test("autopilots page loads", async ({ page }) => {
    await goto(page, "/main/autopilots");
    await expect(page.getByText(/Autopilot/i).first()).toBeVisible({
      timeout: 10000,
    });
  });

  test("runtimes page loads", async ({ page }) => {
    await goto(page, "/main/runtimes");
    await expect(page.getByText(/Runtime/i).first()).toBeVisible({
      timeout: 10000,
    });
  });

  test("skills page loads", async ({ page }) => {
    await goto(page, "/main/skills");
    await expect(page.getByText(/Skill/i).first()).toBeVisible({
      timeout: 10000,
    });
  });

  test("settings page loads", async ({ page }) => {
    await goto(page, "/main/settings");
    await expect(page.getByText(/Settings/i).first()).toBeVisible({
      timeout: 10000,
    });
  });

  test("executions page loads", async ({ page }) => {
    await goto(page, "/main/executions");
    await expect(page.getByText(/Execution Agents/i).first()).toBeVisible({
      timeout: 10000,
    });
  });

  test("executions page shows templates", async ({ page }) => {
    await goto(page, "/main/executions");
    await expect(page.getByText("Web Scraper")).toBeVisible({ timeout: 10000 });
    await expect(page.getByText("LinkedIn Prospector")).toBeVisible();
    await expect(page.getByText("Code Generator")).toBeVisible();
    await expect(page.getByText("Deep Research")).toBeVisible();
    await expect(page.getByText("Form Automator")).toBeVisible();
    await expect(page.getByText("Custom Agent")).toBeVisible();
  });

  test("executions page template selection shows prompt builder", async ({ page }) => {
    await goto(page, "/main/executions");
    // Click on Web Scraper template
    await page.getByText("Web Scraper").click();
    // Prompt builder should appear with configure section
    await expect(page.getByText("Configure Execution")).toBeVisible({ timeout: 5000 });
    // Stealth mode toggle should be visible (Web Scraper has stealth on by default)
    await expect(page.getByText("Stealth Mode")).toBeVisible();
    // Launch button
    await expect(page.getByRole("button", { name: /Launch Execution/i })).toBeVisible();
  });

  test("executions page shows anti-detection tools panel", async ({ page }) => {
    await goto(page, "/main/executions");
    // Click Anti-Detection Tools button
    await page.getByRole("button", { name: /Anti-Detection Tools/i }).click();
    await expect(page.getByText("puppeteer-extra-stealth")).toBeVisible({ timeout: 5000 });
    await expect(page.getByText("FlareSolverr")).toBeVisible();
    await expect(page.getByText("curl-impersonate")).toBeVisible();
  });

  test("executions page shows recent executions section", async ({ page }) => {
    await goto(page, "/main/executions");
    await expect(page.getByText("Recent Executions")).toBeVisible({ timeout: 10000 });
    // Empty state should show "No executions yet"
    await expect(page.getByText(/No executions yet/i)).toBeVisible();
  });

  test("executions page can navigate from sidebar", async ({ page }) => {
    await goto(page, "/main/agents");
    const sb = await ensureSidebarOpen(page);
    await sb.getByRole("link", { name: "Executions" }).dispatchEvent("click");
    await page.waitForURL(/\/main\/executions/, { timeout: 10000 });
    await expect(page.getByText(/Execution Agents/i).first()).toBeVisible({ timeout: 10000 });
  });
});

// ─── Cross-Page Smoke ────────────────────────────────────────────────

test.describe("Cross-Page Smoke", () => {
  test("all main pages load without 500 errors", async ({ page }) => {
    const routes = [
      "/main/agents",
      "/main/issues",
      "/main/projects",
      "/main/autopilots",
      "/main/runtimes",
      "/main/skills",
      "/main/settings",
      "/main/executions",
      "/main/inbox",
      "/main/my-issues",
    ];

    for (const route of routes) {
      const response = await page.goto(`${BASE}${route}`, {
        waitUntil: "domcontentloaded",
      });
      expect(response?.status()).toBeLessThan(500);
    }
  });
});
