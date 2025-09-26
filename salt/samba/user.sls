create_test_user:
  user.present:
    - name: test
    - shell: /bin/bash
    - home: /home/test
    - createhome: True
    
test_samba_user:
  cmd.run:
    - name: >
        /usr/bin/printf "test\ntest\n" | /usr/bin/smbpasswd -s -a test
