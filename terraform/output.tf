output "master" {
  value = "${aws_instance.k8s_master.public_ip}"
}

output "master_private" {
  value = "${aws_instance.k8s_master.private_ip}"
}
output "node1" {
  value = "${aws_instance.node1.public_ip}"
}

output "node1_private" {
  value = "${aws_instance.node1.private_ip}"
}
