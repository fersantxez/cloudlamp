resource "google_compute_disk" "default" {
  name = "${var.nfs_disk_name}"
  type = "${var.nfs_raw_disk_type}"
  zone = "${var.gcp_zone}"
}

output "self_link_compute_disk" {
  value = "${google_compute_disk.default.self_link}"
}

data "template_file" "nfs_startup_template" {
  template = "${file("nfs_startup_script.sh.tpl")}"

  vars {
    nfs_disk_name = "${var.nfs_disk_name}"
  }
}

resource "google_compute_instance" "nfs_server" {
  zone = "${var.gcp_zone}"
  name = "${var.nfs_server_name}"

  machine_type = "${var.nfs_machine_type}"

  boot_disk {
    initialize_params {
      image = "${var.nfs_server_os_image}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  attached_disk {
    source      = "${google_compute_disk.default.name}"
    device_name = "${var.nfs_disk_name}"
  }

  metadata_startup_script = "${data.template_file.nfs_startup_template.rendered}"
}

output "nfs_instance_id" {
  value = "${google_compute_instance.nfs_server.self_link}"
}

output "nfs_private_ip" {
  value = "${google_compute_instance.nfs_server.network_interface.0.address}"
}

# Sab comment TODO - figure out if this is needed:
# output "nfs_public_ip" {
#   value = "${google_compute_instance.nfs_server.network_interface.0.access_config.0.assigned_nat_ip}"
# }

