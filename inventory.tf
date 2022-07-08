data "template_file" "inventory" {
  template = "${file("${path.module}/templates/hosts.tpl")}"
  vars = {
    ip =  "${join("\n", [for i in google_compute_instance.k8s:  i.network_interface.0.access_config.0.nat_ip ])}" 
  }
}


resource "local_file" "save_inventory" {
  content  = "${data.template_file.inventory.rendered}"
  filename = "./inventory"
}
