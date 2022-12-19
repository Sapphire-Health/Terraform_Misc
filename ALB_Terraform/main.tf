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
data "azurerm_subnet" "appgw_subnet" {
  name                 = var.subnetname
  virtual_network_name = var.vnetname
  resource_group_name  = var.subnetrgname
}

data "azurerm_user_assigned_identity" "identity" {
  name                = var.identityname
  resource_group_name = var.identityrg
}

##############Application Gateway############
resource "azurerm_public_ip" "epicro_appgw_pip" {
  name                = "epicro-appgw-pip"
  resource_group_name = var.resourcegrp
  location            = var.location
  allocation_method   = "Static"
  sku 				  = "Standard"
  tags = {
	  Terraform = "Yes"
  }  
}

locals {
  hsw_vip_address_pool_name            = "hsw-vip-backendpool"
  icfg_backend_address_pool_name       = "icfg-backendpool"
  hsw_servers_address_pool_name        = "hsw-servers-backendpool"
  http_frontend_port_name              = "epicro-appgw-httpport"
  https_frontend_port_name             = "epicro-appgw-httpsport"
  frontend_ip_configuration_name       = "epicro-appgw-feip"  
  hsw_http_setting_name                = "epicro-appgw-hswbacksettings-http"
  hsw_https_setting_name               = "epicro-appgw-hswbacksettings-https"
  icfg_http_setting_name               = "epicro-appgw-icfgbacksettings-http"
  icfg_https_setting_name              = "epicro-appgw-icfgbacksettings-https"  
  hsw_probe_name					   = "epicro-appgw-hswprobe"
  hsw_hostname						   = "epicro.tvc.org"
  icfg_probe_name					   = "epicro-appgw-icfgprobe"  
  icfg_hostname						   = "soapprod.tvc.org"  
  hsw_cert_name						   = "epicro-hswcert"
  icfg_cert_name					   = "epicro-icfgcert" 
  ssl_profile_name	  				   = "epicro-appgw-sslprofile"
  ssl_policy_name					   = "AppGwSslPolicy20220101"
  icfg_http_listener_name              = "icfg-httplstn"
  icfg_https_listener_name             = "icfg-httpslstn"  
  hsw_http_listener_name               = "hsw-httplstn"
  hsw_https_listener_name              = "hsw-httpslstn"  
  icfg_redirect_name                   = "icfg-https-redirect"
  hsw_redirect_name                    = "hsw-https-redirect"  
  icfg_http_request_routing_rule_name  = "icfg-http-rqrt"
  icfg_https_request_routing_rule_name = "icfg-https-rdrcfg"
  hsw_http_request_routing_rule_name   = "hsw-http-rqrt"
  hsw_https_request_routing_rule_name  = "hsw-https-rdrcfg"  
}

resource "azurerm_application_gateway" "appgw" {
  name                = "epicro-appgateway"
  resource_group_name = var.resourcegrp
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.appgw_firewallpol.id
  
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = "1"
    max_capacity = "5"
  }

  identity {
	type = "UserAssigned"
	identity_ids = [data.azurerm_user_assigned_identity.identity.id]
  }
  
  gateway_ip_configuration {
    name      = "epicro-gatewayip-config"
    subnet_id = data.azurerm_subnet.appgw_subnet.id
  }

  backend_address_pool {
    name                           = local.hsw_vip_address_pool_name 
    ip_addresses                   = var.hswvip
  }

  backend_address_pool {
    name                           = local.icfg_backend_address_pool_name 
    ip_addresses                   = var.icfgvip
  }

  backend_address_pool {
    name                           = local.hsw_servers_address_pool_name 
    ip_addresses                   = var.hswservers
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.epicro_appgw_pip.id
  }

  frontend_port {
    name = local.http_frontend_port_name
    port = 80
  }

  frontend_port {
    name = local.https_frontend_port_name
    port = 443
  }

  backend_http_settings {
    name                  = local.hsw_http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  backend_http_settings {
    name                  = local.hsw_https_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 30
	probe_name			  = local.hsw_probe_name
  }  

  backend_http_settings {
    name                  = local.icfg_http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  backend_http_settings {
    name                  = local.icfg_https_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 30
	probe_name			  = local.icfg_probe_name	
  }  

  probe {
	name				  = local.hsw_probe_name
	protocol              = "Https"
	host				  = local.hsw_hostname
	path				  = "/"
	interval			  = "10"
	timeout				  = "10"
	unhealthy_threshold   = "3"	
  }

  probe {
	name				  = local.icfg_probe_name
	protocol              = "Https"
	host				  = local.icfg_hostname
	path				  = "/"
	interval			  = "10"
	timeout				  = "10"
	unhealthy_threshold   = "3"	
  }

  ssl_certificate {
	name 				  = local.hsw_cert_name
	key_vault_secret_id   = var.hswcertid
  }

  ssl_certificate {
	name 				  = local.icfg_cert_name
	key_vault_secret_id   = var.icfgcertid
  }
  
  ssl_policy {
	  policy_type = "Predefined"
	  policy_name = local.ssl_policy_name
  }
 
  http_listener {
    name                           = local.hsw_http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.http_frontend_port_name
    protocol                       = "Http"
    host_name                      = var.hswurl
  }

  http_listener {
    name                           = local.hsw_https_listener_name 
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.https_frontend_port_name
    protocol                       = "Https"
	ssl_certificate_name		   = local.hsw_cert_name
    host_name                      = var.hswurl
  }    

  http_listener {
    name                           = local.icfg_http_listener_name 
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.http_frontend_port_name
    protocol                       = "Http"
    host_name                      = var.icfgurl
  }

  http_listener {
    name                           = local.icfg_https_listener_name 
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.https_frontend_port_name
    protocol                       = "Https"
	ssl_certificate_name		   = local.icfg_cert_name
    host_name                      = var.icfgurl
  }    

  redirect_configuration {
    name                  = local.hsw_redirect_name
    redirect_type         = "Permanent"
    target_listener_name  = local.hsw_https_listener_name 
    include_path          = "true"
    include_query_string  = "true"
  }

  redirect_configuration {
    name                  = local.icfg_redirect_name
    redirect_type         = "Permanent"
    target_listener_name  = local.icfg_https_listener_name 
    include_path          = "true"
    include_query_string  = "true"
  }

  request_routing_rule {
    name                        = local.hsw_http_request_routing_rule_name
    rule_type                   = "Basic"
    http_listener_name          = local.hsw_http_listener_name
    redirect_configuration_name = local.hsw_redirect_name
	priority					= "10"
  }      

  request_routing_rule {
    name                        = local.hsw_https_request_routing_rule_name
    rule_type                   = "Basic"
    http_listener_name          = local.hsw_https_listener_name
    backend_address_pool_name   = local.hsw_servers_address_pool_name 
    backend_http_settings_name  = local.hsw_https_setting_name
	priority					= "20"	
  }  

  request_routing_rule {
    name                        = local.icfg_http_request_routing_rule_name
    rule_type                   = "Basic"
    http_listener_name          = local.icfg_http_listener_name
    redirect_configuration_name = local.icfg_redirect_name
	priority					= "30"	
  }  

  request_routing_rule {
    name                        = local.icfg_https_request_routing_rule_name
    rule_type                   = "Basic"
    http_listener_name          = local.icfg_https_listener_name
    backend_address_pool_name   = local.icfg_backend_address_pool_name 
    backend_http_settings_name  = local.icfg_https_setting_name
	priority					= "40"	
  }  

  tags = {
	  Terraform = "Yes"
  }
  depends_on = [
    azurerm_web_application_firewall_policy.appgw_firewallpol
  ]  
}

resource "azurerm_web_application_firewall_policy" "appgw_firewallpol" {
  name                = "epicro-appgw-wafpolicy"
  resource_group_name = var.resourcegrp
  location            = var.location

  custom_rules {
    name      = "GeoFilter"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "GeoMatch"
      negation_condition = true
      match_values       = ["US"]
	  transforms		 = ["Lowercase"]
    }

    action = "Block"
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}