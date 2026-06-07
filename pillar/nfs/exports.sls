nfs:
  exports:
    - path: /Pool01/test1
      clients: "*"
      options: "rw,no_root_squash,insecure,async,no_subtree_check"
      fsid: 1235

    - path: /Pool01/test2
      clients: "*"
      options: "rw,no_root_squash,insecure,async,no_subtree_check"
      fsid: 1236

    - path: /Pool01/test3
      clients: "*"
      options: "rw,no_root_squash,insecure,async,no_subtree_check"
      fsid: 1237
