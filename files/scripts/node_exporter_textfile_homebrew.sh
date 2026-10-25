#!/bin/bash
# Writes Homebrew metrics for the node_exporter textfile collector.
# Deployed by tasks/node_exporter.yml, run hourly by a LaunchAgent.
# Usage: node_exporter_textfile_homebrew.sh <homebrew prefix> <textfile dir>
set -euo pipefail

prefix=$1
dir=$2
brew="$prefix/bin/brew"
jq="$prefix/bin/jq"

# No auto-update: the counts reflect the metadata of the last `brew update`
# (macupdate); homebrew_last_update_timestamp_seconds shows how old it is.
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1

json=$("$brew" outdated --json=v2 --greedy)
formulae=$("$jq" '.formulae | length' <<<"$json")
casks=$("$jq" '.casks | length' <<<"$json")
installed_formulae=$("$brew" list --formula -1 | wc -l | tr -d ' ')
installed_casks=$("$brew" list --cask -1 | wc -l | tr -d ' ')
last_update=$(stat -f %m "$("$brew" --repository)/.git/FETCH_HEAD" 2>/dev/null || echo 0)

# Write to a temp file in the same directory and rename it, so node_exporter
# never reads a half-written file. On failure the previous file stays and
# homebrew_textfile_last_run_timestamp_seconds stops advancing.
tmp=$(mktemp "$dir/.homebrew.prom.XXXXXX")
trap 'rm -f "$tmp"' EXIT
cat >"$tmp" <<EOF
# HELP homebrew_outdated_packages Outdated Homebrew packages (brew outdated --greedy).
# TYPE homebrew_outdated_packages gauge
homebrew_outdated_packages{type="formula"} $formulae
homebrew_outdated_packages{type="cask"} $casks
# HELP homebrew_installed_packages Installed Homebrew packages (brew list).
# TYPE homebrew_installed_packages gauge
homebrew_installed_packages{type="formula"} $installed_formulae
homebrew_installed_packages{type="cask"} $installed_casks
# HELP homebrew_last_update_timestamp_seconds Time of the last brew update (fetch of the Homebrew repository).
# TYPE homebrew_last_update_timestamp_seconds gauge
homebrew_last_update_timestamp_seconds $last_update
# HELP homebrew_textfile_last_run_timestamp_seconds Time this script last completed.
# TYPE homebrew_textfile_last_run_timestamp_seconds gauge
homebrew_textfile_last_run_timestamp_seconds $(date +%s)
EOF
chmod 0644 "$tmp"
mv "$tmp" "$dir/homebrew.prom"
trap - EXIT
