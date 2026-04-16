# Playwright MCP

This sidecar uses the official Playwright MCP container directly through `docker-compose.yml`.

Change the target website in the root `.env` file:

```text
BASE_URL=http://host.docker.internal:3100
```

The MCP server itself stays generic; your AI client uses that base URL when it starts browsing the live site.

