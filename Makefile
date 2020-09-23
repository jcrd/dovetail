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

DEFAULT_CONFIG ?= /etc/xdg/dovetail/config.lua
USER_CONFIG ?= dovetail/config.lua

all: builddir/dovetail.sh builddir/init.lua lua_modules

builddir/dovetail.sh: dovetail.sh.in
	mkdir -p builddir
	sed -e "s|VERSION=|VERSION=$(VERSION)|" \
		-e "s|LUA_SHARE=|LUA_SHARE=$(LUA_SHARE)|" \
		$< > $@
	chmod +x $@

builddir/init.lua: init.lua.in
	mkdir -p builddir
	sed -e "s|local default_config|local default_config = '$(DEFAULT_CONFIG)'|" \
		-e "s|local user_config|local user_config = '$(USER_CONFIG)'|" \
		$< > $@

tree:
	./scripts/make_tree.sh $(LUA_TREE)

lua_modules: tree
	mkdir -p $(LUA_MODULES)
	cp -r $(LUA_TREE_SHARE)/* $(LUA_MODULES)

install:
	mkdir -p $(DESTDIR)$(BINPREFIX)
	cp -p builddir/dovetail.sh $(DESTDIR)$(BINPREFIX)/dovetail
	mkdir -p $(DESTDIR)$(LUA_SHARE)
	cp -p builddir/init.lua $(DESTDIR)$(LUA_SHARE)
	cp -pr src $(DESTDIR)$(LUA_SHARE)/dovetail
	cp -pr $(LUA_MODULES)/* $(DESTDIR)$(LUA_SHARE)
	mkdir -p $(DESTDIR)$(LIBPREFIX)/systemd/user
	cp -p systemd/dovetail.service $(DESTDIR)$(LIBPREFIX)/systemd/user
	mkdir -p $(DESTDIR)/etc/xdg/dovetail
	cp -p config.def.lua $(DESTDIR)/etc/xdg/dovetail/config.lua

uninstall:
	rm -f $(DESTDIR)$(BINPREFIX)/dovetail
	rm -fr $(DESTDIR)$(LUA_SHARE)
	rm -f $(DESTDIR)$(LIBPREFIX)/systemd/user/dovetail.service
	rm -fr $(DESTDIR)/etc/xdg/dovetail

clean:
	rm -fr builddir

clean-modules:
	rm -fr $(LUA_TREE)
	rm -fr $(LUA_MODULES)

clean-all: clean clean-modules

.PHONY: all install uninstall clean clean-modules clean-all
