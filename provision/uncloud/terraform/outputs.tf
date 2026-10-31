output "bridge_gateway_ip" {
  description = "Bridge interface (br-uncloud) gateway and Technitium DNS IP"
  value       = local.gateway_ip
}

output "seed_node_ip" {
  description = "IP of the Uncloud seed node (uc-node-1)"
  value       = local.nodes[0].ip
}

output "domain_suffix" {
  description = "Internal DNS zone suffix for the lab"
  value       = var.domain_suffix
}

output "technitium_web_console" {
  description = "Technitium DNS Server web console URL"
  value       = "http://dns.${var.domain_suffix}:${var.dns_web_port}"
}

output "nodes" {
  description = "Provisioned Uncloud VM nodes and their static IPs/FQDNs"
  value = [
    for node in local.nodes : {
      name = node.name
      ip   = node.ip
      fqdn = node.fqdn
      ssh  = "ssh -i ${local.ssh_key_path} ${var.ssh_user}@${node.ip}"
    }
  ]
}

output "uncloud_config_path" {
  description = "Isolated Uncloud CLI configuration file path for this lab"
  value       = local.uncloud_cfg
}

output "caddy_root_ca_path" {
  description = "Path to the extracted Caddy internal PKI Root CA certificate"
  value       = local.root_ca_path
}
