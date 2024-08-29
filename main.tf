
/*add the GCP provider*/


data "terraform_remote_state" "foo" {
  backend = "gcs"
  config = {
    bucket  = "gpmgcp3q24"
    prefix  = "dev"
  }
}


provider "google" {
  project     = var.project_num
  region      = var.region
}

/*enable the compute apis to createm vm and vpc resources*/
resource "google_project_service" "compute_google_apis" {
    project = var.project_num
    service = "compute.googleapis.com"
  
}

resource "google_compute_network" "vpc-fw-test" {
  project                 = var.project_num
  name                    = "vpc-fw-test"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode = "GLOBAL"

  depends_on = [ google_project_service.compute_google_apis ]
}

resource "google_compute_subnetwork" "vpc-fw-test-snet" {
  name          = "vpc-fw-test-snet"
  ip_cidr_range = "10.1.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc-fw-test.self_link
}

#F/w allowing ssh from everywhere 
resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc-fw-test.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
    
  }

source_ranges = ["0.0.0.0/0"]
  target_tags = [ "ssh" ]
  
  depends_on = [ google_compute_network.vpc-fw-test ]
}



#F/w allowing http from everywhere
resource "google_compute_firewall" "allow-http-0000" {
  name    = "allow-http-0000"
  network = google_compute_network.vpc-fw-test.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = [ "allow-http-0000" ]

  depends_on = [ google_compute_network.vpc-fw-test ]
}

resource "google_compute_instance" "allow-0000" {
  name         = "allow-0000"
  machine_type = "e2-small"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 10

    }
  }

  network_interface {
    network = "vpc-fw-test"
    subnetwork = google_compute_subnetwork.vpc-fw-test-snet.self_link

        access_config {
      // Ephemeral public IP
    }
  }

    tags = [ "allow-http-0000", "ssh" ]
  metadata_startup_script = <<-EOF
                            apt update 
                            apt -y install apache2 
                            EOF

}



#F/w allowing http from source-ip addresses
resource "google_compute_firewall" "allow-http-src-ip" {
  name    = "allow-http-src-ip"
  network = google_compute_network.vpc-fw-test.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["10.1.1.0/24"]
  target_tags = [ "allow-http-src-ip" ]

  depends_on = [ google_compute_network.vpc-fw-test ]
}

resource "google_compute_instance" "allow-http-src-ip" {
  name         = "allow-http-src-ip"
  machine_type = "e2-small"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 10

    }
  }

  network_interface {
    network = "vpc-fw-test"
    subnetwork = google_compute_subnetwork.vpc-fw-test-snet.self_link

        access_config {
      // Ephemeral public IP
    }
  }

    tags = [ "allow-http-src-ip", "ssh" ]
  metadata_startup_script = <<-EOF
                            apt update 
                            apt -y install apache2 
                            EOF

}



#F/w allowing http from source-tags 
resource "google_compute_firewall" "allow-http-src-tag" {
  name    = "allow-http-src-tag"
  network = google_compute_network.vpc-fw-test.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
    
  }

  target_tags = [ "allow-http-src-tag" ]
  source_tags = ["allow-http-0000"]

  depends_on = [ google_compute_network.vpc-fw-test ]
}

resource "google_compute_instance" "allow-http-src-tag" {
  name         = "allow-http-src-tag"
  machine_type = "e2-small"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 10

    }
  }

  network_interface {
    network = "vpc-fw-test"
    subnetwork = google_compute_subnetwork.vpc-fw-test-snet.self_link

        access_config {
      // Ephemeral public IP
    }
  }

    tags = [ "allow-http-src-tag", "ssh" ]
  metadata_startup_script = <<-EOF
                            apt update 
                            apt -y install apache2 
                            EOF

}

