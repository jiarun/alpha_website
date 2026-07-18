#!/usr/bin/env bash
set -euo pipefail

# Deploy the static website folder to GoDaddy/cPanel over FTP or FTPS.
#
# Required environment variables:
#   CPANEL_FTP_HOST      FTP host, for example ftp.example.com
#   CPANEL_FTP_USER      cPanel/FTP username
#   CPANEL_FTP_PASSWORD  cPanel/FTP password
#
# Optional environment variables:
#   CPANEL_REMOTE_DIR    Remote directory, defaults to public_html/alphary.org
#   CPANEL_FTP_PORT      FTP port, defaults to 21
#   CPANEL_FTP_SSL       true/false, defaults to true
#
# Usage:
#   ./deploy.sh
#   ./deploy.sh --dry-run

if [[ -f ".env.deploy" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env.deploy"
  set +a
fi

WEBSITE_DIR="${WEBSITE_DIR:-./website}"
REMOTE_DIR="${CPANEL_REMOTE_DIR:-public_html/alphary.org}"
FTP_PORT="${CPANEL_FTP_PORT:-21}"
FTP_SSL="${CPANEL_FTP_SSL:-true}"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
elif [[ $# -gt 0 ]]; then
  echo "Usage: ./deploy.sh [--dry-run]" >&2
  exit 1
fi

required_vars=(CPANEL_FTP_HOST CPANEL_FTP_USER CPANEL_FTP_PASSWORD)
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing required environment variable: $var" >&2
    echo "Create .env.deploy from .env.deploy.example, then run ./deploy.sh" >&2
    exit 1
  fi
done

if [[ ! -d "$WEBSITE_DIR" ]]; then
  echo "Website directory not found: $WEBSITE_DIR" >&2
  exit 1
fi

if ! command -v lftp >/dev/null 2>&1; then
  echo "lftp is required for FTP sync." >&2
  echo "Install it with: brew install lftp" >&2
  exit 1
fi

if [[ "$FTP_SSL" == "true" ]]; then
  SSL_SETTING="set ftp:ssl-force true; set ftp:ssl-protect-data true;"
else
  SSL_SETTING="set ftp:ssl-force false; set ftp:ssl-protect-data false;"
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Running dry run. No files will be uploaded, changed, or deleted."
  echo "Checking FTP login and remote directory: $REMOTE_DIR"

  lftp <<LFTP_COMMANDS
set cmd:fail-exit yes
set ssl:verify-certificate no
$SSL_SETTING
open -u "$CPANEL_FTP_USER","$CPANEL_FTP_PASSWORD" -p "$FTP_PORT" "$CPANEL_FTP_HOST"
cd "$REMOTE_DIR"
bye
LFTP_COMMANDS

  echo "Dry run complete. FTP login and remote directory are accessible."
  exit 0
fi

echo "Deploying $WEBSITE_DIR to $CPANEL_FTP_HOST:$REMOTE_DIR ..."

lftp <<LFTP_COMMANDS
set cmd:fail-exit yes
set ssl:verify-certificate no
$SSL_SETTING
set ftp:list-options -a
open -u "$CPANEL_FTP_USER","$CPANEL_FTP_PASSWORD" -p "$FTP_PORT" "$CPANEL_FTP_HOST"
mirror --reverse --delete "$WEBSITE_DIR" "$REMOTE_DIR"
bye
LFTP_COMMANDS

echo "Deployment complete."
