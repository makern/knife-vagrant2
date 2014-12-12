# 0.0.6 (unreleased)

## Changes and new features

## Fixes


# 0.0.5 (2014-12-11)

## Changes and new features

* Added --vmx-customize option to pass arbitrary parameters to VMware providers
* Added --vagrant-config option to extend Vagrantfile with custom options


## Fixes

* Fix missing `ostruct` dependency with newer Chef versions
* Fix `--distro` default value change in newer Chef versions


# 0.0.4 (2014-03-14)

## Changes and new features

* Added --provider option to use vagrant providers other than virtualbox


# 0.0.3 (2014-01-28)

## Fixes

* Fixed error when not using --vb-customize option
* Removed unneeded dependency on knife-ec2


# 0.0.2 (2013-12-17)

## Changes and new features

* BREAKING: --share-folders option now takes HOST_PATH::GUEST_PATH instead of NAME::GUEST_PATH::HOST_PATH
* Added --port-forward option to map host ports to VMs
* Added --vb-customize option to pass arbitrary VirtualBox options to Vagrant


# 0.0.1 (2013-12-11)

## Changes and new features

* Initial release


# Thanks to our contributors

* [Jāzeps Baško](https://github.com/jbasko)
* [Robert J. Berger](https://github.com/rberger)
* [xsunsmile](https://github.com/xsunsmile)
* [Mevan Samaratunga](https://github.com/mevansam)
