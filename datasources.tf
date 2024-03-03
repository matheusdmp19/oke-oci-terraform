data "oci_identity_availability_domain" "sa_saopaulo_1" {
  compartment_id = var.compartment_ocid
  ad_number      = "1"
}