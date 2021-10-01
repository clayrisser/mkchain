# File: /main.mk
# Project: blackmagic
# File Created: 26-09-2021 16:53:36
# Author: Clay Risser
# -----
# Last Modified: 30-09-2021 21:56:13
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
# -----
#
# just a bit of black magic
#
# the magic of this makefile consists of functions and macros
# used to create complex cached dependency chains that track
# changes on individual files and works across unix environments
#
# for example, this can be used to format the code and run tests
# against only the files that updated
#
# this significantly increases the speed of builds and development in a
# language and ecosystem agnostic way without sacrificing enforcement of
# critical scripts and jobs
#
# an explanation of how this works is beyond the scope of this header
#
# - Clay Risser

export NO_INSTALL_DEPS ?= false
export BLACKMAGIC_CACHE ?= $(MKPM_TMP)/blackmagic
export _ACTIONS := $(BLACKMAGIC_CACHE)/actions
export _INSTALL_DEPS := $(BLACKMAGIC_CACHE)/install_deps
export _DEPS := $(BLACKMAGIC_CACHE)/deps
export _DONE := $(BLACKMAGIC_CACHE)/done
export _ENVS := $(BLACKMAGIC_CACHE)/envs
export ACTION := $(_DONE)

CD ?= cd
CUT ?= cut
ECHO ?= echo
TR ?= tr

.EXPORT_ALL_VARIABLES:

export GIT ?= $(call ternary,git --version,git,true)

IS_PROJECT_ROOT := false
ifeq ($(PROJECT_ROOT),$(ROOT))
	IS_PROJECT_ROOT := true
endif

export BLACKMAGIC_CLEAN := $(call rm_rf,$(BLACKMAGIC_CACHE)) $(NOFAIL)
export BLACKMAGIC_RESET_ENVS := $(call rm_rf,$(_ENVS)) $(NOFAIL)

define done
$(call reset_deps,$1)
$(call touch_m,$(_DONE)/$1)
$(call rm_rf,$(_DONE)/+$1) $(NOFAIL)
endef

define add_dep
echo $2 >> $(_DEPS)/$1
endef

define reset_deps
$(call rm_rf,$(_DEPS)/$1) $(NOFAIL)
endef

define get_deps
$(shell $(call cat,$(_DEPS)/$1) $(NOFAIL))
endef

define cache
$(call mkdir_p,$(shell echo $1 | $(SED) 's|\/[^\/]*$$||g')) && \
	$(call touch_m,$1)
endef

define clear_cache
$(call rm_rf,$1) $(NOFAIL)
endef

define deps
$(patsubst %,$(_DONE)/_$1/%,$2)
endef

define git_deps
$(call deps,$1,$(shell $(GIT) ls-files 2>$(NULL) | $(GREP) -E "$2" $(NOFAIL)))
endef

# POSIX >>>
define _ACTION_TEMPLATE
ifneq ($$({{ACTION_UPPER}}_READY),true)
{{ACTION_UPPER}}_READY = true
.PHONY: {{ACTION}} +{{ACTION}} _{{ACTION}} ~{{ACTION}} .{{ACTION}} ._{{ACTION}}
{{ACTION}}: _{{ACTION}} ~{{ACTION}}
~{{ACTION}}: | {{ACTION_DEPENDENCY}} $$({{ACTION_UPPER}}_DEPS) \
	$$({{ACTION_UPPER}}_TARGETS) $$(ACTION)/{{ACTION}}
+{{ACTION}}: | _{{ACTION}} $$({{ACTION_UPPER}}_DEPS) \
	$$({{ACTION_UPPER}}_TARGETS) $$(ACTION)/{{ACTION}}
_{{ACTION}}:
	@$$(call touch_m,$$(_DONE)/+{{ACTION}})
	@$$(call clear_cache,$$(_DONE)/_{{ACTION}})
	@$$(call clear_cache,$$(_DONE)/{{ACTION}})
$$(_DONE)/_{{ACTION}}/%: %
	@$$(call clear_cache,$$(_DONE)/{{ACTION}})
	@$$(call add_dep,{{ACTION}},$$<)
	@$$(call cache,$$@)
.{{ACTION}}: | _{{ACTION}} $$({{ACTION_UPPER}}_DEPS)
	@echo {{ACTION}}$$$$(echo {{ACTION_DEPENDENCY}} | $(SED) "s|^~| \< |g"): $$({{ACTION_UPPER}}_TARGETS)
	@[ "$$(call get_deps,two)" = "" ] && true || \
		(printf "    " && (echo $$(call get_deps,two) | $(SED) "s| |\\n    |g"))
	@$$(call done,two)
endif
endef
# <<< POSIX

define actions
$(patsubst %,$(_ACTIONS)/%,$(ACTIONS))
endef

define parent_dir
$(shell $(ECHO) $1 | $(SED) -E "s|\/[^\/]*$$||g")
endef

define ensure_parent_dir
$(call mkdir_p,$(call parent_dir,$1))
endef

.PHONY: $(_ACTIONS)/%
$(_ACTIONS)/%:
	@$(call ensure_parent_dir,$@)
# POSIX >>>
	@ACTION_BLOCK=$(shell $(ECHO) $@ | $(GREP) -oE "[^\/]+$$") && \
		ACTION=$$($(ECHO) $$ACTION_BLOCK | $(GREP) -oE "^[^~]+") && \
		ACTION_DEPENDENCY=$$($(ECHO) $$ACTION_BLOCK | $(GREP) -Eo "~[^~]+$$" $(NOFAIL)) && \
		CHILD_ACTION_DEPENDENCY=$$([ "$$ACTION_DEPENDENCY" = "" ] && $(ECHO) "" || $(ECHO) "child_$$ACTION_DEPENDENCY") && \
		ACTION_UPPER=$$($(ECHO) $$ACTION | $(TR) '[:lower:]' '[:upper:]') && \
		$(ECHO) "$${_ACTION_TEMPLATE}" | $(SED) "s|{{ACTION}}|$${ACTION}|g" | \
		$(SED) "s|{{ACTION_DEPENDENCY}}|$${ACTION_DEPENDENCY}|g" | \
		$(SED) "s|{{CHILD_ACTION_DEPENDENCY}}|$${CHILD_ACTION_DEPENDENCY}|g" | \
		$(SED) "s|{{ACTION_UPPER}}|$${ACTION_UPPER}|g" > $@
# <<< POSIX

-include $(_DEPS)/_
$(_DEPS)/_:
	@$(call mkdir_p,$(_DEPS))
	@$(call touch,$@)
-include $(_DONE)/_
$(_DONE)/_:
	@$(call mkdir_p,$(_DONE))
	@$(call touch,$@)

-include $(_ENVS)
$(_ENVS): $(PROJECT_ROOT)/main.mk $(ROOT)/Makefile
	@$(ECHO) 🗲  make will be faster next time
	@$(call rm_rf,$@) $(NOFAIL)
# POSIX >>>
	@$(call for,e,$$CACHE_ENVS) \
			$(ECHO) "export $(call for_i,e) := $$(eval "echo \$$$(call for_i,e)")" >> $@ \
		$(call for_end)
# <<< POSIX

-include $(_INSTALL_DEPS)
$(_INSTALL_DEPS): $(PROJECT_ROOT)/main.mk $(ROOT)/Makefile
	@$(call ensure_parent_dir,$(_INSTALL_DEPS))
ifneq ($(NO_INSTALL_DEPS),true)
	@$(ECHO) 🔌 installing dependencies
	@$(TRUE) $(INSTALL_DEPS_SCRIPT)
	@$(BLACKMAGIC_CLEAN)
	@$(ECHO) 💣 busted cache
endif
	@$(call ensure_parent_dir,$(_INSTALL_DEPS))
	@$(call touch_m,$(_INSTALL_DEPS))

CACHE_ENVS += \
	GIT

.PHONY: +%
+%:
	@$(MAKE) -s $(shell echo $@ | $(SED) 's|^\+||g')
