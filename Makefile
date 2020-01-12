all:	check

check:
	if [ ! -e .bash_helpers.sh ]; then curl -kSL https://raw.githubusercontent.com/13pgeiser/bash/master/bash_helpers.sh -o .bash_helpers.sh ; fi
	docker run --rm -v "$(shell pwd)":/mnt mvdan/shfmt -d /mnt/setup.sh
	docker run --rm -e SHELLCHECK_OPTS="" -v "$(shell pwd)":/mnt koalaman/shellcheck:stable -x setup.sh

format:
	docker run --rm -v "$(shell pwd)":/mnt mvdan/shfmt -w /mnt/setup.sh

.PHONY: check format
