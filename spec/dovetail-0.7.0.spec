Name: dovetail
Version: 0.7.0
Release: 2%{?dist}
Summary: An opinionated window manager

License: MIT
URL: https://github.com/jcrd/dovetail
Source0: https://github.com/jcrd/dovetail/archive/v0.7.0.tar.gz

BuildArch: noarch

BuildRequires: luarocks
BuildRequires: make

Requires: awesome
Requires: bash
Requires: rofi
Requires: sessiond >= 0.6.0
Requires: wm-launch >= 0.5.0
Requires: fontawesome-fonts

Recommends: ImageMagick
Recommends: pulseaudio
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
/usr/lib/systemd/user/%{name}.service
/etc/xdg/dovetail

%changelog
* Sun Nov  7 2021 James Reed <james@twiddlingbits.net> - 0.7.0-1
- Release v0.7.0

* Tue Oct 19 2021 James Reed <james@twiddlingbits.net> - 0.6.0-2
- Add missing fontawesome-fonts dependency

* Tue Aug 10 2021 James Reed <james@twiddlingbits.net> - 0.6.0-1
- Release v0.6.0

* Mon May 10 2021 James Reed <james@twiddlingbits.net> - 0.5.2-1
- Release v0.5.2

* Mon Apr 12 2021 James Reed <james@twiddlingbits.net> - 0.5.1-1
- Release v0.5.1 (hotfix for broken installation)

* Mon Apr 12 2021 James Reed <james@twiddlingbits.net> - 0.5.0-1
- Release v0.5.0
- Depend on sessiond >= 0.5.0

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
