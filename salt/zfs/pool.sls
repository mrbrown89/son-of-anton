{% set zfs = pillar.get('zfs', {}) %}
{% set pools = zfs.get('pools', {}) %}

{% set data_disks = salt['cp.get_file_str']('/opt/son-of-anton/salt/zfs/disks.txt').splitlines() %}
{% set meta_disks = salt['cp.get_file_str']('/opt/son-of-anton/salt/zfs/metaDisks.txt').splitlines() %}

{% for pool_name, config in pools.items() %}

create_zpool_{{ pool_name }}:
  cmd.run:
    - name: >
        zpool create {{ pool_name }}
        mirror {{ data_disks | join(' ') }}
        special mirror {{ meta_disks | join(' ') }}
    - unless: zpool list -H -o name | grep -qx {{ pool_name }}

{% endfor %}
