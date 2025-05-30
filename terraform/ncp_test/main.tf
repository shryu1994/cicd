provider "ncloud" {
  support_vpc = true
  region      = var.region
  access_key  = var.access_key
  secret_key  = var.secret_key
}

resource "ncloud_login_key" "key_shryu" {
  key_name = var.name_shryu
}

resource "ncloud_vpc" "vpc_shryu" {
  name            = var.name_shryu
  ipv4_cidr_block = var.vpc_ipv4_cidr
}

resource "ncloud_subnet" "subnet_public" {
  name           = "${var.name_shryu}-public"
  vpc_no         = ncloud_vpc.vpc_shryu.id
  subnet         = cidrsubnet(ncloud_vpc.vpc_shryu.ipv4_cidr_block, 8, 0)
  // 10.0.0.0/24
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.network_acl_shryu_public.id
  subnet_type    = "PUBLIC"
  // PUBLIC(Public) | PRIVATE(Private)
}

resource "ncloud_subnet" "subnet_private" {
  name           = "${var.name_shryu}-private"
  vpc_no         = ncloud_vpc.vpc_shryu.id
  subnet         = cidrsubnet(ncloud_vpc.vpc_shryu.ipv4_cidr_block, 8, 1)
  // 10.0.1.0/24
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.network_acl_shryu_private.id
  subnet_type    = "PRIVATE"
  // PUBLIC(Public) | PRIVATE(Private)
}

resource "ncloud_subnet" "subnet_shryu_public_natgw" {
  vpc_no         = ncloud_vpc.vpc_shryu.id
  subnet         = cidrsubnet(ncloud_vpc.vpc_shryu.ipv4_cidr_block, 8, 2)
  // "10.0.2.0/24"
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.network_acl_shryu_public.id
  subnet_type    = "PUBLIC"
  usage_type     = "NATGW"
}

# Network ACL
resource "ncloud_network_acl" "network_acl_shryu_public" {
  vpc_no = ncloud_vpc.vpc_shryu.id
  name   = "${var.name_shryu}-public"
}

resource "ncloud_network_acl" "network_acl_shryu_private" {
  vpc_no = ncloud_vpc.vpc_shryu.id
  name   = "${var.name_shryu}-private"
}

# Server
resource "ncloud_server" "server_shryu_git" {
  subnet_no                 = ncloud_subnet.subnet_public.id
  name                      = "${var.name_shryu}-git"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
  login_key_name            = ncloud_login_key.key_shryu.key_name
  //server_product_code       = "SVR.VSVR.STAND.C002.M008.NET.SSD.B050.G002"
}

resource "ncloud_server" "server_shryu_jenkins" {
  subnet_no                 = ncloud_subnet.subnet_public.id
  name                      = "${var.name_shryu}-jenkins"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
  login_key_name            = ncloud_login_key.key_shryu.key_name
  //server_product_code       = "SVR.VSVR.STAND.C002.M008.NET.SSD.B050.G002"
}

resource "ncloud_server" "server_shryu_harbor" {
  subnet_no                 = ncloud_subnet.subnet_public.id
  name                      = "${var.name_shryu}-harbor"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
  login_key_name            = ncloud_login_key.key_shryu.key_name
  //server_product_code       = "SVR.VSVR.STAND.C002.M008.NET.SSD.B050.G002"
}

# Public IP
resource "ncloud_public_ip" "public_ip_git" {
  server_instance_no = ncloud_server.server_shryu_git.id
  description        = "for ${var.name_shryu}"
}

resource "ncloud_public_ip" "public_ip_jenkins" {
  server_instance_no = ncloud_server.server_shryu_jenkins.id
  description        = "for ${var.name_shryu}"
}

resource "ncloud_public_ip" "public_ip_harbor" {
  server_instance_no = ncloud_server.server_shryu_harbor.id
  description        = "for ${var.name_shryu}"
}

# NAT Gateway
resource "ncloud_nat_gateway" "nat_gateway_shryu" {
  vpc_no    = ncloud_vpc.vpc_shryu.id
  subnet_no = ncloud_subnet.subnet_shryu_public_natgw.id
  zone      = "KR-2"
  name      = var.name_shryu
}

# Route Table
resource "ncloud_route" "route_shryu_nat" {
  route_table_no         = ncloud_vpc.vpc_shryu.default_private_route_table_no
  destination_cidr_block = "0.0.0.0/0"
  target_type            = "NATGW"
  // NATGW (NAT Gateway) | VPCPEERING (VPC Peering) | VGW (Virtual Private Gateway).
  target_name            = ncloud_nat_gateway.nat_gateway_shryu.name
  target_no              = ncloud_nat_gateway.nat_gateway_shryu.id
}


data "ncloud_root_password" "shryu_root_password_git" {
  server_instance_no = ncloud_server.server_shryu_git.id
  private_key        = ncloud_login_key.key_shryu.private_key
}

data "ncloud_root_password" "shryu_root_password_jenkins" {
  server_instance_no = ncloud_server.server_shryu_jenkins.id
  private_key        = ncloud_login_key.key_shryu.private_key
}

data "ncloud_root_password" "shryu_root_password_harbor" {
  server_instance_no = ncloud_server.server_shryu_harbor.id
  private_key        = ncloud_login_key.key_shryu.private_key
}

# You can add ACG rules remove comment If you want
/*
locals {
  default_acg_rules_inbound = [
    ["TCP", "0.0.0.0/0", "80"],
    ["TCP", "0.0.0.0/0", "443"],
    ["TCP", "${var.client_ip}/32", "22"]
  ]

  default_acg_rules_outbound = [
    ["TCP", "0.0.0.0/0", "1-65535"],
    ["UDP", "0.0.0.0/0", "1-65534"],
    ["ICMP", "0.0.0.0/0", null]
  ]
}

resource "ncloud_access_control_group" "acg_shryu" {
  description = "for acc test"
  vpc_no      = ncloud_vpc.vpc_shryu.id
}

resource "ncloud_access_control_group_rule" "acg_rule_shryu" {
  access_control_group_no = ncloud_access_control_group.acg_shryu.id

  dynamic "inbound" {
    for_each = local.default_acg_rules_inbound
    content {
      protocol    = inbound.value[0]
      ip_block    = inbound.value[1]
      port_range  = inbound.value[2]
    }
  }

  dynamic "outbound" {
    for_each = local.default_acg_rules_outbound
    content {
      protocol    = outbound.value[0]
      ip_block    = outbound.value[1]
      port_range  = outbound.value[2]
    }
  }
}
*/

