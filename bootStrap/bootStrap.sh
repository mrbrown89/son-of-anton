#!/bin/bash

baseSoftware() {
# Make sure some basic apps are installed. Tools for work post deployment
    apt-get install wget curl screen vim -y
}

saltInstall() {
# Ensure keyrings directory exists
    mkdir -p /etc/apt/keyrings

# Import Salt keys
    curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public \
        | tee /etc/apt/keyrings/salt-archive-keyring.pgp >/dev/null
    curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources \
        | tee /etc/apt/sources.list.d/salt.sources >/dev/null

# Update and pin Salt version
    apt-get update
    cat >/etc/apt/preferences.d/salt-pin-1001 <<'EOF'
Package: salt-*
Pin: version 3006.*
Pin-Priority: 1001
EOF

# Install both master and minion
    apt-get install salt-master salt-minion -y

# Create /opt/son-of-anton/salt for state files
    mkdir -p /opt/son-of-anton/salt
    chmod 755 /opt/son-of-anton/salt
    
# Configure master to use /opt/son-of-anton/salt
    mkdir -p /etc/salt/master.d
    cat >/etc/salt/master.d/roots.conf <<'EOF'
file_roots:
  base:
    - /opt/son-of-anton/salt
EOF

systemctl restart salt-master

# Point minion to local master; set stable ID; prefer IPv4
    MINION_ID="$(hostname -f 2>/dev/null || hostname)"
    mkdir -p /etc/salt/minion.d
    cat >/etc/salt/minion.d/local.conf <<EOF
master: 127.0.0.1
id: ${MINION_ID}
ipv6: False
EOF
    echo "${MINION_ID}" >/etc/salt/minion_id

    H="$(hostname)"
    F="${MINION_ID}"
    grep -qE "^\s*127\.0\.1\.1\s+${F}\b.*\b${H}\b" /etc/hosts || \
        sed -i "1i127.0.1.1 ${F} ${H}" /etc/hosts
# Ensure ::1 line exists and includes our hostnames, so AAAA lookups resolve instantly
    if grep -q '^::1' /etc/hosts; then
        grep -qE "^::1 .*\\b${F}\\b" /etc/hosts || sed -i "s/^::1.*/& ${F} ${H}/" /etc/hosts
    else
        printf "::1 localhost ip6-localhost ip6-loopback %s %s\n" "$F" "$H" >>/etc/hosts
    fi
# Explicitly disable IPv6 on the master too to prevent IPv6 errors
    echo "ipv6: False" >/etc/salt/master.d/ipv6.conf
    echo "ipv6: False" >/etc/salt/minion.d/ipv6.conf


    systemctl enable salt-master && systemctl restart salt-master
    sleep 3

# Fresh minion keys on first connect
    systemctl stop salt-minion 2>/dev/null || true
    rm -rf /etc/salt/pki/minion/* 2>/dev/null || true

# Start the minion service
    systemctl enable salt-minion
    sleep 5
    systemctl start salt-minion

# Cool little loop to wait for the salt minion key to talk back to the master
    WAIT_TIMEOUT=180
    waited=0
    echo "[i] waiting for '${MINION_ID}' to show under unaccepted keys (pre)…"
    while ! salt-key -l pre 2>/dev/null | awk 'NF' | grep -Fxq "${MINION_ID}"; do
        if salt-key -l acc 2>/dev/null | awk 'NF' | grep -Fxq "${MINION_ID}"; then
            echo "[i] key already accepted for ${MINION_ID}"
            break
        fi
        if [ "${waited}" -ge "${WAIT_TIMEOUT}" ]; then
            echo "[!] timed out waiting for ${MINION_ID} to appear under unaccepted keys"
            salt-key -L || true
            break
        fi
        echo "[…] still waiting (${waited}/${WAIT_TIMEOUT}s)…"
        sleep 5
        waited=$((waited+5))
    done

    if salt-key -l pre 2>/dev/null | awk 'NF' | grep -Fxq "${MINION_ID}"; then
        echo "[i] accepting key for ${MINION_ID}"
        salt-key -a "${MINION_ID}" -y
    fi
    echo "Pausing for 30 seconds for minion to be fully added. Test ping to follow..."
    sleep 30
    salt '*' test.ping
}

diskMappings() {
    META_FILE="/opt/son-of-anton/salt/zfs/metaDisks.txt"
    DATA_FILE="/opt/son-of-anton/salt/zfs/disks.txt"

# Clear old files so they are nice and empty
    : > "$META_FILE"
    : > "$DATA_FILE"

# if statement to find the disk mappings and put them into two text files ready for ZFS
    lsblk -dn -o NAME,TYPE,SIZE | awk '$2=="disk"{print $1,$3}' | while read -r name size; do
        if [[ "$size" == "5G" ]]; then
            echo "/dev/$name" >> "$META_FILE"
        elif [[ "$size" == "10G" ]]; then
            echo "/dev/$name" >> "$DATA_FILE"
        fi
    done

# Spit the files out to terminal for feedback
    echo "Meta (5G) disks:"
    cat "$META_FILE"
    echo
    echo "Data (10G) disks:"
    cat "$DATA_FILE"
}


main() {
    baseSoftware
    saltInstall
    diskMappings
    
# Now runs a few one shot salt states
    echo "Installing ZFS"
    salt '*' state.apply zfs.zfs
    echo "Building ZFS Pool"
    salt '*' state.apply zfs.pool
    
# Show pool information for feedback/comfort! 
    echo "Pool Information"
    zpool list
    
# Now runs the top.sls file
    echo "Running full salt build"
    salt '*' state.apply test=false
}

main

