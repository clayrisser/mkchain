include mkpm.mk
include src/hi.mk
-include src/blackmagic.mk

.PHONY: hello
hello:
	@echo world
