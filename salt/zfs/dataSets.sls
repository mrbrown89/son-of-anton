{% set datasets = [
  'Pool01/test1',
  'Pool01/test2',
  'Pool01/test3'
] %}

{% for ds in datasets %}
create_{{ ds.replace('/', '_') }}:
  cmd.run:
    - name: zfs create {{ ds }}
    - unless: zfs list -H -o name {{ ds }}
{% endfor %}
