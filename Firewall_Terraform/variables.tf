variable "location" {
    type = string
    description = "Azure location of terraform server environment"
    default = "westus2"
}

variable "subnetname" {
	type = string
	description = "The name of the pre-existing subnet that will contain the Firewall"
}

variable "vnetname" {
	type = string
	description = "The name of the pre-existing vnet that will contain the Firewall"
}

variable "subnetrgname" {
	type = string
	description = "The name of the resource group that the Firewall subnet is in"
}

variable "hswvip" {
    type = string
    description = "Netscaler HSW VIPs"
}

variable "icfgvip" {
    type = string
    description = "Netscaler Interconnect Haiku/Canto VIPs"
}
