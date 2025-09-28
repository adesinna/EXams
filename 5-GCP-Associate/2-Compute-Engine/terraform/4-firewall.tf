resource "google_compute_firewall" "http" {
  name    = "server-firewall-http"
  network = google_compute_network.my_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "ssh" {
  name    = "server-firewall-ssh"
  network = google_compute_network.my_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["18.203.115.61/32"]
  target_tags   = ["web-server"]
  direction     = "INGRESS"
}