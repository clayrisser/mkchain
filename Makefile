# File: /Makefile
# Project: blackmagic
# File Created: 26-09-2021 16:53:36
# Author: Clay Risser
# -----
# Last Modified: 02-10-2021 10:00:31
# Modified By: Clay Risser
# -----
# BitSpur Inc (c) Copyright 2021
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include mkpm.mk
ifneq (,$(MKPM))
include main.mk

PACK_DIR := $(MKPM_TMP)/pack

.PHONY: zero
zero: ;

ACTIONS += one
ONE_TARGETS := zero
$(ACTION)/one:
	@echo one
	@$(call done,one)

ACTIONS += two~one
$(ACTION)/two: $(call git_deps,two,\.((mk)|(md))$$)
	@echo two
	@echo $?
	@$(call done,two)

ACTIONS += three~two
$(ACTION)/three:
	@echo three
	@$(MAKE) -s -C sub three
	@$(call done,three)

.PHONY: info
info:
	@echo IS_PROJECT_ROOT: $(IS_PROJECT_ROOT)
	@echo MAKELEVEL: $(MAKELEVEL)
	@echo CURDIR: $(CURDIR)
	@echo PROJECT_ROOT: $(PROJECT_ROOT)
	@echo ROOT: $(ROOT)
	@echo
	@$(MAKE) -s -C sub info

.PHONY: pack
pack:
	@rm -rf $(PACK_DIR) $(NOFAIL) && mkdir -p $(PACK_DIR)
	@cp main.mk $(PACK_DIR)
	@cp mkpm.mk $(PACK_DIR)
	@cp LICENSE $(PACK_DIR) $(NOFAIL)
	@for f in $(shell [ "$(MKPM_FILES_REGEX)" = "" ] || \
		$(FIND) . -type f -not -path './.git/*' | $(SED) 's|^\.\/||g' | \
		$(GREP) -E "$(MKPM_FILES_REGEX)") \
		$(shell $(GIT) ls-files | $(GREP) -E "^README[^\/]*$$"); do \
			PARENT_DIR=$$(echo $$f | $(SED) 's|[^\/]\+$$||g' | $(SED) 's|\/$$||g') && \
			([ "$$PARENT_DIR" != "" ] && mkdir -p $(PACK_DIR)/$$PARENT_DIR || true) && \
			cp $$f $(PACK_DIR)/$$f; \
		done
	@tar -cvzf $(MKPM_PKG_NAME).tar.gz -C $(PACK_DIR) .

.PHONY: publish
publish: pack

.PHONY: sudo
sudo:
	@sudo true

.PHONY: clean
clean:
	@$(BLACKMAGIC_CLEAN)
	@$(GIT) clean -fXd \
		$(MKPM_GIT_CLEAN_FLAGS)

.PHONY: purge
purge: clean
	@$(GIT) clean -fXd

-include $(call actions)

endif

INSTALL_DEPS_SCRIPT += && \
	true
