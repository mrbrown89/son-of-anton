{% set nfs = pillar.get('nfs', {}) %}
{% set exports = nfs.get('exports', []) %}

/etc/exports:
  file.managed:
    - user: root
    - group: root
    - mode: "0644"
    - contents: |
        # Managed by Salt - do not edit manually

        {% for e in exports %}
        {{ e.path }} {{ e.clients }}({{ e.options }}{% if e.get('fsid') is not none %},fsid={{ e.fsid }}{% endif %})
        {% endfor %}
    - watch_in:
      - module: nfs_export_apply

nfs_export_apply:
  cmd.run:
    - name: exportfs -ar
    - onchanges:
      - file: /etc/exports
