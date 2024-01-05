locals {
  name = "World"
}

output "result" {
  value = templatefile("${path.module}/example.tftpl", { name = local.name })
}
