## Build images with playwright in the box

### Prepare
```shell
cp .env_example .env
```
* set parameters in .env

### Build n8n images if needed
```shell
make build-all
```

### Or use prebuild
#### Docker Compose UP
```shell
make docker-compose-up
```
#### Docker Compose STOP
```shell
make docker-compose-stop
```
#### Docker Compose DOWN
```shell
make docker-compose-down
```

### Community Playwright node for n8n
```text
n8n-nodes-playwright-mcp
```
https://www.npmjs.com/package/n8n-nodes-playwright-mcp

### Postgres settings
```text
https://docs.n8n.io/hosting/configuration/supported-databases-settings/#postgresdb
```

### Playwright docs
https://playwright.help/python/docs/intro

### Example workflow
[example-workflow.json](./example-workflow.json)

### Example n8n Code node
```python
import re
from playwright.sync_api import Page, expect, sync_playwright


def test_has_title(page: Page):
    page.goto("https://playwright.dev/")
    expect(page).to_have_title(re.compile("Playwright"))


def test_get_started_link(page: Page):
    page.goto("https://playwright.dev/")
    page.get_by_role("link", name="Get started").click()
    expect(page.get_by_role("heading", name="Installation")).to_be_visible()


results = []

with sync_playwright() as p:
    # ВАЖЛИВО: headless=True для роботи в Docker/n8n
    # args=['--no-sandbox'] часто необхідний для запусків під root або в контейнерах
    browser = p.chromium.launch(headless=True, args=['--no-sandbox', '--disable-setuid-sandbox'])

    try:
        page = browser.new_page()

        test_has_title(page)
        test_get_started_link(page)

        results.append({
            "status": "success",
            "message": "Tests passed successfully"
        })
    except Exception as e:
        results.append({
            "status": "error",
            "message": str(e)
        })
    finally:
        browser.close()

return results
```