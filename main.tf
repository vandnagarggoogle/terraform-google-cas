/**
 * Copyright 2026 Google LLC
 */

locals {
  # Logic: Use existing pool if provided, otherwise use the newly created one
  ca_pool_id = (
    var.ca_pool_config.use_pool != null
    ? var.ca_pool_config.use_pool.id
    : try(google_privateca_ca_pool.default[0].id, null)
  )
}

# 1. Enable the Private CA API
resource "google_project_service" "privateca_api" {
  project            = var.project_id 
  service            = "privateca.googleapis.com"
  disable_on_destroy = false
}

# 2. Handle API propagation delay (Standard best practice)
resource "time_sleep" "wait_for_privateca_api" {
  depends_on      = [google_project_service.privateca_api]
  create_duration = "30s"
}

# 3. Create the CA Pool (Single block with dependency)
resource "google_privateca_ca_pool" "default" {
  count    = var.ca_pool_config.create_pool != null ? 1 : 0
  name     = var.ca_pool_config.create_pool.name
  location = var.location
  project  = var.project_id
  tier     = var.ca_pool_config.create_pool.enterprise_tier ? "ENTERPRISE" : "DEVOPS"

  # Wait for the API to be fully functional
  depends_on = [time_sleep.wait_for_privateca_api]
}

# 4. Create CAs based on the ca_configs map
resource "google_privateca_certificate_authority" "default" {
  for_each = var.ca_configs

  pool                     = local.ca_pool_id
  certificate_authority_id = each.key
  location                 = var.location
  project                  = var.project_id
  
  deletion_protection      = each.value.deletion_protection
  skip_grace_period        = each.value.skip_grace_period
  ignore_active_certificates_on_deletion = each.value.ignore_active_certificates_on_deletion
  gcs_bucket               = each.value.gcs_bucket
  labels                   = each.value.labels

  config {
    subject_config {
      subject {
        common_name         = each.value.subject.common_name
        organization        = each.value.subject.organization
        country_code        = each.value.subject.country_code
        locality            = each.value.subject.locality
        organizational_unit = each.value.subject.organizational_unit
        postal_code         = each.value.subject.postal_code
        province            = each.value.subject.province
        street_address      = each.value.subject.street_address
      }
      dynamic "subject_alt_name" {
        for_each = each.value.subject_alt_name != null ? [1] : []
        content {
          dns_names       = each.value.subject_alt_name.dns_names
          email_addresses = each.value.subject_alt_name.email_addresses
          ip_addresses    = each.value.subject_alt_name.ip_addresses
          uris            = each.value.subject_alt_name.uris
        }
      }
    }
    x509_config {
      ca_options {
        is_ca = each.value.is_ca
      }
      key_usage {
        base_key_usage {
          cert_sign          = each.value.key_usage.cert_sign
          content_commitment = each.value.key_usage.content_commitment
          crl_sign           = each.value.key_usage.crl_sign
          data_encipherment  = each.value.key_usage.data_encipherment
          decipher_only      = each.value.key_usage.decipher_only
          digital_signature  = each.value.key_usage.digital_signature
          encipher_only      = each.value.key_usage.encipher_only
          key_agreement      = each.value.key_usage.key_agreement
          key_encipherment   = each.value.key_usage.key_encipherment
        }
        extended_key_usage {
          client_auth      = each.value.key_usage.client_auth
          code_signing     = each.value.key_usage.code_signing
          email_protection = each.value.key_usage.email_protection
          ocsp_signing     = each.value.key_usage.ocsp_signing
          server_auth      = each.value.key_usage.server_auth
          time_stamping    = each.value.key_usage.time_stamping
        }
      }
    }
  }

  key_spec {
    algorithm             = each.value.key_spec.algorithm
    cloud_kms_key_version = each.value.key_spec.kms_key_id
  }

  dynamic "subordinate_config" {
    for_each = each.value.subordinate_config != null ? [1] : []
    content {
      certificate_authority = each.value.subordinate_config.root_ca_id
      dynamic "pem_issuer_chain" {
        for_each = each.value.subordinate_config.pem_issuer_certificates != null ? [1] : []
        content {
          pem_certificates = each.value.subordinate_config.pem_issuer_certificates
        }
      }
    }
  }

  # Ensure the CA also waits for the API
  depends_on = [time_sleep.wait_for_privateca_api]
}

# 5. IAM Bindings for the CA Pool
resource "google_privateca_ca_pool_iam_member" "default" {
  for_each = var.iam
  ca_pool  = local.ca_pool_id
  role     = each.value.role
  member   = each.value.member
  
  # This correctly waits for the pool creation
  depends_on = [google_privateca_ca_pool.default]
}
