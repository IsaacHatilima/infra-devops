terraform {
    required_providers {
        proxmox = {
            source = "telmate/proxmox"   
            version = "3.0.2-rc04"
        }
    }
}

provider "proxmox" {
    pm_api_url          = "https://HOST-SERVER-IP-OR-DOMAIN/api2/json"
    pm_api_token_id     = "terraform@pam!terraform"
    pm_api_token_secret = "some-very-long-and-secure-token-string"
    pm_tls_insecure     = false # set to true if using self-signed certificates
}

locals {
  vms = {
    server-name = { ip = "192.168.10.27", vmid = 200, disk_size = "32G", memory = 2048 }
    another-server-name = { ip = "192.168.10.28", vmid = 201, disk_size = "150G", memory = 2048 }
  }
}

resource "proxmox_vm_qemu" "ubuntu" {
    for_each    = local.vms
    name        = each.key
    vmid        = each.value.vmid
    target_node = "node-name" # replace with your Proxmox node name
    pool        = "Active" # replace with your Proxmox resource pool name
    clone       = "ubuntu-2404-template" # replace with your Proxmox template name
    full_clone  = true
    memory      = each.value.memory
    agent       = 1
    cpu {
        cores = 2
    }
    os_type = "cloud-init"
    boot = "order=ide2;scsi0;net0"
    scsihw = "virtio-scsi-pci"
    ipconfig0 = "ip=${each.value.ip}/24,gw=192.168.10.1"

    serial {
        id   = 0
        type = "socket"
    }

    # Main disk
    disk {
        size       = each.value.disk_size
        type       = "disk"
        storage    = "local"
        slot       = "scsi0"
        discard    = true
        emulatessd = true
    }

    # Cloud-init drive
    disk {
        type     = "cloudinit"
        storage  = "local"
        slot     = "ide2"
    }

    network {
        id        = 0
        model     = "virtio"
        bridge    = "vmbr1"
        firewall  = false
    }

    ciuser     = "username"
    cipassword = "Passw0rd123!"
    ciupgrade = true
    sshkeys = <<EOF
    ssh-ed25519 ansible server-key
    ssh-rsa your-local-public-key
    EOF
}
