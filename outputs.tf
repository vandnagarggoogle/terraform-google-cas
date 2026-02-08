output "ca_pool_id" {
  description = "The ID of the CA Pool."
  value       = local.ca_pool_id
}

output "ca_ids" {
  description = "Map of CA IDs created."
  value       = { for k, v in google_privateca_certificate_authority.default : k => v.id }
}

output "ca_pool" {
  description = "The CA pool resource object."
  value       = try(google_privateca_ca_pool.default[0], null)
}
