{% set zfs = pillar.get('zfs', {}) %}
{% set datasets = zfs.get('datasets', {}) %}

{% for pool, ds_list in datasets.items() %}

  {% for ds in ds_list %}

ensure_{{ pool }}_{{ ds }}:
  cmd.run:
    - name: zfs create {{ pool }}/{{ ds }}
    - unless: zfs list -H -o name {{ pool }}/{{ ds }}

  {% endfor %}

{% endfor %}
