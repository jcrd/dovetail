VERSIONCMD = git describe --dirty --tags --always 2> /dev/null
VERSION := $(shell $(VERSIONCMD) || cat VERSION)

PREFIX ?= /usr/local
BINPREFIX ?= $(PREFIX)/bin
SHAREPREFIX ?= $(PREFIX)/share
LIBPREFIX ?= $(PREFIX)/lib

LUA_TREE := tree
LUA_MODULES := lua_modules
LUA_VERSION := $(shell luarocks config --lua-ver)
LUA_TREE_SHARE := $(LUA_TREE)/share/lua/$(LUA_VERSION)
LUA_SHARE := $(SHAREPREFIX)/dovetail

CONFIG_DIR ?= dovetail
CONFIG_FILE ?= config.lua
DEFAULT_CONFIG := /etc/xdg/$(CONFIG_DIR)/$(CONFIG_FILE)

BUILDDIR ?= builddir

all: $(BUILDDIR)/dovetail.sh $(BUILDDIR)/init.lua

$(BUILDDIR)/dovetail.sh: dovetail.sh.in
	mkdir -p $(BUILDDIR)
	sed -e "s|@VERSION|$(VERSION)|" \
		-e "s|@LUA_SHARE|$(LUA_SHARE)|" \
		$< > $@
	chmod +x $@

$(BUILDDIR)/init.lua: init.lua.in
	mkdir -p $(BUILDDIR)
	sed -e "s|@default_config|'$(DEFAULT_CONFIG)'|" \
		-e "s|@config_dir|'$(CONFIG_DIR)'|" \
		-e "s|@config_file|'$(CONFIG_FILE)'|" \
		$< > $@

$(BUILDDIR)/share: clean-share $(BUILDDIR)/init.lua $(LUA_MODULES)
	mkdir -p $@
	./scripts/make_share.sh $@ $(LUA_MODULES)

$(LUA_TREE):
	./scripts/make_tree.sh $(LUA_TREE)

init: $(BUILDDIR)/share

$(LUA_MODULES): clean-modules $(LUA_TREE)
	mkdir -p $(LUA_MODULES)
	cp -r $(LUA_TREE_SHARE)/* $(LUA_MODULES)

install:
	mkdir -p $(DESTDIR)$(BINPREFIX)
	cp -p $(BUILDDIR)/dovetail.sh $(DESTDIR)$(BINPREFIX)/dovetail
	mkdir -p $(DESTDIR)$(LUA_SHARE)
	cp -p $(BUILDDIR)/init.lua $(DESTDIR)$(LUA_SHARE)
	cp -pr src $(DESTDIR)$(LUA_SHARE)/dovetail
	cp -pr $(LUA_MODULES)/* $(DESTDIR)$(LUA_SHARE)
	mkdir -p $(DESTDIR)$(LIBPREFIX)/systemd/user
	cp -p systemd/dovetail.service $(DESTDIR)$(LIBPREFIX)/systemd/user
	mkdir -p $(DESTDIR)/etc/xdg/dovetail
	cp -p config.def.lua $(DESTDIR)$(DEFAULT_CONFIG)
	mkdir -p $(DESTDIR)$(SHAREPREFIX)/xsessions

uninstall:
	rm -f $(DESTDIR)$(BINPREFIX)/dovetail
	rm -fr $(DESTDIR)$(LUA_SHARE)
	rm -f $(DESTDIR)$(LIBPREFIX)/systemd/user/dovetail.service
	rm -fr $(DESTDIR)/etc/xdg/dovetail

clean:
	rm -fr $(BUILDDIR)

clean-share:
	rm -fr $(BUILDDIR)/share

clean-tree:
	rm -fr $(LUA_TREE)

clean-modules:
	rm -fr $(LUA_MODULES)

clean-all: clean clean-tree clean-modules

.PHONY: all init install uninstall \
	clean clean-share clean-tree clean-modules clean-all
