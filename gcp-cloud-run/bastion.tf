#####################
### Vault bastion ###
#####################
resource "google_service_account" "pvault-bastion-sa" {
  count = var.create_bastion ? 1 : 0

  account_id   = "${var.deployment_id}-pvault-bastion"
  display_name = "${var.deployment_id}-pvault-bastion service account"
}

resource "google_compute_instance" "pvault-bastion" {
  count = var.create_bastion ? 1 : 0

  name         = "${var.deployment_id}-vm-pvault-bastion"
  machine_type = "e2-small"
  zone         = local.vault_bastion_zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos_lts.self_link
    }
    auto_delete = true
    mode        = "READ_WRITE"
  }

  network_interface {
    network    = local.network
    subnetwork = local.bastion_subnetwork
  }

  service_account {
    email  = google_service_account.pvault-bastion-sa[0].email
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true

  metadata_startup_script = <<-EOF
    sudo echo "#!/bin/bash
    # Get service account access token from GCP metadata endpoint.
    ACCESS_TOKEN=\$(curl -s -H 'Metadata-Flavor: Google' ${local.service_account_access_token_url} | jq -r '.access_token')

    # Get the vault admin API key from GCP secrets manager.
    VAULT_ADMIN_KEY=\$(curl -s ${local.admin_key_secret_url} --request GET --header \"authorization: Bearer \$ACCESS_TOKEN\" | jq -r '.payload.data' | base64 --decode)

    # Create an alias for pvault CLI and configure its address and token.
    alias pvault='docker run -u $(id -u):$(id -g) -it -v \$(pwd):/pwd -w /pwd ${var.pvault_cli_repository}:${var.pvault_tag} --addr ${local.vault_url} --authtoken \$VAULT_ADMIN_KEY'
    " > /etc/profile.d/pvault.sh

    sudo chmod +x /etc/profile.d/pvault.sh

    sudo useradd -m tmpuser
    sudo usermod -aG docker tmpuser
    sudo -u tmpuser docker-credential-gcr configure-docker --registries us-central1-docker.pkg.dev
    sudo -u tmpuser docker pull ${var.pvault_cli_repository}:${var.pvault_tag}
    userdel -d tmpuser

    sudo echo "#!/bin/bash
    count=0
    while true; do
      if who | grep -v tmux &>/dev/null ; then
        count=0
      else
        ((count+=1))
      fi
      if ((count>4)) ; then
        sudo poweroff
      fi
      sleep 120
    done &
    " > /etc/profile.d/shutdown-inactive.sh
    sudo chmod +x /etc/profile.d/shutdown-inactive.sh

    sudo ./etc/profile.d/shutdown-inactive.sh
  EOF

  depends_on = [
    module.vpc[0],
    var.vpc_id,
    google_project_service.apis
  ]
}
