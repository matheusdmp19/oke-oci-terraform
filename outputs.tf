output "cluster_id" {
  value = oci_containerengine_cluster.master.id
}

output "cluster_public_endpoint" {
  value = oci_containerengine_cluster.master.endpoints[0]["public_endpoint"]
}