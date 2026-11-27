#!/usr/bin/env bash
set -e

if [ -d /tmp/host-ssh ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  cp -rf /tmp/host-ssh/. "$HOME/.ssh/"
  chmod 600 "$HOME/.ssh/config" "$HOME/.ssh/id_"* 2>/dev/null || true
  chmod 644 "$HOME/.ssh/"*.pub "$HOME/.ssh/known_hosts" 2>/dev/null || true
fi
