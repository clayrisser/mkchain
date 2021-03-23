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

PLATFORM := $(shell node -e "process.stdout.write(process.platform)")

ifeq ($(PLATFORM),win32)
  BANG ?= !
	MAKE ?= make
	NULL ?= nul
	SHELL ?= cmd.exe
	GREP ?= grep
	SED ?= sed
else
	BANG ?= \!
	NULL ?= /dev/null
	SHELL ?= $(shell bash --version >$(NULL) 2>&1 && echo bash|| echo sh)
ifeq ($(PLATFORM),darwin)
	GREP ?= ggrep
	SED ?= gsed
else
	GREP ?= grep
	SED ?= sed
endif
endif
ifeq ($(PLATFORM),linux)
	NUMPROC ?= $(shell grep -c ^processor /proc/cpuinfo)
endif
ifeq ($(PLATFORM),darwin)
	NUMPROC ?= $(shell sysctl hw.ncpu | awk '{print $$2}')
endif
export NUMPROC ?= 1
MAKEFLAGS += "-j $(NUMPROC)"

CWD := $(shell pwd)
export CD ?= cd
export GIT ?= $(shell git --version >$(NULL) 2>&1 && echo git|| echo true)
export NOFAIL := 2>$(NULL)|| true

.EXPORT_ALL_VARIABLES:

export PROJECT_ROOT ?= $(shell $(GIT) rev-parse --show-superproject-working-tree)
ifeq ($(PROJECT_ROOT),)
	PROJECT_ROOT := $(shell $(GIT) rev-parse --show-toplevel)
endif
ifeq ($(PROJECT_ROOT),)
	PROJECT_ROOT := $(CWD)
endif

CHILD := false
ifneq ($(PROJECT_ROOT),$(CWD))
ifeq ($(PARENT),true)
	CHILD := true
endif
endif

export MAKE_CACHE ?= $(CWD)/.make
export _ACTIONS := $(MAKE_CACHE)/actions
export DONE := $(MAKE_CACHE)/done
export DEPS := $(MAKE_CACHE)/deps
export ACTION := $(DONE)

_RUN := $(shell mkdir -p $(_ACTIONS) $(DEPS) $(DONE))

define done
	$(call reset_deps,$1)
	touch -m $(DONE)/$1
endef

define add_dep
	echo $2 >> $(DEPS)/$1
endef

define reset_deps
	rm -f $(DEPS)/$1 $(NOFAIL)
endef

define get_deps
	cat $(DEPS)/$1 $(NOFAIL)
endef

define cache
	mkdir -p $$(echo $1 | $(SED) 's/\/[^\/]*$$//g') && touch -m $1
endef

define clear_cache
	rm -rf $1 $(NOFAIL)
endef

define deps
	$(patsubst %,$(DONE)/_$1/%,$2)
endef

define clean
	rm -rf $(MAKE_CACHE) $(NOFAIL)
endef

define ACTION_TEMPLATE
ifeq ($$(CHILD),true)
ifneq ($$(CHILD_{{ACTION_UPPER}}_READY),true)
CHILD_{{ACTION_UPPER}}_READY = true
.PHONY: child_{{ACTION}} child_+{{ACTION}} child__{{ACTION}} child_~{{ACTION}}
child_{{ACTION}}: child__{{ACTION}} child_~{{ACTION}}
child_~{{ACTION}}: child_{{ACTION_DEPENDENCY}} $$({{ACTION_UPPER}}_TARGET)
child_+{{ACTION}}: child__{{ACTION}} $$({{ACTION_UPPER}}_TARGET)
child__{{ACTION}}:
	@$$(call clear_cache,$$(DONE)/{{ACTION}})
$$(DONE)/_{{ACTION}}/%: %
	@$$(call clear_cache,$$(DONE)/{{ACTION}})
	@$$(call add_dep,{{ACTION}},$$<)
	@$$(call cache,$$@)
endif
else
ifneq ($$({{ACTION_UPPER}}_READY),true)
{{ACTION_UPPER}}_READY = true
.PHONY: {{ACTION}} +{{ACTION}} _{{ACTION}} ~{{ACTION}}
{{ACTION}}: _{{ACTION}} ~{{ACTION}}
~{{ACTION}}: {{ACTION_DEPENDENCY}} $$({{ACTION_UPPER}}_TARGET)
+{{ACTION}}: _{{ACTION}} $$({{ACTION_UPPER}}_TARGET)
_{{ACTION}}:
	@$$(call clear_cache,$$(DONE)/{{ACTION}})
$$(DONE)/_{{ACTION}}/%: %
	@$$(call clear_cache,$$(DONE)/{{ACTION}})
	@$$(call add_dep,{{ACTION}},$$<)
	@$$(call cache,$$@)
endif
endif
endef

.PHONY: $(_ACTIONS)/%
$(_ACTIONS)/%:
	@ACTION_BLOCK=$(shell echo $@ | $(GREP) -oE '[^\/]+$$') && \
		ACTION=$$(echo $$ACTION_BLOCK | $(GREP) -oE '^[^~]+') && \
		ACTION_DEPENDENCY=$$(echo $$ACTION_BLOCK | $(GREP) -oE '~[^~]+$$' $(NOFAIL)) && \
		ACTION_UPPER=$$(echo $$ACTION | tr '[:lower:]' '[:upper:]') && \
		echo "$${ACTION_TEMPLATE}" | $(SED) "s/{{ACTION}}/$${ACTION}/g" | \
		$(SED) "s/{{ACTION_DEPENDENCY}}/$${ACTION_DEPENDENCY}/g" | \
		$(SED) "s/{{ACTION_UPPER}}/$${ACTION_UPPER}/g" > $@
