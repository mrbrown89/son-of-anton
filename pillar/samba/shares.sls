samba:
  users:
    - name: test
      password: test

  shares:
    - name: test1
      path: /Pool01/test1
      valid_users: test

    - name: test2
      path: /Pool01/test2
      valid_users: test

    - name: test3
      path: /Pool01/test3
      valid_users: test

  global:
    workgroup: WORKGROUP
    security: user
    map_to_guest: "Bad User"
    min_protocol: SMB2
    max_protocol: SMB3
