check_ipmi_power
================

Use the ```ipmi-power``` tool from [FreeIPMI](http://www.gnu.org/software/freeipmi/) to check current power state.

Requirements
------------

**General**

- Perl 5
- Perl Modules:
    - Monitoring::Plugin or Nagios::Plugin
- [FreeIPMI](http://www.gnu.org/software/freeipmi/)

**Ubuntu**

- perl
- libmonitoring-plugin-perl
- freeipmi-tools

Installation
------------

Just copy the file `check_ipmi_power.pl` to your Icinga or Nagios plugin directory.

Examples
--------

Only the USER privilege level is required to fetch the power state. Don't use a user with administrative privileges.

```
./check_ipmi_power.pl --hostname 1.2.3.4 --username your-ipmi-username --password your-ipmi-password
check_ipmi_power OK - System is on
```

Source
------

- [Latest source at github.com](https://github.com/DinoTools/monitoring-check_ipmi_power)

Issues
------

Use the [GitHub issue tracker](https://github.com/DinoTools/monitoring-check_ipmi_power) to report any issues

License
-------

GPLv3+
