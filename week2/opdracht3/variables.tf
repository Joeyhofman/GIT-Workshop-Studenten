variable "esxi_host" {}
variable "esxi_user" {}
variable "esxi_password" {}
variable "disk_store" {}
variable "virtual_network" {}
variable "ubuntu_image_url" {
  default = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
}
variable "ssh_public_key_path" {}