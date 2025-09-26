{# zfs/init.sls - Debian (arm64 & amd64) without duplicate repos #}
{% set arch = grains['osarch'] %}
{% set codename = grains.get('oscodename', 'stable') %}

{% if arch in ['x86_64', 'amd64'] %}
  {% set hdr_pkg = 'linux-headers-amd64' %}
{% elif arch in ['aarch64', 'arm64'] %}
  {% set hdr_pkg = 'linux-headers-arm64' %}
{% else %}
  {% set hdr_pkg = 'linux-headers-' ~ grains['kernelrelease'] %}
{% endif %}

# Ensure time sync (prevents "signature not live until..." apt errors)
timesyncd-service:
  service.running:
    - name: systemd-timesyncd
    - enable: True

timesyncd-ntp-on:
  cmd.run:
    - name: timedatectl set-ntp true
    - unless: timedatectl show -p NTP --value | grep -qx yes
    - require:
      - service: timesyncd-service

# Provide contrib + non-free-firmware ONLY (no 'main') to avoid duplicates
/etc/apt/sources.list.d/zfs-debian-extras.list:
  file.managed:
    - mode: "0644"
    - user: root
    - group: root
    - contents: |
        deb http://deb.debian.org/debian {{ codename }} contrib non-free-firmware
        deb http://deb.debian.org/debian {{ codename }}-updates contrib non-free-firmware
        deb http://security.debian.org/debian-security {{ codename }}-security contrib non-free-firmware

# Refresh apt (skip if lists are fresh)
apt-update:
  cmd.run:
    - name: apt-get update
    - unless: test -n "$(find /var/lib/apt/lists -type f -name '*Packages*' -mmin -60 2>/dev/null)"
    - require:
      - file: /etc/apt/sources.list.d/zfs-debian-extras.list
      - cmd: timesyncd-ntp-on

# Build toolchain + headers (by arch)
zfs-build-deps:
  pkg.installed:
    - pkgs:
      - build-essential
      - dkms
      - {{ hdr_pkg }}
    - require:
      - cmd: apt-update
    - retry:
        attempts: 2
        interval: 5

# ZFS DKMS + userspace
zfs-packages:
  pkg.installed:
    - pkgs:
      - zfs-dkms
      - zfsutils-linux
    - require:
      - pkg: zfs-build-deps
    - retry:
        attempts: 2
        interval: 5

# Load module now (idempotent)
modprobe-zfs:
  cmd.run:
    - name: /sbin/modprobe zfs
    - unless: lsmod | awk '{print $1}' | grep -qx zfs
    - require:
      - pkg: zfs-packages

# Load at boot
/etc/modules-load.d/zfs.conf:
  file.managed:
    - contents: "zfs\n"
    - mode: "0644"
    - user: root
    - group: root
    - require:
      - pkg: zfs-packages

# ZFS event daemon
zfs-zed:
  service.running:
    - enable: True
    - require:
      - cmd: modprobe-zfs
      - pkg: zfs-packages
