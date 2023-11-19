
###########
### KMS ###
###########

locals {
  kms_ring_name = "key-ring"
}

resource "google_kms_key_ring" "db_keyring" {
  name       = "${var.deployment_id}-db-vault-${local.kms_ring_name}"
  location   = local.db_region
  depends_on = [google_project_service.apis]
}

resource "google_kms_key_ring" "vault_keyring" {
  name       = "${var.deployment_id}-vault-encription-${local.kms_ring_name}"
  location   = local.pvault_region
  depends_on = [google_project_service.apis]
}

resource "google_kms_crypto_key" "db-encryption-key" {
  name     = "${var.deployment_id}-db-key"
  key_ring = google_kms_key_ring.db_keyring.id
  purpose  = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "vault-encryption-key" {
  name     = "${var.deployment_id}-vault-key"
  key_ring = google_kms_key_ring.vault_keyring.id
  purpose  = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  service  = "sqladmin.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "crypto_key_cloud_run" {
  crypto_key_id = google_kms_crypto_key.vault-encryption-key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.pvault-server-sa.email}"
}

resource "google_kms_crypto_key_iam_member" "crypto_key_db" {
  crypto_key_id = google_kms_crypto_key.db-encryption-key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}"
}
