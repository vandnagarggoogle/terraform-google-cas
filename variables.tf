variable "project_id" {
  description = "The project ID to host the CAS resources."
  type        = string
}

variable "location" {
  description = "The location of the CAs (e.g., us-central1). Must match your SWP region."
  type        = string
}

variable "ca_pool_config" {
  description = "The CA pool config. Provide 'create_pool' to make a new one or 'use_pool' for an existing one."
  type = object({
    create_pool = optional(object({
      name            = string
      enterprise_tier = optional(bool, false)
    }))
    use_pool = optional(object({
      id = string
    }))
  })
}

variable "ca_configs" {
  description = "The CA configurations. Keys are the CA IDs."
  type = map(object({
    is_ca                                  = optional(bool, true)
    deletion_protection                    = optional(bool, false)
    skip_grace_period                      = optional(bool, true)
    ignore_active_certificates_on_deletion = optional(bool, false)
    gcs_bucket                             = optional(string)
    labels                                 = optional(map(string), {})
    subject = object({
      common_name         = string
      organization        = string
      country_code        = optional(string)
      locality            = optional(string)
      organizational_unit = optional(string)
      postal_code         = optional(string)
      province            = optional(string)
      street_address      = optional(string)
    })
    subject_alt_name = optional(object({
      dns_names       = optional(list(string))
      email_addresses = optional(list(string))
      ip_addresses    = optional(list(string))
      uris            = optional(list(string))
    }))
    key_usage = object({
      cert_sign          = optional(bool, true)
      crl_sign           = optional(bool, true)
      server_auth        = optional(bool, true)
      client_auth        = optional(bool, false)
      code_signing       = optional(bool, false)
      content_commitment = optional(bool, false)
      data_encipherment  = optional(bool, false)
      decipher_only      = optional(bool, false)
      digital_signature  = optional(bool, false)
      email_protection   = optional(bool, false)
      encipher_only      = optional(bool, false)
      key_agreement      = optional(bool, false)
      key_encipherment   = optional(bool, true)
      ocsp_signing       = optional(bool, false)
      time_stamping      = optional(bool, false)
    })
    key_spec = object({
      algorithm  = optional(string, "RSA_PKCS1_2048_SHA256")
      kms_key_id = optional(string)
    })
    subordinate_config = optional(object({
      root_ca_id               = string
      pem_issuer_certificates = optional(list(string))
    }))
  }))
  default = {}
}
