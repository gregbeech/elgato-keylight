#!/bin/bash

set eo -pipefail

lights=('192.168.0.203' '192.168.0.204')

function toggle_light() {
  local on="$1"
  local ip="$2"

  curl --silent --location --request GET "http://${ip}:9123/elgato/lights" --header 'Accept: application/json' | \
  jq -crM ".lights[0].on = ${on}" 2>&1 | \
  curl --silent --location --request PUT "http://${ip}:9123/elgato/lights" --header 'Content-Type: application/json' -d @- | \
  > /dev/null
}

function toggle_lights() {
  local on="$1"

  echo "[$(date +"%Y-%m-%d %H:%M:%S")] lights on = ${on}"
  for light in "${lights[@]}"; do
    toggle_light "$1" "${light}" &
  done
}

if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Install using Homebrew?"
  read -p "Continue? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
  brew install jq
fi

log stream --predicate 'subsystem == "com.apple.UVCExtension" and composedMessage contains "Post PowerLog"' | \
while read line; do
  case "${line}" in
    *"= On"*)
      toggle_lights 1
      ;;
    *"= Off"*)
      toggle_lights 0
      ;;
  esac
done
