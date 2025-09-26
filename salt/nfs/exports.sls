# Define the contents of the /etc/exports file
/etc/exports:
  file.managed:
    - contents: |
        # /etc/exports: the access control list for filesystems which may be exported
        # See exports(5).

        # Example for NFSv2 and NFSv3:
        # /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)

        # Example for NFSv4:
        # /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
        # /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)

        /Pool01/test1 *(rw,no_root_squash,insecure,fsid=1235,async,no_subtree_check)
        /Pool01/test2 *(rw,no_root_squash,insecure,fsid=1236,async,no_subtree_check)
        /Pool01/test3 *(rw,no_root_squash,insecure,fsid=1237,async,no_subtree_check)
        
        # Add any new NFS exports here as needed
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - cmd: exportfs -ar

# Apply the exportfs command to export the shares
export_nfs_exports:
  cmd.run:
    - name: exportfs -ar
    - onchanges:
      - file: /etc/exports
