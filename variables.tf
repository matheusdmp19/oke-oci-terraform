variable "cluster_name" {
  type    = string
  default = "cluster-prod"
}

variable "cluster_version" {
  type    = string
  default = "v1.28.2"
}

variable "nodes" {
  type    = number
  default = 4
}

variable "shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "ocpus_per_node" {
  type    = number
  default = 1
}

variable "memory_in_gbs_per_node" {
  type    = number
  default = 6
}

variable "region" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "compartment_ocid" {
  type = string
}