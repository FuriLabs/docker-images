#!/bin/bash
#
# Quick and dirty deployer
#

if [ "${CIRCLECI}" == "true" ]; then
	# CircleCI

	BRANCH="${CIRCLE_BRANCH}"
	COMMIT="${CIRCLE_SHA1}"
	PROJECT_SLUG="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
	if [ -n "${CIRCLE_TAG}" ]; then
		TAG="${CIRCLE_TAG}"
	fi
else
	# Sorry
	echo "This script runs only on CircleCI"
	exit 1
fi

# Load SSH KEY
echo "Loading SSH key"
mkdir -p ~/.ssh

wget -q "${INTAKE_SSH_KEY}"

eval $(ssh-agent -s)
ssh-add <(cat $(basename "${INTAKE_SSH_KEY}")) &> /dev/null

# Push fingerprint (this must be changed manually)
cat > ~/.ssh/known_hosts <<EOF
# repo.furilabs.com:22 SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u2
repo.furilabs.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2/ShuoIqfJ26fouqJDG68sZeeYKFwR/GBUxadu0bUfqbsSrG37jLXz+vRei+Qeq8u0YRfe84A7v8K+yqq5pWlNDSXype35F6CJ7ts59tKWQlK7sXUYenXGbJ1PxibXlrRLxXgV/eb+GV6c8ko2vWMXmhLYnr9glKTuSmBVf94ylJUVXFvJeDsfVU4Gh92m5n4bVFxGGXAbQvAlE6foc3jHbN9BLfq08zcXCZC+xSwWeILnCSP2U1yimTagQ75+1YMWmxWarf1XFILVZARaC2U4XUuxUAAbi4uqv/z8Y9h4OoKmcWBw6yJwx856x2GdtMjsrFbz6azP7sCyHXw6KodCx7F/PWftjsiu2bfghwu7SSvMI933BDRHyC6INszlVzgUw9eQr/vMmSR/o/EsgcymwY8zxkQPCaEmhcrkI+fBgnrHxxU6hgwbsfvKNKmoFjJz1wOQ6uCWkssCvR1wJJNvnBlZYEY2Y2iJY1D9pm2QB89WJleurU6WBM3rsXt5Dk=
# repo.furilabs.com:22 SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u2
repo.furilabs.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBU8PvkjrCI+mtPEVYImq7Jj4hgv/57zaStBBGrkkfw2Pmx2YlVg/nASNoogPERM3SvWTLU+BJcRnuvR1T3ZjYY=
# repo.furilabs.com:22 SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u2
repo.furilabs.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFytZKxTLB74+kDVg5Sv8TksaSNpKL5OCscI/PQ4r237
EOF

# Determine target.
echo "Determining target"
if [ -n "${TAG}" ]; then
	# Tag, should go to production
	TARGET="production"
elif [[ ${BRANCH} = feature/* ]]; then
	# Feature branch
	_project=${PROJECT_SLUG//\//-}
	_project=${_project//_/-}
	_branch=${BRANCH/feature\//}
	_branch=${_branch//./-}
	_branch=${_branch//_/-}
	_branch=${_branch//\//-}
	TARGET=$(echo ${_project}-${_branch} | tr '[:upper:]' '[:lower:]')
else
	# Staging
	TARGET="staging"
fi

echo "Chosen target is ${TARGET}"

echo "Uploading data"
find /tmp/buildd-results/ \
	-maxdepth 1 \
	-regextype posix-egrep \
	-regex "/tmp/buildd-results/.*\.(u?deb|tar\..*|dsc|buildinfo)$" \
	-print0 \
	| xargs -0 -i rsync --perms --chmod=D770,F770 --progress {} ${INTAKE_SSH_USER}@repo.furilabs.com:./${TARGET}/

echo "Uploading .changes"
find /tmp/buildd-results/ \
	-maxdepth 1 \
	-regextype posix-egrep \
	-regex "/tmp/buildd-results/.*\.changes$" \
	-print0 \
	| xargs -0 -i rsync --perms --chmod=D770,F770 --progress {} ${INTAKE_SSH_USER}@repo.furilabs.com:./${TARGET}/
