# Welcome to Son of Anton!

Son of Anton is a collection of [SaltStack](https://saltproject.io/) states and scripts for automating ZFS storage builds.  
It sets up a ZFS filesystem, creates datasets, and shares them out with samba and NFS making it easy to spin up a reproducible storage lab. Why Son of Anton? Check out the wiki page.

If you're using Parallels on macOS there is a Packer build that will automate the build by using a golden image. See the wiki for help.

## Quickstart

1. Download an ISO from Debian and build a VM
2. Attach two 5GB and two 10GB virtual disks
3. Boot up and create your VM.
4. `cd` into `/opt` and clone this repo to `/opt`
5. `cd` into `/opt/mustyStor/bootStrap` and `chmod +x` the `bootStrap.sh` script
6. Run the script
7. Once complete you have a working ZFS build with 3 datasets and 3 shares! You can access the SMB shares with the user `test` and password `test`.

Check the wiki page for more detailed instructions! Happy storage'ing! 

This project is supplied as is and has been tested several times on Debian 13 VM running in Parallels.
