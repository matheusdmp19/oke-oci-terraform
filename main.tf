terraform {
  backend "s3" {
    bucket = "mpinho-tfstate"
    key = "oci/oke/terraform.tfstate"
  }
  
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "5.30.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}