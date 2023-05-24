LUA=lua5.1
BUSTED_PARAMS=--helper=spec/_init.lua

all: test

clean:
	rm -R docs

test:
	busted $(BUSTED_PARAMS) --exclude-tags=ignore,performance

test-verbose:
	busted $(BUSTED_PARAMS) --exclude-tags=ignore --keep-going --verbose

test-only:
	busted $(BUSTED_PARAMS) -t only --verbose

docs:
	ldoc -d docs --format=markdown --not_luadoc LibRingCache*.lua

install-dependencies:
	sudo luarocks install busted ldoc

.PHONY: all test test-only docs clean install-dependencies
