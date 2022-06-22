# File: /sub/Makefile
# Project: mkchain
# File Created: 01-10-2021 01:51:21
# Author: Clay Risser
# -----
# Last Modified: 22-06-2022 14:31:19
# Modified By: Clay Risser
# -----
# Risser Labs LLC (c) Copyright 2021
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

include ../mkpm.mk
ifneq (,$(MKPM))
include ../main.mk

.PHONY: zero
zero: ;

ACTIONS += one
ONE_TARGETS := zero
$(ACTION)/one:
	@echo one
	@$(call done,one)

ACTIONS += two~one
$(ACTION)/two: Makefile
	@echo two
	@echo $?
	@$(call done,two)

ACTIONS += three~two
$(ACTION)/three:
	@echo three
	@$(call done,three)

.PHONY: info
info:
	@echo IS_PROJECT_ROOT: $(IS_PROJECT_ROOT)
	@echo MAKELEVEL: $(MAKELEVEL)
	@echo CURDIR: $(CURDIR)
	@echo PROJECT_ROOT: $(PROJECT_ROOT)
	@echo ROOT: $(ROOT)

-include $(call actions)

endif
