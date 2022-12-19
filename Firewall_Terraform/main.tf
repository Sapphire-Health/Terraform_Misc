## Configure the Microsoft Azure Provider
## <https://www.terraform.io/docs/providers/azurerm/index.html>
terraform {
  backend "local"  {

  }

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.34.0"
    }
  }
}

provider "azurerm" {
  features {}
  
}

###############Get existing data sources###############
data "azurerm_subnet" "fw_subnet" {
  name                 = var.subnetname
  virtual_network_name = var.vnetname
  resource_group_name  = var.subnetrgname
}

##############Application Gateway############
resource "azurerm_public_ip" "epicro_fw_hsw_pip" {
  name                = "epicro-fw-hsw-pip"
  resource_group_name = var.subnetrgname
  location            = var.location
  allocation_method   = "Static"
  sku 				  = "Standard"
  tags = {
	  Terraform = "Yes"
  }  
}

resource "azurerm_public_ip" "epicro_fw_icfg_pip" {
  name                = "epicro-fw-icfg-pip"
  resource_group_name = var.subnetrgname
  location            = var.location
  allocation_method   = "Static"
  sku 				  = "Standard"
  tags = {
	  Terraform = "Yes"
  }  
}

resource "azurerm_firewall" "epicro_fw" {
  name                 = "epicro-firewall"
  resource_group_name  = var.subnetrgname
  location             = var.location
  firewall_policy_id   = azurerm_firewall_policy.firewallpol.id
  sku_name = "AZFW_VNet"
  sku_tier = "Standard"
  threat_intel_mode = "Deny"
  
  ip_configuration {
	  name                 = "epicro-firewall-hsw-ipconfig"
	  subnet_id			   = data.azurerm_subnet.fw_subnet.id
	  public_ip_address_id = azurerm_public_ip.epicro_fw_hsw_pip.id
  }

  ip_configuration {
	  name                 = "epicro-firewall-icfg-ipconfig"
	  public_ip_address_id = azurerm_public_ip.epicro_fw_icfg_pip.id
  }
  
  tags = {
	  Terraform = "Yes"
  }
  depends_on = [
    azurerm_firewall_policy.firewallpol
  ]  
}

resource "azurerm_firewall_policy" "firewallpol" {
  name                     = "epicro-appgw-wafpolicy"
  resource_group_name      = var.subnetrgname
  location                 = var.location
  sku				       = "Standard"
  threat_intelligence_mode = "Deny"


  tags = {
	  Terraform = "Yes"
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "natcollectiongrp" {
  name               = "epicro-fwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.firewallpol.id
  priority           = 100
  nat_rule_collection {
    name     = "hsw_http_nat_rule_collection"
    priority = 100
    action   = "Dnat"
    rule {
      name                = "hsw_nat_rule"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.epicro_fw_hsw_pip.ip_address
      destination_ports   = ["80"]
      translated_address  = var.hswvip
	  translated_port	  = "80"
    }
  }
  nat_rule_collection {
    name     = "hsw_https_nat_rule_collection"
    priority = 110
    action   = "Dnat"
    rule {
      name                = "hsw_nat_rule"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.epicro_fw_hsw_pip.ip_address
      destination_ports   = ["443"]
      translated_address  = var.hswvip
	  translated_port	  = "443"
    }
  }  
  nat_rule_collection {
    name     = "icfg_http_nat_rule_collection"
    priority = 200
    action   = "Dnat"
    rule {
      name                = "icfg_nat_rule"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.epicro_fw_icfg_pip.ip_address
      destination_ports   = ["80"]
      translated_address  = var.icfgvip
	  translated_port	  = "80"
    }
  }  
  nat_rule_collection {
    name     = "icfg_https_nat_rule_collection"
    priority = 220
    action   = "Dnat"
    rule {
      name                = "icfg_nat_rule"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.epicro_fw_icfg_pip.ip_address
      destination_ports   = ["443"]
      translated_address  = var.icfgvip
	  translated_port	  = "443"
    }
  }    
}