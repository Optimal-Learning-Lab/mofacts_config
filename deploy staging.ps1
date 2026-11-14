#Requires -Version 7.4
[CmdletBinding()]
param([switch]$DeferAcceptance, [switch]$AcceptExisting, [switch]$DeployPublished)

# Deliberately no host, URL, project or production-path parameters. This is the
# staging operator entry point; production retains its separate existing owner.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
if ($DeferAcceptance -and $AcceptExisting) { throw 'Choose deployment or acceptance, not both' }
if ($DeployPublished -and $AcceptExisting) { throw 'Choose installation or acceptance, not both' }
$MofactsRoot = 'C:\dev\MoFaCTS'
$ConfigRoot = 'C:\dev\mofacts_config'
foreach ($mapping in @(@('MOFACTS_CONFIG_REPO', $ConfigRoot), @('MOFACTS_WIKI_REPO', 'C:\dev\MoFaCTS.wiki'))) {
    $configured = [Environment]::GetEnvironmentVariable($mapping[0])
    if ($configured -and [IO.Path]::GetFullPath($configured).TrimEnd('\') -ine $mapping[1]) { throw "Noncanonical $($mapping[0])" }
    if (!(Test-Path -LiteralPath $mapping[1] -PathType Container)) { throw "Missing canonical repository: $($mapping[1])" }
}
$OperatorRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop'
$StageKey = Join-Path $OperatorRoot 'mykey.pem'
$StageHost = 'ubuntu@44.253.109.187'
$StageUrl = 'https://staging.optimallearning.org'
if (@([Net.Dns]::GetHostAddresses('staging.optimallearning.org') | ForEach-Object IPAddressToString) -notcontains '44.253.109.187') { throw 'Staging DNS does not identify the configured staging host' }
$StageEnvPath = Join-Path $OperatorRoot '.env.staging'
$StageSettingsPath = Join-Path $OperatorRoot 'settingsstaging.json'
$StageReplicaKey = Join-Path $OperatorRoot 'staging-mongodb-keyfile'
$RecordPath = Join-Path $OperatorRoot 'mofacts-staging-deployment.json'
$AcceptedPath = Join-Path $OperatorRoot 'mofacts-staging-release.json'
$OverlayPath = Join-Path $ConfigRoot 'staging\docker-compose.staging.yml'
$ApachePath = Join-Path $ConfigRoot 'staging\apache\000-default-le-ssl.conf'
$ImageRepository = 'ppavlikmemphis/mofacts-mini'
$SshOptions = @('-o', 'BatchMode=yes', '-o', 'ConnectTimeout=15', '-i', $StageKey)

function Invoke-StagingSsh([string]$Command) {
    # Every operation verifies this exact machine before any mutation.
    $guard = "set -euo pipefail`n[ `"`$(cat /etc/machine-id)`" = ec2cff643d953ceedc56a113cd1f488c ]`n"
    # Encode exact UTF-8 bytes: Windows native stdin appends CRLF, which must
    # never become part of a Linux filename or shell token.
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($guard + $Command).Replace("`r`n", "`n") + "`n"))
    & ssh @SshOptions $StageHost "printf '%s' '$encoded' | base64 --decode | sudo bash -se"
}
function Send-StagingFile([string]$Source, [string]$Destination) {
    & scp @SshOptions $Source "${StageHost}:$Destination"
}
function Assert-StagingRelease($Record) {
    if ($Record.url -ne $StageUrl -or $Record.host -ne $StageHost -or
        $Record.imageTag -notmatch '^staging-(local-)?[0-9]{14}Z-[0-9a-f]{12}$' -or
        $Record.imageDigest -notmatch '^sha256:[0-9a-f]{64}$' -or
        $Record.sourceCommit -notmatch '^[0-9a-f]{40}$') { throw 'Invalid staging deployment identity' }
    $publishedId = (Invoke-StagingSsh "docker image inspect '$ImageRepository@$($Record.imageDigest)' --format '{{.Id}}'").Trim()
    $runningId = (Invoke-StagingSsh "docker inspect mofacts-staging --format '{{.Image}}'").Trim()
    $runningRevision = (Invoke-StagingSsh "docker inspect mofacts-staging --format '{{index .Config.Labels `"org.opencontainers.image.revision`"}}'").Trim()
    $runningProject = (Invoke-StagingSsh "docker inspect mofacts-staging --format '{{index .Config.Labels `"com.docker.compose.project`"}}'").Trim()
    if ($publishedId -notmatch '^sha256:[0-9a-f]{64}$' -or $runningId -ne $publishedId -or
        $runningRevision -ne $Record.sourceCommit -or $runningProject -ne 'mofacts-staging') { throw 'Running staging image/project does not match the deployed digest/revision' }
    $health = Invoke-WebRequest "$StageUrl/health"
    if ($health.StatusCode -ne 200) { throw 'Staging HTTPS health failed' }
    $sockjs = Invoke-RestMethod "$StageUrl/sockjs/info"
    if (!$sockjs.websocket) { throw 'Staging SockJS does not advertise WebSocket support' }
    $expectedCsp = [regex]::Match((Get-Content -LiteralPath $ApachePath -Raw), 'Header always set Content-Security-Policy "([^"]+)"').Groups[1].Value
    $head = Invoke-WebRequest "$StageUrl/admin/tests" -Method Head
    if (!$expectedCsp -or [string]$head.Headers['Content-Security-Policy'] -ne $expectedCsp) { throw 'Staging CSP differs from its tracked Apache configuration' }
    return $runningId
}

foreach ($file in @($StageKey, $StageEnvPath, $StageSettingsPath, $StageReplicaKey, $OverlayPath, $ApachePath)) {
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Required staging input missing: $file" }
}
if ($AcceptExisting) {
    $record = Get-Content -LiteralPath $RecordPath -Raw | ConvertFrom-Json -AsHashtable
} else {
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $StageEnvPath) {
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            if ($values.ContainsKey($Matches[1])) { throw "Duplicate staging env key: $($Matches[1])" }
            $values[$Matches[1]] = $Matches[2]
        }
    }
    $required = @('ROOT_URL','DOCKER_REGISTRY','IMAGE_NAME','IMAGE_TAG','MONGO_URL','EXPECTED_MONGO_DB_NAME',
        'MOFACTS_MONGO_APP_DATABASE','MONGO_INITDB_ROOT_USERNAME','MONGO_INITDB_ROOT_PASSWORD',
        'MOFACTS_MONGO_APP_USERNAME','MOFACTS_MONGO_APP_PASSWORD','MOFACTS_REDIS_PASSWORD',
        'MOFACTS_SECURITY_AUDIT_INGEST_SECRET','MOFACTS_MONGO_REPLICA_SET_NAME','MOFACTS_MONGO_REPLICA_SET_MEMBER',
        'METEOR_REACTIVITY_ORDER','DDP_TRANSPORT','METEOR_SETTINGS_HOST_PATH','MOFACTS_ENV_FILE_HOST_PATH',
        'MONGO_REPLICA_SET_KEYFILE_HOST_PATH','MOFACTS_BACKUP_HOST_PATH','MOFACTS_HTTP_BIND')
    foreach ($name in $required) { if (!$values.ContainsKey($name) -or [string]::IsNullOrWhiteSpace($values[$name])) { throw "Missing staging env key: $name" } }
    $expected = @{
        ROOT_URL=$StageUrl; METEOR_SETTINGS_HOST_PATH='./settingsstaging.json'; MOFACTS_ENV_FILE_HOST_PATH='./.env';
        MONGO_REPLICA_SET_KEYFILE_HOST_PATH='/etc/mofacts-staging/mongodb-keyfile';
        MOFACTS_BACKUP_HOST_PATH='/backups/mofacts-staging'; MOFACTS_HTTP_BIND='127.0.0.1:3000';
        EXPECTED_MONGO_DB_NAME='MoFACT-meteor3'; MOFACTS_MONGO_APP_DATABASE='MoFACT-meteor3';
        MOFACTS_MONGO_REPLICA_SET_NAME='mofacts-rs'; MOFACTS_MONGO_REPLICA_SET_MEMBER='mongodb:27017';
        METEOR_REACTIVITY_ORDER='changeStreams'; DDP_TRANSPORT='sockjs'
    }
    foreach ($name in $expected.Keys) { if ($values[$name] -cne $expected[$name]) { throw "Staging boundary mismatch: $name" } }
    if ("$($values['DOCKER_REGISTRY'])/$($values['IMAGE_NAME'])" -ne $ImageRepository) { throw 'Incorrect staging image repository' }
    foreach ($name in @('MONGO_INITDB_ROOT_PASSWORD','MOFACTS_MONGO_APP_PASSWORD','MOFACTS_REDIS_PASSWORD','MOFACTS_SECURITY_AUDIT_INGEST_SECRET')) {
        if ($values[$name] -notmatch '^[A-Za-z0-9_-]{32,}$') { throw "Invalid URL-safe staging credential: $name" }
    }
    $settings = Get-Content -LiteralPath $StageSettingsPath -Raw | ConvertFrom-Json -AsHashtable
    if ($settings.ROOT_URL -ne $StageUrl) { throw 'Staging settings ROOT_URL mismatch' }
    $existingTag = $values['IMAGE_TAG']
    Remove-Variable settings, values
    Invoke-StagingSsh 'docker compose version >/dev/null' | Out-Null
    $commit = (git -C $MofactsRoot rev-parse HEAD).Trim()
    $short = (git -C $MofactsRoot rev-parse --short=12 HEAD).Trim()
    $dirty = [bool](git -C $MofactsRoot status --porcelain)
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddHHmmssZ')
    $tag = if ($dirty) { "staging-local-$stamp-$short" } else { "staging-$stamp-$short" }
    if ($DeployPublished) {
        $tag = $existingTag
        if ($tag -notmatch '^staging-(local-)?[0-9]{14}Z-[0-9a-f]{12}$') { throw 'Authoritative staging env does not identify a published staging tag' }
        $localRevision = (& docker image inspect "${ImageRepository}:$tag" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}').Trim()
        if ($localRevision -ne $commit) { throw 'Published image is not from the current local source commit' }
    }
    if ($commit -notmatch '^[0-9a-f]{40}$') { throw 'Cannot identify local source revision' }
    $oldTag = $env:IMAGE_TAG; $oldRevision = $env:MOFACTS_SOURCE_REVISION
    Push-Location (Join-Path $MofactsRoot 'deploy')
    try {
        $env:IMAGE_TAG = $tag; $env:MOFACTS_SOURCE_REVISION = $commit
        & docker compose --project-name mofacts-staging --env-file $StageEnvPath -f docker-compose.yml -f $OverlayPath config --quiet
        $effective = & docker compose --project-name mofacts-staging --env-file $StageEnvPath -f docker-compose.yml -f $OverlayPath config --format json | ConvertFrom-Json -AsHashtable
        if ($effective.services.mofacts.environment.ROOT_URL -ne $StageUrl -or
            $effective.services.mofacts.image -ne "${ImageRepository}:$tag" -or
            $effective.services.mofacts.container_name -ne 'mofacts-staging' -or
            $effective.services.mofacts.ports[0].host_ip -ne '127.0.0.1') { throw 'Process environment overrides the staging deployment boundary' }
        Remove-Variable effective
        if (!$DeployPublished) {
            & docker compose --project-name mofacts-staging --env-file $StageEnvPath -f docker-compose.yml build --no-cache mofacts
            & docker compose --project-name mofacts-staging --env-file $StageEnvPath -f docker-compose.yml push mofacts
        }
        $manifest = & docker buildx imagetools inspect "${ImageRepository}:$tag" --format '{{json .Manifest}}' | ConvertFrom-Json
        $digest = $manifest.digest
        if ($digest -notmatch '^sha256:[0-9a-f]{64}$') { throw 'No immutable staging image digest returned' }
        # Docker Desktop's containerd store exposes an OCI index as .Id, while
        # the server's Docker store exposes a platform config as .Id. Compare
        # registry digests across hosts, and runtime image IDs on the server.
        $localDigests = @(& docker image inspect "${ImageRepository}:$tag" --format '{{json .RepoDigests}}' | ConvertFrom-Json)
        if ($localDigests -notcontains "$ImageRepository@$digest") { throw 'Published digest does not match the locally built/pushed image' }
        $envText = Get-Content -LiteralPath $StageEnvPath -Raw
        $envText = [regex]::Replace($envText, '(?m)^IMAGE_TAG=.*$', "IMAGE_TAG=$tag")
        [IO.File]::WriteAllText($StageEnvPath, $envText, [Text.UTF8Encoding]::new($false))
        Invoke-StagingSsh 'test -s /srv/mofacts-staging/retired-site-archive.verified; test -d /srv/mofacts-staging/dynamic-assets; test -s /srv/mofacts-staging/overrides/memphis-saml-public-cert.pem; test -s /srv/mofacts-staging/overrides/memphis-saml-private-key.pem; install -d -o ubuntu -g ubuntu -m 700 /var/www/mofacts-staging; install -d -m 700 /etc/mofacts-staging /backups/mofacts-staging' | Out-Null
        # No compose down, volume deletion, old-container replacement, or production paths.
        Send-StagingFile './docker-compose.yml' '/var/www/mofacts-staging/docker-compose.yaml'
        Send-StagingFile $OverlayPath '/var/www/mofacts-staging/docker-compose.staging.yaml'
        Send-StagingFile $StageEnvPath '/var/www/mofacts-staging/.env'
        Send-StagingFile $StageSettingsPath '/var/www/mofacts-staging/settingsstaging.json'
        Send-StagingFile $ApachePath '/var/www/mofacts-staging/apache-tls.conf'
        Send-StagingFile $StageReplicaKey '/var/www/mofacts-staging/mongodb-keyfile.upload'
        foreach ($directory in @('mongo-init','mongodb')) {
            # These directories contain source only. MongoDB's entrypoint drops
            # to UID 999 before reading init files, so it must be able to traverse.
            Invoke-StagingSsh "install -d -o ubuntu -g ubuntu -m 755 /var/www/mofacts-staging/$directory" | Out-Null
            foreach ($file in Get-ChildItem -LiteralPath $directory -File) { Send-StagingFile $file.FullName "/var/www/mofacts-staging/$directory/$($file.Name)" }
        }
        Invoke-StagingSsh @"
cd /var/www/mofacts-staging
install -o root -g root -m 600 mongodb-keyfile.upload /etc/mofacts-staging/mongodb-keyfile
rm mongodb-keyfile.upload
chmod 600 .env settingsstaging.json
chmod 755 mongo-init mongodb
chmod 644 mongo-init/*.js mongodb/*.js
sed -i 's/\r$//' mongodb/*.sh
chmod 755 mongodb/*.sh
docker compose -p mofacts-staging --env-file .env -f docker-compose.yaml -f docker-compose.staging.yaml config --quiet
docker pull '$ImageRepository@$digest'
docker tag '$ImageRepository@$digest' '${ImageRepository}:$tag'
docker compose -p mofacts-staging --env-file .env -f docker-compose.yaml -f docker-compose.staging.yaml pull mongodb mongodb-replica-init redis
docker compose -p mofacts-staging --env-file .env -f docker-compose.yaml -f docker-compose.staging.yaml up -d --no-build --pull never --wait --wait-timeout 300
# The rollback below only recovers an Apache config/reload error; it does not
# claim to roll back the application or database after an acceptance failure.
cp /etc/apache2/sites-available/000-default-le-ssl.conf apache-tls.before.conf
install -m 644 apache-tls.conf /etc/apache2/sites-available/000-default-le-ssl.conf
if apache2ctl configtest && systemctl reload apache2; then :; else
  install -m 644 apache-tls.before.conf /etc/apache2/sites-available/000-default-le-ssl.conf
  apache2ctl configtest; systemctl reload apache2; exit 1
fi
"@ | Out-Null
        $record = @{
            url=$StageUrl; host=$StageHost; sourceCommit=$commit; includedUncommittedLocalChanges=$dirty;
            imageTag=$tag; imageDigest=$digest; deployedAtUtc=[DateTime]::UtcNow.ToString('o');
            status='awaiting-acceptance'; authenticatedReadiness='not-attested'; participantChecks='not-attested'
        }
    } finally {
        Pop-Location
        $env:IMAGE_TAG=$oldTag; $env:MOFACTS_SOURCE_REVISION=$oldRevision
    }
}
$record.imageId = Assert-StagingRelease $record
if (!$AcceptExisting) { $record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $RecordPath }
Write-Host "Staging image verified: $($record.imageTag) $($record.imageDigest)"
if ($DeferAcceptance) { Write-Host 'Deployed; authenticated readiness and participant acceptance remain pending. No accepted release record written.'; return }
Write-Host "Sign in as the configured administrator at $StageUrl/admin/tests and run Deployment Readiness. Every check must pass."
Write-Host 'Verify login, lesson upload/listing, practice response, reload/resume, data export, and dynamic media. Check SPARC/speech providers if used; this script does not copy localhost administrator provider keys.'
$acceptance = Read-Host "After all checks pass, enter VERIFIED $($record.imageTag)"
if ($acceptance -cne "VERIFIED $($record.imageTag)") { throw 'Staging acceptance not confirmed; no accepted release record written' }
$record.imageId = Assert-StagingRelease $record
$record.status='accepted'; $record.authenticatedReadiness='operator-confirmed'; $record.participantChecks='operator-confirmed'
$record.acceptedAtUtc=[DateTime]::UtcNow.ToString('o')
$record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $AcceptedPath
Write-Host "Accepted staging release recorded: $AcceptedPath"
