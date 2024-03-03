resource "oci_core_default_security_list" "vcn_cluster" {
  compartment_id             = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.cluster.default_security_list_id

  ingress_security_rules {
    description = "Allow all traffic"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "all"
    stateless = "false"
  }

  egress_security_rules {
    description      = "Allow all traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }

  depends_on = [oci_core_vcn.cluster]
}

resource "oci_core_network_security_group" "cluster_api_endpoint" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.cluster.id
  display_name   = "nsg_cluster_api"
}

resource "oci_core_network_security_group" "cluster_node_pool" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.cluster.id
  display_name   = "nsg_cluster_node_pool"
}

# Ingress rules / K8s API endpoint
resource "oci_core_network_security_group_security_rule" "api_endpoint_ingress_01" {
  network_security_group_id = oci_core_network_security_group.cluster_api_endpoint.id
  description               = "Kubernetes worker to Kubernetes API endpoint communication"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_subnet.cluster_private_subnet.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"

  tcp_options {
    destination_port_range {
      max = "6443"
      min = "6443"
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_endpoint_ingress_02" {
  network_security_group_id = oci_core_network_security_group.cluster_api_endpoint.id
  description               = "Kubernetes worker to control plane communication"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_subnet.cluster_private_subnet.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"

  tcp_options {
    destination_port_range {
      max = "12250"
      min = "12250"
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_endpoint_ingress_03" {
  network_security_group_id = oci_core_network_security_group.cluster_api_endpoint.id
  description               = "Path discovery"
  direction                 = "INGRESS"
  protocol                  = "1"
  source                    = oci_core_subnet.cluster_private_subnet.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"

  icmp_options {
    code = "4"
    type = "3"
  }
}

resource "oci_core_network_security_group_security_rule" "api_endpoint_ingress_04" {
  network_security_group_id = oci_core_network_security_group.cluster_api_endpoint.id
  description               = "External access to Kubernetes API endpoint"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"

  tcp_options {
    destination_port_range {
      max = "6443"
      min = "6443"
    }
  }
}
# End - Ingress rules / K8s API endpoint

# Egress Rules / K8s API endpoint
resource "oci_core_network_security_group_security_rule" "api_endpoint_egress_01" {
  network_security_group_id = oci_core_network_security_group.cluster_api_endpoint.id
  description               = "Allow the Kubernetes control plane to communicate with OKE"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "all-gru-services-in-oracle-services-network"
  destination_type          = "SERVICE_CIDR_BLOCK"
  stateless                 = "false"
}

resource "oci_core_network_security_group_security_rule" "api_endpoint_egress_02" {
  network_security_group_id = oci_core_network_security_group.cluster_api_endpoint.id
  description               = "Path Discovery"
  direction                 = "EGRESS"
  protocol                  = "1"
  destination               = "all-gru-services-in-oracle-services-network"
  destination_type          = "SERVICE_CIDR_BLOCK"
  stateless                 = "false"

  icmp_options {
    code = "4"
    type = "3"
  }
}

resource "oci_core_network_security_group_security_rule" "api_endpoint_egress_03" {
  network_security_group_id = oci_core_network_security_group.cluster_api_endpoint.id
  description               = "Allow the Kubernetes control plane to communicate with worker nodes"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = oci_core_subnet.cluster_private_subnet.cidr_block
  destination_type          = "CIDR_BLOCK"
  stateless                 = "false"
}

resource "oci_core_network_security_group_security_rule" "api_endpoint_egress_04" {
  network_security_group_id = oci_core_network_security_group.cluster_api_endpoint.id
  description               = "Path Discovery"
  direction                 = "EGRESS"
  protocol                  = "1"
  destination               = oci_core_subnet.cluster_private_subnet.cidr_block
  destination_type          = "CIDR_BLOCK"
  stateless                 = "false"

  icmp_options {
    code = "4"
    type = "3"
  }
}

# End - Egress Rules / K8s API endpoint

# Ingress Rules / Worker Nodes

resource "oci_core_network_security_group_security_rule" "node_pool_ingress_01" {
  network_security_group_id = oci_core_network_security_group.cluster_node_pool.id
  description               = "Allow pods on a worker node to communicate with pods on other worker nodes"
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = oci_core_subnet.cluster_private_subnet.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource "oci_core_network_security_group_security_rule" "node_pool_ingress_02" {
  network_security_group_id = oci_core_network_security_group.cluster_node_pool.id
  description               = "Allow the Kubernetes control plane to communicate with worker nodes"
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = oci_core_subnet.cluster_public_subnet.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource "oci_core_network_security_group_security_rule" "node_pool_ingress_03" {
  network_security_group_id = oci_core_network_security_group.cluster_node_pool.id
  description               = "Path discovery"
  direction                 = "INGRESS"
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"

  icmp_options {
    code = "4"
    type = "3"
  }
}

# End - Ingress Rules / Worker Nodes

# Egress Rules / Worker Nodes

resource "oci_core_network_security_group_security_rule" "node_pool_egress_01" {
  network_security_group_id = oci_core_network_security_group.cluster_node_pool.id
  description               = "Allow pods on a worker node to communicate with pods on other worker nodes"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = oci_core_subnet.cluster_private_subnet.cidr_block
  destination_type          = "CIDR_BLOCK"
  stateless                 = "false"
}

resource "oci_core_network_security_group_security_rule" "node_pool_egress_02" {
  network_security_group_id = oci_core_network_security_group.cluster_node_pool.id
  description               = "Path discovery"
  direction                 = "EGRESS"
  protocol                  = "1"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  stateless                 = "false"

  icmp_options {
    code = "4"
    type = "3"
  }
}

resource "oci_core_network_security_group_security_rule" "node_pool_egress_03" {
  network_security_group_id = oci_core_network_security_group.cluster_node_pool.id
  description               = "Allow work nodes to communicate with OKE"
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = "all-gru-services-in-oracle-services-network"
  destination_type          = "SERVICE_CIDR_BLOCK"
  stateless                 = "false"
}

resource "oci_core_network_security_group_security_rule" "node_pool_egress_04" {
  network_security_group_id = oci_core_network_security_group.cluster_node_pool.id
  description               = "Access to Kubernetes API Endpoint"
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_subnet.cluster_public_subnet.cidr_block
  destination_type          = "CIDR_BLOCK"
  stateless                 = "false"

  tcp_options {
    destination_port_range {
      max = "6443"
      min = "6443"
    }
  }
}

resource "oci_core_network_security_group_security_rule" "node_pool_egress_05" {
  network_security_group_id = oci_core_network_security_group.cluster_node_pool.id
  description               = "Kubernetes worker to control plane communication"
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_subnet.cluster_public_subnet.cidr_block
  destination_type          = "CIDR_BLOCK"
  stateless                 = "false"

  tcp_options {
    destination_port_range {
      max = "12250"
      min = "12250"
    }
  }
}

resource "oci_core_network_security_group_security_rule" "node_pool_egress_06" {
  network_security_group_id = oci_core_network_security_group.cluster_node_pool.id
  description               = "Allow work nodes to communicate with the Internet"
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  stateless                 = "false"
}

# End - Egress Rules / Worker Nodes