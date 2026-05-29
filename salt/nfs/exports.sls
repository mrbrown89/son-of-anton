{% set nfs = pillar.get('nfs', {}) %}
{% set exports = nfs.get('exports', []) %}

nfs_exports_file:
  file.managed:
    - name: /etc/exports
    - user: root
    - group: root
    - mode: "0644"
    - contents: |
        # Managed by Salt - do not edit manually

        {% for e in exports %}
        {{ e.path }} {{ e.clients }}({{ e.options }}{% if e.get('fsid') is not none %},fsid={{ e.fsid }}{% endif %})
        {% endfor %}
    - require_in:
      - cmd: nfs_export_apply

nfs_export_apply:
  cmd.run:
    - name: exportfs -ra
    - onchanges:
      - file: nfs_exports_file
