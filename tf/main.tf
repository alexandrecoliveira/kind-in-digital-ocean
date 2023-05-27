terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.digital_ocean_api_token
}

variable "region" { default = "" }
variable "digital_ocean_api_token" { default = "" }

#Tag usada para agrupar recursos
resource "random_string" "tag_gerenciada" {
  count   = 1
  length  = 6
  special = false
}

#Chave ssh usada na máquina
resource "tls_private_key" "ed25519" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a new SSH key
resource "digitalocean_ssh_key" "chave_ssh" {
  name       = "chave_ssh_tag_${random_string.tag_gerenciada[0].result}"
  public_key = tls_private_key.ed25519.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.ed25519.private_key_openssh}' > ./chave_ssh_privada; echo '${tls_private_key.ed25519.public_key_openssh}' > ./chave_ssh_publica.pub; chmod 600 ./chave_ssh_privada"
  }
}

#VPC
resource "digitalocean_vpc" "vpc_kind" {
  name        = "vpc-kind-${var.region}-${random_string.tag_gerenciada[0].result}"
  region      = var.region
  ip_range    = "10.2.0.0/16"
  description = "VPC criada para uso com o KIND, TAG: ${random_string.tag_gerenciada[0].result}"
}

# Droplets
resource "digitalocean_droplet" "vm_kind_controlplane" {
  count    = 1
  image    = "ubuntu-22-04-x64"
  name     = "vm-kind-controlplane-${count.index}-${random_string.tag_gerenciada[0].result}"
  tags     = ["${random_string.tag_gerenciada[0].result}", "ubuntu-22-04-x64", "kind", "vm-kind-controlplane"]
  region   = var.region
  size     = "s-4vcpu-8gb"
  ssh_keys = [digitalocean_ssh_key.chave_ssh.fingerprint]
  vpc_uuid = digitalocean_vpc.vpc_kind.id

}

resource "digitalocean_droplet" "vm_kind_worker" {
  count    = 0
  image    = "ubuntu-22-04-x64"
  name     = "vm-kind-worker-${count.index}-${random_string.tag_gerenciada[0].result}"
  tags     = ["${random_string.tag_gerenciada[0].result}", "ubuntu-22-04-x64", "kind", "vm-kind-worker"]
  region   = var.region
  size     = "s-4vcpu-8gb"
  ssh_keys = [digitalocean_ssh_key.chave_ssh.fingerprint]
  vpc_uuid = digitalocean_vpc.vpc_kind.id

}

output "vm_kind_controlplanes" {
  value = {
    for d in digitalocean_droplet.vm_kind_controlplane :
    d.name => {
      tag  = "${random_string.tag_gerenciada[0].result}",
      urn  = d.urn,
      ipv4 = d.ipv4_address,
      vpc  = d.vpc_uuid
    }
  }
}

output "vm_kind_workers" {
  value = {
    for d in digitalocean_droplet.vm_kind_worker :
    d.name => {
      tag  = "${random_string.tag_gerenciada[0].result}",
      urn  = d.urn,
      ipv4 = d.ipv4_address
    }
  }
}