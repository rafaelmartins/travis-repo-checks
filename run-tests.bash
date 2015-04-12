#!/bin/bash
set -e -x

# semaphore does not creates a virtualenv for us
sudo apt-get install -y python-virtualenv python-dev
virtualenv ~/.venv
source ~/.venv/bin/activate

JOB=${1}
NO_JOBS=${2}

if [[ ! ${JOB} || ! ${NO_JOBS} ]]; then
	# simple whole-repo run
	pkgcheck -r gentoo --reporter FancyReporter \
		-d imlate -d unstable_only -d cleanup -d stale_unstable \
		--profile-disable-dev --profile-disable-exp
elif [[ ${JOB} == global ]]; then
	# global check part of split run
	pkgcheck -r gentoo --reporter FancyReporter \
		-c UnusedGlobalFlags -c UnusedLicense
else
	# keep the category scan silent, it's so loud...
	set +x
	cx=0
	cats=()
	for c in $(<profiles/categories); do
		if [[ $(( cx++ % ${NO_JOBS} )) -eq ${JOB} ]]; then
			cats+=( "${c}/*" )
		fi
	done
	set -x

	pkgcheck -r gentoo --reporter FancyReporter "${cats[@]}" \
		-d imlate -d unstable_only -d cleanup -d stale_unstable \
		--profile-disable-dev --profile-disable-exp
fi |& awk -f "$(dirname "${0}")"/parse-pcheck-output.awk

[[ ${PIPESTATUS[0]} == 0 ]]
