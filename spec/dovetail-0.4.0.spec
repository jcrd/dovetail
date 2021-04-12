Name: dovetail
Version: 0.4.0
Release: 1%{?dist}
Summary: An opinionated window manager

License: MIT
URL: https://github.com/jcrd/dovetail
Source0: https://github.com/jcrd/dovetail/archive/v0.4.0.tar.gz

BuildArch: noarch

BuildRequires: luarocks
BuildRequires: make

Requires: awesome
Requires: bash
Requires: pulseaudio
Requires: rofi
Requires: sessiond
Requires: wm-launch >= 0.5.0

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
* Sun Mar 14 2021 James Reed <jcrd@tuta.io> - 0.4.0-1
- Release v0.4.0

* Tue Feb 16 2021 James Reed <jcrd@tuta.io> - 0.3.0-1
- Release v0.3.0

* Thu Dec 31 2020 James Reed <jcrd@tuta.io> - 0.2.0-1
- Release v0.2.0
- Depend on wm-launch >= 0.5.0

* Sun Nov 1 2020 James Reed <jcrd@tuta.io> - 0.1.0-1
- Initial package

# vim: ft=spec