#!/bin/bash
#
# Quick and dirty signer
#

set -e

wget -q "${GPG_STAGINGPRODUCTION_SIGNING_KEY}"

cat $(basename "${GPG_STAGINGPRODUCTION_SIGNING_KEY}") | gpg --import --batch
exec debsign -k97E5FB897E9B94B4E3ED94966261FCC7EE607820 *.changes
