#!/bin/bash
#
# Quick and dirty signer
#

set -e

echo "${GPG_STAGINGPRODUCTION_SIGNING_KEY}" | gpg --import
exec debsign -kAE9382E7F07D8B288BC836C16210FA9A8BA0CF15 *.changes
