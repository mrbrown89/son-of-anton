{% set samba = pillar.get('samba', {}) %}
{% set users = samba.get('users', {}) %}

{% for username, config in users.items() %}

samba_user_{{ username }}:
  user.present:
    - name: {{ username }}
    - shell: {{ config.get('shell', '/bin/bash') }}
    - home: {{ config.get('home', '/home/' ~ username) }}
    - createhome: True

samba_password_{{ username }}:
  cmd.run:
    - name: >
        (printf "{{ config['password'] }}\n{{ config['password'] }}\n" |
        smbpasswd -s -a {{ username }})
    - unless: "pdbedit -L | grep -q '^{{ username }}:'"
    - require:
      - user: samba_user_{{ username }}

{% endfor %}
