include blackmagic.mk

ACTIONS += hello
HELLO_DEPS :=
HELLO_TARGET := $(HELLO_DEPS) $(ACTION)/hello
$(ACTION)/hello:
	@echo world

-include $(patsubst %,$(_ACTIONS)/%,$(ACTIONS))

+%:
	@$(MAKE) -e -s $(shell echo $@ | $(SED) 's/^\+//g')

%:
	@echo $@ is not a valid command && exit 1
