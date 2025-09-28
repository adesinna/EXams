resource "google_compute_instance" "vm-1" {
  name         = "my-first-vm"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  tags = ["web-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 20
      labels = {
        env = "dev"
      }
    }
  }


  network_interface {
    network    = google_compute_network.my_vpc.id
    subnetwork = google_compute_subnetwork.my_subnet.id

    access_config {
//    nat_ip = google_compute_address.static_ip.address   # static ip
    }
  }

  # Reference the local script.sh file
  metadata = {
    startup-script = file("script.sh")
  }
}

//resource "google_compute_address" "static_ip" {
//  name   = "my-static-ip"
//  region = "us-central1"  # must match your subnet region
//}
