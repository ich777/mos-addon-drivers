#!/bin/bash
# This shows you how to set up a custom GitHub runner, preferrably in a LXC container.
# Preferred Distribustion: devuan
# Preferred Release: daedalus

# Install base dependencies
apt-get update
apt-get -y install wget curl nano jq procps

# Create necessary directories and download and extract GitHub Runner
GH_RUNNER_V=2.328.0
mkdir -p /root/runner/mos-drivers /root/runner_workdir/mos-drivers
cd /root/runner/mos-drivers
curl -o actions-runner-linux-x64-${GH_RUNNER_V}.tar.gz -L https://github.com/actions/runner/releases/download/v${GH_RUNNER_V}/actions-runner-linux-x64-${GH_RUNNER_V}.tar.gz
tar xzf ./actions-runner-linux-x64-${GH_RUNNER_V}.tar.gz
rm -f actions-runner-linux-x64-${GH_RUNNER_V}.tar.gz

# Make sure to replace <YOURTOKEN> with the runner token from GitHub
RUNNER_ALLOW_RUNASROOT="1" ./config.sh --url https://github.com/ich777/mos-addon-drivers --name mos-drivers --work /root/runner_workdir/mos-drivers --unattended --token <YOURTOKEN>

# Copy over runner-mos_drivers to /etc/init.d/ and make sure it's executable
echo "/etc/init.d/runner-mos_drivers start"  >> /etc/rc.local

# Reboot the LXC container
# Done
