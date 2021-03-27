#! /usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

profile_path="/workspace/.config/profile.sh"

if [[ -r "$profile_path" ]]; then
  source "$profile_path"
else
  printf "%s\n" "File not found or readable: $profile_path."
  exit 1
fi
