{% set samba = pillar.get('samba', {}) %}

/etc/samba/smb.conf:
  file.managed:
    - source: salt://samba/files/smb.conf.j2
    - template: jinja
    - user: root
    - group: root
    - mode: "0644"
    - context:
        samba: {{ samba | tojson }}


smbd:
  service.running:
    - name: smbd
    - enable: True
    - watch:
      - file: /etc/samba/smb.conf
