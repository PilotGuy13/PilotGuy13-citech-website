variable "subscription_id" {
  description = "Azure subscription ID (a77d4636-... — CIT hello@citechnologies.io)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding the CIT website infra"
  type        = string
  default     = "rg-cit-website-prod"
}

variable "location" {
  description = "SWA metadata region (must be a Static-Web-Apps-supported region; content is global CDN regardless). Valid: centralus, eastus2, westus2, westeurope, eastasia."
  type        = string
  default     = "eastasia"
}

variable "swa_name" {
  description = "Static Web App resource name"
  type        = string
  default     = "swa-cit-website"
}
