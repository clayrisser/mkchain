# File: /mkpm.mk
# Project: mkchain
# File Created: 27-09-2021 16:33:44
# Author: Clay Risser
# -----
# Last Modified: 11-01-2022 02:43:50
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

MKPM_PKG_NAME := mkchain

MKPM_PKG_VERSION := 0.0.13

MKPM_PKG_DESCRIPTION := "chained actions for makefiles"

MKPM_PKG_AUTHOR := Clay Risser <clayrisser@gmail.com>

MKPM_PKG_SOURCE := https://gitlab.com/bitspur/community/mkchain.git

MKPM_PKG_FILES_REGEX :=

MKPM_PACKAGES := \

MKPM_REPOS := \

############# MKPM BOOTSTRAP SCRIPT BEGIN #############
MKPM_BOOTSTRAP := https://bitspur.gitlab.io/community/mkpm/bootstrap.mk
export PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
NULL := /dev/null
TRUE := true
ifneq ($(patsubst %.exe,%,$(SHELL)),$(SHELL))
	NULL = nul
	TRUE = type nul
endif
-include $(PROJECT_ROOT)/.mkpm/.bootstrap.mk
$(PROJECT_ROOT)/.mkpm/.bootstrap.mk: bootstrap.mk
	@mkdir .mkpm 2>$(NULL) || $(TRUE)
ifeq ($(OS),Windows_NT)
	@type $< > $@
else
	@cp $< $@
endif
############## MKPM BOOTSTRAP SCRIPT END ##############
