variable "project_location" {
  default = "southeastasia"
}

variable "res_group_name" {
  default = "secured-aml-rg"
}

variable "dev_team_group_name" {
  default = "PartnerDevelopersGroup_2"
}

data "azurerm_client_config" "current" {}

# data "azuread_group" "dev_team_group" {
#   name = var.dev_team_group_name
# }

provider "msgraph" {}
resource "msgraph_group" "group" {
  display_name  = var.dev_team_group_name
  mail_nickname = var.dev_team_group_name
}

# Create a resource group for the project
resource "azurerm_resource_group" "project_rg" {
  name     = var.res_group_name
  location = var.project_location
}

# Assign the AAD team group to the resource group as Contributor
resource "azurerm_role_assignment" "rg_contributor_role" {
  scope                = azurerm_resource_group.project_rg.id
  role_definition_name = "Contributor"
  principal_id         = msgraph_group.group.id
}

