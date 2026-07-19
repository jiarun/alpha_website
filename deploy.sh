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
#   DEPLOY_REF           Git ref to deploy, defaults to HEAD
#   WEBSITE_DIR          Website directory in the repo, defaults to website
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

WEBSITE_DIR="${WEBSITE_DIR:-website}"
DEPLOY_REF="${DEPLOY_REF:-HEAD}"
REMOTE_DIR="${CPANEL_REMOTE_DIR:-public_html/alphary.org}"
FTP_PORT="${CPANEL_FTP_PORT:-21}"
FTP_SSL="${CPANEL_FTP_SSL:-true}"
DRY_RUN=false
DEPLOY_SOURCE=""

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

WEBSITE_PATH="${WEBSITE_DIR#./}"
WEBSITE_PATH="${WEBSITE_PATH%/}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to deploy files from the latest commit." >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "deploy.sh must be run from inside the Git repository." >&2
  exit 1
fi

if ! git cat-file -e "$DEPLOY_REF:$WEBSITE_PATH" 2>/dev/null; then
  echo "Website directory not found in $DEPLOY_REF: $WEBSITE_PATH" >&2
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

prepare_deploy_source() {
  DEPLOY_SOURCE="$(mktemp -d)"
  git archive --format=tar "$DEPLOY_REF:$WEBSITE_PATH" | tar -x -C "$DEPLOY_SOURCE"
}

cleanup() {
  if [[ -n "$DEPLOY_SOURCE" && -d "$DEPLOY_SOURCE" ]]; then
    rm -rf "$DEPLOY_SOURCE"
  fi
}
trap cleanup EXIT

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Running dry run. No files will be uploaded, changed, or deleted."
  echo "Checking FTP login and remote directory: $REMOTE_DIR"
  echo "Deploy source would be $WEBSITE_PATH from commit $(git rev-parse --short "$DEPLOY_REF")."

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

prepare_deploy_source

echo "Deploying $WEBSITE_PATH from commit $(git rev-parse --short "$DEPLOY_REF") to $CPANEL_FTP_HOST:$REMOTE_DIR ..."

lftp <<LFTP_COMMANDS
set cmd:fail-exit yes
set ssl:verify-certificate no
$SSL_SETTING
set ftp:list-options -a
open -u "$CPANEL_FTP_USER","$CPANEL_FTP_PASSWORD" -p "$FTP_PORT" "$CPANEL_FTP_HOST"
mirror --reverse --delete "$DEPLOY_SOURCE" "$REMOTE_DIR"
bye
LFTP_COMMANDS

echo "Deployment complete."
