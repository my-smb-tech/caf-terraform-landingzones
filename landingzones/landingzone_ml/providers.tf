# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {
  version = "=0.7.0"
}

# Configure the Random Provider.
# It is useful to generate random numbers, strings, and passwords.
provider "random" {
  version = "~>2.2"
}