resource "oci_core_vcn" "cluster" {
  compartment_id = var.compartment_ocid
  cidr_block     = "172.16.0.0/16"
  display_name   = "vcn-${var.cluster_name}"
  dns_label      = replace("${var.cluster_name}", "/(_)|(-)/", "")
}

resource "oci_core_internet_gateway" "cluster" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.cluster.id
  display_name   = "igw-${var.cluster_name}"
  enabled        = "true"

  depends_on = [oci_core_vcn.cluster]
}

resource "oci_core_nat_gateway" "cluster" {
  block_traffic  = "false"
  compartment_id = var.compartment_ocid
  display_name   = "ngw-${var.cluster_name}"
  vcn_id         = oci_core_vcn.cluster.id

  depends_on = [oci_core_vcn.cluster]
}

resource "oci_core_service_gateway" "cluster" {
  compartment_id = var.compartment_ocid
  display_name   = "sgw-${var.cluster_name}"

  # OCID of "All GRU Services In Oracle Services Network"
  services {
    service_id = "ocid1.service.oc1.sa-saopaulo-1.aaaaaaaacd57uig6rzxm2qfipukbqpje2bhztqszh3aj7zk2jtvf6gvntena"
  }
  vcn_id = oci_core_vcn.cluster.id

  depends_on = [oci_core_vcn.cluster]
}