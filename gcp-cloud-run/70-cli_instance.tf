
#################
### Vault CLI ###
#################
locals {
  vault_cli_zone                   = coalesce(var.vault_cli_zone, var.default_zone)
  vault_url                        = google_cloud_run_service.nginx_proxy.status[0].url
  service_account_access_token_url = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
  admin_key_secret_url             = "https://secretmanager.googleapis.com/v1/${google_secret_manager_secret_version.admin_api_key_version.id}:access"
}

resource "google_service_account" "pvault-cli-sa" {
  account_id   = "${var.deployment_id}-pvault-cli"
  display_name = "${var.deployment_id}-pvault-cli service account"
}

resource "google_compute_instance" "vault-cli" {
  name         = "${var.deployment_id}-vm-pvault-cli"
  machine_type = "e2-micro"
  zone         = local.vault_cli_zone

  boot_disk {
    initialize_params {
      image = "projects/cos-cloud/global/images/cos-97-16919-29-36"
    }
    auto_delete = true
    mode        = "READ_WRITE"
  }

  network_interface {
    network    = module.vpc.network_name
    subnetwork = module.vpc.subnets["${local.client_region}/${var.deployment_id}-${var.vault_cli_subnet}-${var.env}"].id
  }

  service_account {
    email  = google_service_account.pvault-cli-sa.email
    scopes = ["cloud-platform", "compute-rw"]
  }

  metadata_startup_script = <<-EOF
sudo echo "#!/bin/bash
# Get service account access token from GCP metadata endpoint.
ACCESS_TOKEN=\$(curl -s -H 'Metadata-Flavor: Google' ${local.service_account_access_token_url} | jq -r '.access_token')

# Get the vault admin API key from GCP secrets manager.
VAULT_ADMIN_KEY=\$(curl -s ${local.admin_key_secret_url} --request GET --header \"authorization: Bearer \$ACCESS_TOKEN\" | jq -r '.payload.data' | base64 --decode)

# Create an alias for pvault CLI and configure its address and token.
alias pvault='docker run -it ${var.cli_image}:${var.pvault_tag} --addr ${local.vault_url} --authtoken \$VAULT_ADMIN_KEY'
" > /etc/profile.d/pvault.sh

sudo chmod +x /etc/profile.d/pvault.sh

sudo useradd -m tmpuser
sudo usermod -aG docker tmpuser
sudo -u tmpuser docker-credential-gcr configure-docker --registries us-central1-docker.pkg.dev
sudo -u tmpuser docker pull ${var.cli_image}:${var.pvault_tag}
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
" > /etc/profile.d/shoutdown-inactive.sh
sudo chmod +x /etc/profile.d/shoutdown-inactive.sh

sudo ./etc/profile.d/shoutdown-inactive.sh
EOF

  depends_on = [
    module.vpc,
    google_project_service.apis
  ]
}
