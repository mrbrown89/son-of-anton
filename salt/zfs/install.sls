{% set zfs = pillar.get('zfs', {}) %}
{% set repo = zfs.get('repo', {}) %}
{% set kernel = zfs.get('kernel', {}) %}

{% set arch = grains['osarch'] %}
{% set codename = repo.get('codename', grains.get('oscodename', 'stable')) %}
{% set components = repo.get('components', ['contrib', 'non-free-firmware']) %}
{% set hdr_pkg = kernel.get('headers_map', {}).get(arch, 'linux-headers-' ~ grains['kernelrelease']) %}

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

zfs-repo:
  file.managed:
    - name: /etc/apt/sources.list.d/zfs-debian-extras.list
    - mode: "0644"
    - contents: |
        deb http://deb.debian.org/debian {{ codename }} {{ components | join(' ') }}
        deb http://deb.debian.org/debian {{ codename }}-updates {{ components | join(' ') }}
        deb http://security.debian.org/debian-security {{ codename }}-security {{ components | join(' ') }}

apt-update:
  cmd.run:
    - name: apt-get update
    - unless: test -n "$(find /var/lib/apt/lists -type f -name '*Packages*' -mmin -60 2>/dev/null)"
    - require:
      - file: zfs-repo
      - cmd: timesyncd-ntp-on

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

modprobe-zfs:
  cmd.run:
    - name: /sbin/modprobe zfs
    - unless: lsmod | awk '{print $1}' | grep -qx zfs
    - require:
      - pkg: zfs-packages

zfs-module-load:
  file.managed:
    - name: /etc/modules-load.d/zfs.conf
    - contents: "zfs\n"
    - mode: "0644"
    - require:
      - pkg: zfs-packages

zfs-zed:
  service.running:
    - name: zed
    - enable: {{ zfs.get('zed', {}).get('enabled', True) }}
    - require:
      - cmd: modprobe-zfs
      - pkg: zfs-packages
