resource "oci_containerengine_cluster" "master" {
  compartment_id     = var.compartment_ocid
  vcn_id             = oci_core_vcn.cluster.id
  kubernetes_version = var.cluster_version
  name               = var.cluster_name

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }
  endpoint_config {
    is_public_ip_enabled = "true"
    nsg_ids              = [oci_core_network_security_group.cluster_api_endpoint.id]
    subnet_id            = oci_core_subnet.cluster_public_subnet.id
  }
  image_policy_config {
    is_policy_enabled = "false"
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = "false"
      is_tiller_enabled               = "false"
    }
    admission_controller_options {
      is_pod_security_policy_enabled = "false"
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    persistent_volume_config {
      freeform_tags = {
        "System" = "oke-${var.cluster_name}"
      }
    }
    service_lb_config {
      freeform_tags = {
        "System" = "oke-${var.cluster_name}"
      }
    }
  }
}

resource "oci_containerengine_node_pool" "node_pool_01" {
  cluster_id         = oci_containerengine_cluster.master.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.cluster_version
  name               = "node_pool1"
  node_shape         = var.shape

  freeform_tags = {
    "OKEnodePoolName" = "node_pool1"
    "System"          = "oke-${var.cluster_name}"
  }
  initial_node_labels {
    key   = "name"
    value = var.cluster_name
  }

  node_config_details {
    freeform_tags = {
      "OKEnodePoolName" = "node_pool1"
      "System"          = "oke-${var.cluster_name}"
    }
    node_pool_pod_network_option_details {
      cni_type = "FLANNEL_OVERLAY"
    }
    nsg_ids = [oci_core_network_security_group.cluster_node_pool.id]
    placement_configs {
      availability_domain = data.oci_identity_availability_domain.sa_saopaulo_1.name
      fault_domains       = []
      subnet_id           = oci_core_subnet.cluster_private_subnet.id
    }
    size = var.nodes
  }
  node_eviction_node_pool_settings {
    eviction_grace_duration = "PT20M"
  }
  node_metadata = {}
  node_shape_config {
    memory_in_gbs = var.memory_in_gbs_per_node
    ocpus         = var.ocpus_per_node
  }
  node_source_details {
    boot_volume_size_in_gbs = "50"
    # image name: Oracle-Linux-8.9-aarch64-2024.01.26-0-OKE-1.28.2-679
    image_id    = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaaavl3zahoinfge32ba3xmenuvzov5tmx6odn6okco7hw427mxwhrq"
    source_type = "IMAGE"
  }
}