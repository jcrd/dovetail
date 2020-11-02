Name: dovetail
Version: 0.1.0
Release: 1%{?dist}
Summary: An opinionated window manager

License: MIT
URL: https://github.com/jcrd/dovetail
Source0: https://github.com/jcrd/dovetail/archive/v0.1.0.tar.gz

BuildArch: noarch

BuildRequires: luarocks
BuildRequires: make

Requires: awesome
Requires: bash
Requires: pulseaudio
Requires: rofi
Requires: sessiond
Requires: wm-launch >= 0.4.0

Recommends: upower

%global debug_package %{nil}

%description
An opinionated window manager.

%prep
%setup

%build
%make_build PREFIX=/usr

%install
%make_install PREFIX=/usr

%files
%license LICENSE
%doc README.md
/usr/bin/%{name}
/usr/share/dovetail
/usr/share/xsessions/%{name}.desktop
/usr/lib/systemd/user/%{name}.service
/etc/xdg/dovetail

%changelog
* Sun Nov 1 2020 James Reed <jcrd@tuta.io> - 0.1.0-1
- Initial package

# vim: ft=spec
