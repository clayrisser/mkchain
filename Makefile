include blackmagic.mk
include mkpm.mk

FIND := find
TMP := $(MKPM)/.tmp
ACTIONS += hello
HELLO_DEPS :=
HELLO_TARGET := $(HELLO_DEPS) $(ACTION)/hello
$(ACTION)/hello:
	@echo world

.PHONY: lfs
ifeq ($(shell $(GIT) lfs $(NOOUT) && echo true || echo false),true)
lfs:
else
ifeq ($(PLATFORM),linux)
ifeq ($(FLAVOR),debian)
lfs: sudo
	@sudo apt-get install -y git-lfs
	@git lfs install
endif
endif
ifeq ($(PLATFORM),darwin)
lfs:
	@brew install git-lfs
	@git lfs install
endif
endif
ifneq ($(shell cat .gitattributes 2>$(NULL) | $(GREP) -q '*.tar.gz' $(NOOUT) && echo true || echo false),true)
	@$(GIT) lfs track "*.tar.gz"
endif

.PHONY: pack
pack:
	@rm -rf $(TMP) $(NOFAIL) && mkdir -p $(TMP)
	@cp main.mk $(TMP)
	@cp mkpm.mk $(TMP)
	@cp LICENSE $(TMP) $(NOFAIL)
	@for f in $(shell [ "$(MKPM_FILES_REGEX)" = "" ] || \
		$(FIND) . -type f -not -path './.git/*' | $(SED) 's|^\.\/||g' | \
		$(GREP) -E "$(MKPM_FILES_REGEX)") \
		$(shell $(GIT) ls-files | $(GREP) -E "^README[^\/]*$$"); do \
			PARENT_DIR=$$(echo $$f | $(SED) 's|[^\/]\+$$||g' | $(SED) 's|\/$$||g') && \
			([ "$$PARENT_DIR" != "" ] && mkdir -p $(TMP)/$$PARENT_DIR || true) && \
			cp $$f $(TMP)/$$f; \
		done
	@tar -cvzf $(MKPM_NAME).mkpm.tar.gz -C $(TMP) .

.PHONY: publish
publish: pack
	@$(GIT) add $(MKPM_NAME)/$(MKPM_NAME).tar.gz
	@$(GIT) commit $(MKPM_NAME).tar.gz -m "Publish $(MKPM_NAME) version $(MKPM_VERSION)" $(NOFAIL)
	@$(GIT) tag $(MKPM_NAME)/$(MKPM_VERSION)
	@$(GIT) push && $(GIT) push --tags

.PHONY: sudo
sudo:
	@sudo true

-include $(patsubst %,$(_ACTIONS)/%,$(ACTIONS))

+%:
	@$(MAKE) -e -s $(shell echo $@ | $(SED) 's/^\+//g')

%:
	@echo $@ is not a valid command && exit 1
