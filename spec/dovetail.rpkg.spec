Name: {{{ git_name }}}
Version: {{{ git_version lead="$(git tag | sed -n 's/^v//p' | sort --version-sort -r | head -n1)" }}}
Release: 1%{?dist}
Summary: An opinionated window manager

License: MIT
URL: https://github.com/jcrd/dovetail
VCS: {{{ git_vcs }}}
Source0: {{{ git_pack }}}

BuildArch: noarch

BuildRequires: luarocks
BuildRequires: make

Requires: awesome
Requires: bash
Requires: rofi
Requires: sessiond >= 0.5.0
Requires: wm-launch >= 0.5.0

Recommends: ImageMagick
Recommends: pulseaudio
Recommends: upower

%global debug_package %{nil}

%description
An opinionated window manager.

%prep
{{{ git_setup_macro }}}

%build
%make_build PREFIX=/usr

%install
%make_install PREFIX=/usr

%files
%license LICENSE
%doc README.md
/usr/bin/%{name}
/usr/share/dovetail
/usr/lib/systemd/user/%{name}.service
/etc/xdg/dovetail

%changelog
{{{ git_changelog }}}

# vim: ft=spec
