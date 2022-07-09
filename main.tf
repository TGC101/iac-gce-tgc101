provider "google" {
  credentials = file("./credentials")
  project     = "${var.project}"
  region      = "${var.zone}"
}


module "vpc" {
  
    source  = "terraform-google-modules/network/google"
    version = "~> 4.0"

    project_id     = "${var.project}"
    network_name = "demo"
    routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "public"
      subnet_ip             = "10.10.110.0/24"
      subnet_region         = "us-west1"
      subnet_private_access = "false"
      subnet_flow_logs      = "false"
    },
    {
      subnet_name           = "private"
      subnet_ip             = "10.10.220.0/24"
      subnet_region         = "us-west1"
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
    }
  ]
  routes = [
      {
          name                   = "egress-internet"
          description            = "route through IGW to access internet"
          destination_range      = "0.0.0.0/0"
          tags                   = "egress-inet"
          next_hop_internet      = "true"
      }
  ]
}


resource "google_compute_firewall" "k8s" {
  name = "allow-k8s"
  allow {
    protocol = "all"
  }
  direction     = "INGRESS"
  network = module.vpc.network_name
  priority      = 1000
  source_ranges = ["10.10.110.0/24"]
  target_tags   = ["k8s"]
}


resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh-k8s"
  network = module.vpc.network_name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges           = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "app" {
  name    = "allow-k8s-30008"
  network = module.vpc.network_name
  allow {
    protocol = "tcp"
    ports    = ["30008"]
  }
  source_ranges           = ["0.0.0.0/0"]
}


resource "google_compute_firewall" "lb" {
  name    = "allow-k8s-80"
  network = module.vpc.network_name
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges           = ["0.0.0.0/0"]
}


resource "google_compute_instance" "k8s" {
    for_each = var.hostname
    name         = "${each.value}"
    machine_type = "e2-medium"
    zone         = "us-west1-b"

    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-2204-lts"
        }
    }
    tags = ["k8s"]

    network_interface {
        subnetwork = "${module.vpc.subnets_names[1]}"
        access_config {}
    }
    metadata_startup_script = <<-EOF
        #!/bin/bash 
        sudo hostnamectl set-hostname ${each.value}
        sudo useradd ubuntu -m -s /bin/bash  2>/dev/null
        echo ${var.key_devops} >> /home/ubuntu/.ssh/authorized_keys
    EOF
}


output "ec2_ip" {
   value = {
    for k, i in google_compute_instance.k8s : k => i.network_interface.0.access_config.0.nat_ip
   }
}

output "ec2_ip_out" {
   value = ["${google_compute_instance.k8s["master"].network_interface.0.access_config.0.nat_ip}"]
}
