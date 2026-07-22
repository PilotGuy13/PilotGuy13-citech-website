# CIT corporate site — Azure Static Web App (Free).
# STAGE A: resource group + SWA only. Custom domain + Cloudflare DNS cutover
# live in stage-b.tf (kept separate so we verify on the *.azurestaticapps.net
# default host BEFORE any DNS change — instant rollback preserved).

resource "azurerm_resource_group" "cit" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_static_web_app" "cit" {
  name                = var.swa_name
  resource_group_name = azurerm_resource_group.cit.name
  location            = azurerm_resource_group.cit.location
  sku_tier            = "Free"
  sku_size            = "Free"
}

output "swa_default_host" {
  description = "Test URL — verify the site here before any DNS cutover."
  value       = azurerm_static_web_app.cit.default_host_name
}

output "swa_api_token" {
  description = "Deploy token for GitHub Actions (set as repo secret AZURE_SWA_TOKEN)."
  value       = azurerm_static_web_app.cit.api_key
  sensitive   = true
}
