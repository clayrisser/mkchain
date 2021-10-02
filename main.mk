# File: /main.mk
# Project: blackmagic
# File Created: 26-09-2021 16:53:36
# Author: Clay Risser
# -----
# Last Modified: 02-10-2021 02:19:37
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

.NOTPARALLEL:

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

IS_PROJECT_ROOT := true
IS_SUB := false
ifneq ($(PROJECT_ROOT),$(ROOT))
	IS_PROJECT_ROOT := false
endif
ifneq ($(ROOT),$(shell pwd))
	IS_PROJECT_ROOT := false
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
ifeq ($$(IS_PROJECT_ROOT),true)
ifneq ($$({{ACTION_UPPER}}_READY),true)
{{ACTION_UPPER}}_READY = true
.PHONY: {{ACTION}} +{{ACTION}} _{{ACTION}} ~{{ACTION}} .{{ACTION}} ._{{ACTION}}
.DELETE_ON_ERROR: $$(ACTION)/{{ACTION}}
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
	@[ "$$(call get_deps,{{ACTION}})" = "" ] && true || \
		(printf "    " && (echo $$(call get_deps,{{ACTION}}) | $(SED) "s| |\\n    |g"))
	@$$(call done,{{ACTION}})
endif
else
ifneq ($$({{ACTION_UPPER}}_READY),true)
SUB_{{ACTION_UPPER}}_READY = true
.PHONY: sub_{{ACTION}} sub_+{{ACTION}} sub__{{ACTION}} sub_~{{ACTION}}
sub_{{ACTION}}: sub__{{ACTION}} sub_~{{ACTION}}
sub_~{{ACTION}}: | {{SUB_ACTION_DEPENDENCY}} $$({{ACTION_UPPER}}_DEPS) \
	$$({{ACTION_UPPER}}_TARGETS) $$(ACTION)/{{ACTION}}
sub_+{{ACTION}}: | sub__{{ACTION}} $$({{ACTION_UPPER}}_DEPS) \
	$$({{ACTION_UPPER}}_TARGETS) $$(ACTION)/{{ACTION}}
_{{ACTION}}:
	@$$(call touch_m,$$(_DONE)/+{{ACTION}})
	@$$(call clear_cache,$$(_DONE)/_{{ACTION}})
	@$$(call clear_cache,$$(_DONE)/{{ACTION}})
$$(_DONE)/_{{ACTION}}/%: %
	@$$(call clear_cache,$$(_DONE)/{{ACTION}})
	@$$(call add_dep,{{ACTION}},$$<)
	@$$(call cache,$$@)
endif
endif
endef
# <<< POSIX

define actions
$(patsubst %,$(_ACTIONS)/%,$(ACTIONS))
endef

.PHONY: $(_ACTIONS)/%
$(_ACTIONS)/%:
	@$(call mkdir_p,$(@D))
# POSIX >>>
	@ACTION_BLOCK=$(shell $(ECHO) $@ | $(GREP) -oE "[^\/]+$$") && \
		ACTION=$$($(ECHO) $$ACTION_BLOCK | $(GREP) -oE "^[^~]+") && \
		ACTION_DEPENDENCY=$$($(ECHO) $$ACTION_BLOCK | $(GREP) -Eo "~[^~]+$$" $(NOFAIL)) && \
		SUB_ACTION_DEPENDENCY=$$([ "$$ACTION_DEPENDENCY" = "" ] && $(ECHO) "" || $(ECHO) "sub_$$ACTION_DEPENDENCY") && \
		ACTION_UPPER=$$($(ECHO) $$ACTION | $(TR) '[:lower:]' '[:upper:]') && \
		$(ECHO) "$${_ACTION_TEMPLATE}" | $(SED) "s|{{ACTION}}|$${ACTION}|g" | \
		$(SED) "s|{{ACTION_DEPENDENCY}}|$${ACTION_DEPENDENCY}|g" | \
		$(SED) "s|{{SUB_ACTION_DEPENDENCY}}|$${SUB_ACTION_DEPENDENCY}|g" | \
		$(SED) "s|{{ACTION_UPPER}}|$${ACTION_UPPER}|g" > $@
# <<< POSIX

-include $(_DEPS)/_
$(_DEPS)/_:
	@$(call mkdir_p,$(@D))
	@$(call touch,$@)
-include $(_DONE)/_
$(_DONE)/_:
	@$(call mkdir_p,$(@D))
	@$(call touch,$@)

-include $(_ENVS)
$(_ENVS): $(call join_path,$(PROJECT_ROOT),main.mk) $(call join_path,$(ROOT),Makefile)
	@$(ECHO) 🗲  make will be faster next time
	@$(call rm_rf,$@) $(NOFAIL)
# POSIX >>>
	@$(call for,e,$$CACHE_ENVS) \
			$(ECHO) "export $(call for_i,e) := $$(eval "echo \$$$(call for_i,e)")" >> $@ \
		$(call for_end)
# <<< POSIX

-include $(_INSTALL_DEPS)
$(_INSTALL_DEPS): $(call join_path,$(PROJECT_ROOT),main.mk) $(call join_path,$(ROOT),Makefile)
ifneq ($(NO_INSTALL_DEPS),true)
	@$(ECHO) 🔌 installing dependencies
	@$(TRUE) $(INSTALL_DEPS_SCRIPT)
	@$(BLACKMAGIC_CLEAN)
	@$(ECHO) 💣 busted cache
endif
	@$(call mkdir_p,$(@D))
	@$(call touch_m,$(@))

CACHE_ENVS += \
	GIT

.PHONY: +%
+%:
	@$(MAKE) -s $(shell echo $@ | $(SED) 's|^\+||g')
