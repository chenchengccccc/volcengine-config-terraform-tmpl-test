terraform {
  required_version = ">= 1.0"
}

resource "terraform_data" "marker" {
  input = var.marker
}
