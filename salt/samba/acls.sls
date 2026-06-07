{% set datasets = pillar.get('zfs', {}).get('datasets', {}) %}

{% for pool, dataset_list in datasets.items() %}
{% for dataset in dataset_list %}

{{ pool }}_{{ dataset }}_ownership:
  file.directory:
    - name: /{{ pool }}/{{ dataset }}
    - user: test
    - group: test
    - recurse:
      - user
      - group

{% endfor %}
{% endfor %}
