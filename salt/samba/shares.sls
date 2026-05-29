{% set samba = pillar.get('samba', {}) %}
{% set global = samba.get('global', {}) %}
{% set shares = samba.get('shares', []) %}

/etc/samba/smb.conf:
  file.managed:
    - user: root
    - group: root
    - mode: "0644"
    - contents: |
        [global]
        workgroup = {{ global.get('workgroup', 'WORKGROUP') }}
        security = {{ global.get('security', 'user') }}
        map to guest = {{ global.get('map_to_guest', 'Bad User') }}
        server min protocol = {{ global.get('min_protocol', 'SMB2') }}
        server max protocol = {{ global.get('max_protocol', 'SMB3') }}

        {% for share in shares %}
        [{{ share.name }}]
        path = {{ share.path }}
        read only = no
        guest ok = no
        browseable = yes
        valid users = {{ share.valid_users }}
        force user = {{ share.valid_users }}
        create mask = 0666
        directory mask = 0777

        {% endfor %}

smbd:
  service.running:
    - name: smbd
    - enable: True
    - watch:
      - file: /etc/samba/smb.conf
