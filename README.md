[![Build Status](https://jenkins.testbed.tier.internet2.edu/buildStatus/icon?job=docker/midPoint_container/3.9)](https://jenkins.testbed.tier.internet2.edu/buildStatus/icon?job=docker/midPoint_container/3.9)

This repository contains sources for TIER-supported [midPoint](http://midpoint.evolveum.com) image.

The image contains the midPoint application along with some TIER-specific components: Apache reverse proxy with optional Shibboleth filter and TIER Beacon.

# Supported tags
- latest
- midPoint version-specific branches, e.g. 3.9, 3.9.1, 4.0, etc.

# Content
- the root directory contains build instructions for the `midpoint` image 
- `demo` directory contains a couple of demonstration scenarios:
  - `simple` to show simple composition of midPoint with the repository,
  - `shibboleth` to show integration with Shibboleth IdP,
  - `postgresql` to show how to use alternative dockerized repository,
  - `extrepo` to show how to use external repository,
  - `complex` to demonstrate more complex deployment of midPoint in a sample university environment, featuring midPoint along with Grouper, LDAP directory, RabbitMQ, Shibboleth IdP, source and target systems.

# Build instructions
```
$ ./build.sh
```
You can then continue with one of demo composition, e.g. simple or complex one.

# Documentation
Please see [Dockerized midPoint](https://spaces.at.internet2.edu/display/MID/Dockerized+midPoint) wiki page.

This is a work in progress, suitable for testing.
For details on the project, see [Status of the work](https://spaces.at.internet2.edu/display/MID/Status+of+the+work).
