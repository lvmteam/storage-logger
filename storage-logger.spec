Name:		storage-logger
Version:	0.5
Release:	0%{?dist}
Summary:	Records the storage configuration in the system journal
URL:		https://github.com/lvmteam/storage-logger
License:	GPLv2
BuildArch:	noarch
Requires:	bash
Source:		storage-logger.tgz

%description
storage-logger writes a record of changes to the system's storage 
configuration into the system journal using a udev rule with an 
accompanying script.

%global _udevdir %{_prefix}/lib/udev/rules.d

%prep
%setup -c -q

%build

%install

install -d -m 755 ${RPM_BUILD_ROOT}/%{_sbindir}
install -m 755 scripts/udev_storage_logger.sh ${RPM_BUILD_ROOT}/%{_sbindir}

install -d -m 755 ${RPM_BUILD_ROOT}/%{_udevdir}
install -m 644 udev/99-zzz-storage-logger.rules ${RPM_BUILD_ROOT}/%{_udevdir}

install -d -m 755 ${RPM_BUILD_ROOT}/%{_bindir}
install -m 755 scripts/lsblkj ${RPM_BUILD_ROOT}/%{_bindir}

install -d -m 755 ${RPM_BUILD_ROOT}/%{_mandir}/man1
install -m 644 man/lsblkj.1 ${RPM_BUILD_ROOT}/%{_mandir}/man1

%files
%license COPYING

%defattr(755,root,root,-)
%{_sbindir}/udev_storage_logger.sh

%defattr(644,root,root,-)
%{_udevdir}/99-zzz-storage-logger.rules

%doc README

%package report
Summary: Reports the storage configuration recorded by storage-logger
License: GPLv2
Requires: %{name} = %{version}-%{release}
Requires: systemd-udev >= 244
Requires: util-linux >= 2.35
Requires: perl-JSON

%description report
storage-logger-report provides lsblkj as a wrapper around lsblk to
reports the changes to the system's storage configuration recorded in
the system journal by the storage-logger package.

%files report
%defattr(755,root,root,-)
%{_bindir}/lsblkj

%defattr(644,root,root,-)
%{_mandir}/man1/lsblkj.1*

%changelog
* Wed Jan 8 2020 Alasdair Kergon <agk@redhat.com> 0.5-0
- Initial release
