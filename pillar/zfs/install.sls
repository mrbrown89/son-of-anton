zfs:
  repo:
    codename: stable
    components:
      - contrib
      - non-free-firmware

  kernel:
    headers_map:
      amd64: linux-headers-amd64
      x86_64: linux-headers-amd64
      arm64: linux-headers-arm64
      aarch64: linux-headers-arm64

  zed:
    enabled: true
