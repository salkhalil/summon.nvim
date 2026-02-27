NVIM ?= nvim
PLENARY_BUSTED_CMD = PlenaryBustedDirectory tests { minimal_init = 'tests/minimal_init.lua' }

.PHONY: test

test:
	$(NVIM) --headless -u tests/minimal_init.lua -i NONE \
		-c "$(PLENARY_BUSTED_CMD)" \
		-c qa
