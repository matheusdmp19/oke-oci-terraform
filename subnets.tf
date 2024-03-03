# Public resources

resource "oci_core_route_table" "cluster_rt_public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.cluster.id
  display_name   = "rt-public-${var.cluster_name}"

  route_rules {
    description       = "traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.cluster.id
  }

  depends_on = [oci_core_vcn.cluster, oci_core_internet_gateway.cluster]
}

resource "oci_core_subnet" "cluster_public_subnet" {
  cidr_block     = "172.16.10.0/24"
  compartment_id = var.compartment_ocid

  dhcp_options_id = oci_core_vcn.cluster.default_dhcp_options_id
  display_name    = "public-subnet-regional-${var.cluster_name}"
  dns_label       = "publicsubnet"

  prohibit_internet_ingress  = "false"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_route_table.cluster_rt_public.id

  vcn_id = oci_core_vcn.cluster.id

  depends_on = [oci_core_vcn.cluster, oci_core_route_table.cluster_rt_public]
}

# Private resources

resource "oci_core_route_table" "cluster_rt_private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.cluster.id
  display_name   = "rt-private-${var.cluster_name}"

  route_rules {
    description       = "traffic to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.cluster.id
  }

  route_rules {
    description       = "traffic to OCI services"
    destination       = "all-gru-services-in-oracle-services-network"
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.cluster.id
    #route_type = <<Optional value not found in discovery>>
  }

  depends_on = [oci_core_vcn.cluster, oci_core_service_gateway.cluster]
}

resource "oci_core_subnet" "cluster_private_subnet" {
  cidr_block     = "172.16.20.0/24"
  compartment_id = var.compartment_ocid

  dhcp_options_id = oci_core_vcn.cluster.default_dhcp_options_id
  display_name    = "private-subnet-regional-${var.cluster_name}"
  dns_label       = "privatesubnet"

  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.cluster_rt_private.id

  vcn_id = oci_core_vcn.cluster.id

  depends_on = [oci_core_vcn.cluster, oci_core_route_table.cluster_rt_private]
}