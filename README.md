# MOS Addon Drivers

mos-addon-drivers provides **packaged additional hardware drivers** for use within
the MOS ecosystem.

This repository contains the **build scripts, packaging logic, and automation**
required to compile and package optional drivers for MOS.

---

## Overview

The repository builds and packages various **optional kernel drivers** that are not
part of the MOS base system.

Currently supported driver sets include, but are not limited to:

- NVIDIA drivers
- DVB drivers

Additional drivers may be added over time.

Drivers are compiled against the corresponding MOS kernel versions and provided
as installable add-ons.

No functional changes to upstream drivers are intended.  
The goal is to provide **consistent and reproducible driver packages** for MOS systems.

---

## Licensing

The contents of this repository (build scripts, configuration files, and automation)
are licensed under **GPL-3.0**.

Driver sources and binaries remain licensed under their respective upstream licenses.

---

## Third-Party Software

This repository builds and packages third-party open-source software.
Packaged components remain licensed under their original upstream licenses.
