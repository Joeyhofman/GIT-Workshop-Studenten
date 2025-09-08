terraform {
  required_providers {
    esxi = {
      source  = "josenk/esxi"
      version = "~> 1.6"
    }
  }
}

provider "esxi" {
  esxi_hostname = var.esxi_host
  esxi_hostport = 22
  esxi_hostssl  = 443
  esxi_username = var.esxi_user
  esxi_password = var.esxi_password
}

locals {
  ssh_key = file(var.ssh_public_key_path)
}

data "template_file" "Default" {
  template = file("userdata.yml")
  vars = {
    ssh_key = local.ssh_key
  }
}

resource "esxi_guest" "webserver" {
  count = 2
  guest_name = "webserver-${count.index + 1}"
  disk_store = var.disk_store
  ovf_source = var.ubuntu_image_url

  network_interfaces {
    virtual_network = var.virtual_network
  }

  guestinfo = {
    "userdata.encoding" = "gzip+base64"
    "userdata"          = base64gzip(data.template_file.Default.rendered)
  }

  memsize = 1024
  numvcpus = 1
}

resource "esxi_guest" "databaseserver" {
  guest_name = "databaseserver"
  disk_store = var.disk_store
  ovf_source = var.ubuntu_image_url

  network_interfaces {
    virtual_network = var.virtual_network
  }

  guestinfo = {
    "userdata.encoding" = "gzip+base64"
    "userdata"          = base64gzip(data.template_file.Default.rendered)
  }

  memsize = 1024
  numvcpus = 1
}