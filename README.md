# QA Automation Framework


> **End-to-end test automation framework built with Playwright, TypeScript, and REST API testing.**  
> Designed for enterprise-grade regression coverage with full CI/CD integration via GitHub Actions.

---

## What This Framework Does

This project demonstrates a production-ready QA automation framework I built to showcase the kind of testing infrastructure I design and maintain professionally.

It covers three layers of testing:

- **UI Automation** — browser-based end-to-end tests using Playwright and the Page Object Model
- **REST API Testing** — full CRUD validation using Playwright's API request context
- **CI/CD Integration** — automated test execution on every push via GitHub Actions

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| [Playwright](https://playwright.dev/) | Browser automation + API testing |
| TypeScript | Type-safe test development |
| Page Object Model | Maintainable UI test architecture |
| GitHub Actions | CI/CD pipeline — smoke → regression → API |
| JUnit XML Reporter | Test results for CI dashboards |
| HTML Reporter | Visual test results and failure traces |

---

## Project Structure

```
qa-automation-framework/
├── src/
│   ├── pages/
│   │   ├── BasePage.ts         # Shared actions & assertions
│   │   ├── LoginPage.ts        # Login page interactions
│   │   └── DashboardPage.ts    # Product dashboard interactions
│   ├── tests/
│   │   ├── ui/
│   │   │   ├── login.spec.ts       # Auth flows
│   │   │   └── dashboard.spec.ts   # Product, cart, sort
│   │   └── api/
│   │       ├── users.spec.ts   # Full CRUD
│   │       └── auth.spec.ts    # Login & register flows
│   └── utils/
│       ├── ApiHelper.ts    # REST wrapper with assertion helpers
│       ├── TestData.ts     # Centralized test data
│       └── Logger.ts       # Structured execution logging
├── .github/
│   └── workflows/
│       └── playwright.yml  # CI — smoke, regression, api, summary
├── playwright.config.ts
├── tsconfig.json
└── package.json
```

---

## Running Tests

### Prerequisites
- Node.js 18+
- npm

### Install
```bash
npm install
npx playwright install
```

### Run by type
```bash
npm run test:smoke        # Fast gate — critical paths, Chromium only
npm run test:regression   # Full suite across all browsers
npm run test:api          # API tests only
npm run test:ui           # UI tests only
npm run test:headed       # Watch tests run in browser
npm run report            # Open HTML test report
```

---

## CI/CD Pipeline

Runs automatically on every push and pull request:

```
Push to main/develop
        │
        ▼
  ┌─────────────┐
  │ Smoke Tests │  ← Fast gate (Chromium only)
  └──────┬──────┘
         │ pass
         ▼
  ┌──────────────────────────────────────┐    ┌─────────────┐
  │     Regression (parallel matrix)     │    │  API Tests  │
  │  Chromium  │  Firefox  │  WebKit     │    │  reqres.in  │
  └──────────────────────────────────────┘    └─────────────┘
         │                                          │
         └──────────────────┬───────────────────────┘
                            ▼
                   ┌──────────────┐
                   │ Test Summary │
                   └──────────────┘
```

Full regression runs daily at 6 AM UTC.

---

## Test Coverage

### UI Tests

| Suite | Tests | Tags |
|-------|-------|------|
| Login | Valid login, invalid creds, locked account, empty fields, error dismiss, logout | `@smoke` `@regression` |
| Dashboard | Product count, page title, add to cart (1 and 2 items), sort A-Z, Z-A, price asc/desc | `@smoke` `@regression` |

### API Tests

| Suite | Tests | Tags |
|-------|-------|------|
| Users CRUD | GET list, GET by ID, 404 handling, POST create, PUT full update, PATCH partial, DELETE | `@smoke` `@regression` |
| Auth | Login with token, missing password, missing email, unregistered email, register, bearer token | `@smoke` `@regression` |

---

## Key Design Decisions

**Page Object Model** — All UI interactions live in page classes. Tests read like plain English. Selector changes require updating one file, not twenty.

**Centralized test data** — `TestData.ts` is the single source of truth for all inputs and expected values. No magic strings scattered across tests.

**Layered CI pipeline** — Smoke tests provide fast feedback. Full regression runs in parallel across three browsers. API tests run independently. Results aggregate into a summary posted to the PR.

**ApiHelper abstraction** — Wraps Playwright's request context so API tests stay readable. Status assertions and logging live in the helper, not repeated per test.

**Tags for targeting** — Every test is tagged `@smoke` or `@regression` so CI can run targeted subsets without touching config.

---

## About

Built by **Demitre Schooler** — Senior QA Automation Engineer with 6+ years designing and scaling test automation infrastructure at Best Buy and PNC Bank.

- Email: demitrejob@gmail.com
- LinkedIn: [linkedin.com/in/demitre-schooler-477427342](https://linkedin.com/in/demitre-schooler-477427342)
- Location: New York, USA | US Citizen | Open to Remote
