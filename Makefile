.DEFAULT_GOAL:=help

.PHONY: check  ## Check terraform format recursively.
check:
	terraform fmt -check -recursive

.PHONY: format ## Auto-format terraform files recursively.
format:
	terraform fmt -recursive


.PHONY: help  ## Display this message
help:
	@grep -E \
		'^.PHONY: .*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ".PHONY: |## "}; {printf "\033[36m%-19s\033[0m %s\n", $$2, $$3}'