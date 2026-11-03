# staging2 security-audit target

This configuration belongs only to `staging2.optimallearning.org`, Compose
project `staging2`, and the separately enrolled Tailscale node `mofacts-staging2`.
It does not configure production or the older staging installation.

- `docker-compose.runtime.yml` adds the single trusted reverse-proxy hop. Use it
  together with the existing base Compose definition when recreating the app.
- `apache/000-default.conf` is the accepted HTTP redirect/ACME plugin entry.
- `apache/000-default-le-ssl.conf` is the accepted HTTPS proxy policy. It keeps
  existing CSP/HSTS values, preserves stricter app responses, rejects other Host
  values, and routes both Meteor WebSocket forms before the general app route.
- `apache/security.conf` owns `ServerTokens Prod` and `ServerSignature Off`.
- `apache/mofacts-server-name.conf` supplies only the global server name.

The deployed base Compose file is `/opt/mofacts/deploy/docker-compose.yml`; this
runtime overlay is installed alongside it as
`docker-compose.staging2-runtime.yml`. Private environment/settings and
certificate/account keys remain protected on the host. Operator SSH credentials
and the pinned known-host entry remain in Phil's designated personal OneDrive
Desktop credential directory. Do not place their values here.

Apache is the active, boot-enabled proxy. Certbot's packaged timer owns automatic
renewal with its Apache plugin; the renewal dry-run passed. Caddy is stopped and
disabled, with its previous configuration, TLS and service state preserved in
root-only recovery storage. Stop/disable Apache and its newly introduced renewal
timer before an authorized rollback to the retained Caddy state.

The proxy/configuration operation retained the existing `a3155584` app image.
It did not install a new qualified application release. Full audit-reader,
receipt, role-contract and firewall acceptance remain tracked in the main
repository's `docs-developer/security-audit-durable-redesign-status.md`.

The approved optional Sidecar policy is explicit absence. The future protected
audit configuration must set `MOFACTS_SIDECAR_EXPECTED_STATE=absent` and reserve
`MOFACTS_MONGO_SIDECAR_USER=mofacts_sidecar`, with its password and role unset or
empty. Do not create that unused account or start helper containers. A read-only
preflight confirmed the reserved principal, helper containers and relevant ports
were absent; protected-reader installation and full host acceptance remain pending.
