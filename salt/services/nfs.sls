nfs_service_enabled:
  service.enabled:
    - name: nfs-server
    - enable: True

nfs_service_running:
  service.running:
    - name: nfs-server
    - enable: True
