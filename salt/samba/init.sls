/etc/samba/smb.conf:
  file.managed:
    - source: salt://samba/files/smb.conf.j2
    - template: jinja
    - user: root
    - group: root
    - mode: '0644'

smbd:
  service.running:
    - enable: true
    - watch:
      - file: /etc/samba/smb.conf
