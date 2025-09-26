{% set data_disks = salt['cp.get_file_str']('salt://zfs/disks.txt').splitlines() %}
{% set meta_disks = salt['cp.get_file_str']('salt://zfs/metaDisks.txt').splitlines() %}

create_zpool_Pool01:
  cmd.run:
    - name: >
        zpool create Pool01
        mirror {{ data_disks | join(' ') }}
        special mirror {{ meta_disks | join(' ') }}
    - unless: zpool list -H -o name | grep -q '^Pool01$'
