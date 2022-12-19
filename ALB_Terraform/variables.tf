variable "location" {
    type = string
    description = "Azure location of terraform server environment"
    default = "westus2"
}

variable "resourcegrp" {
	type = string
	description = "Resource Group to build the App Gateway in"
}

variable "subnetname" {
	type = string
	description = "The name of the pre-existing subnet that will contain the App Gateway"
}

variable "vnetname" {
	type = string
	description = "The name of the pre-existing vnet that will contain the App Gateway"
}

variable "subnetrgname" {
	type = string
	description = "The name of the resource group that the subnet is in"
}

variable "identityname" {
	type = string
	description = "The name of the Managed Identity that has permissions to GET the certificates"
}

variable "identityrg" {
	type = string
	description = "The resource group of the Managed Identity that has permissions to GET the certificates"
}

variable "hswvip" {
    type = list
    description = "List of Netscaler HSW VIPs"
}

variable "hswservers" {
    type = list
    description = "List of Netscaler HSW server IPs"
}

variable "hswurl" {
	type = string
	description = "The URL that will be used to access Hyperspace Web via Chrome/Edge"
}

variable "hswcertid" {
	type = string
	description = "The secret identifier of the HSW certificate in Azure Keyvault"
}

variable "icfgvip" {
    type = list
    description = "List of Netscaler Interconnect Haiku/Canto VIPs"
}

variable "icfgurl" {
	type = string
	description = "The URL that will be used to access Haiku/Canto"
}

variable "icfgcertid" {
	type = string
	description = "The secret identifier of the HSW certificate in Azure Keyvault"
}