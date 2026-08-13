# terraform_data 由 OpenTofu 内置 Provider 提供，不需要访问外部 Provider Registry。
resource "terraform_data" "mixed_outcome_test" {
  input = var.marker

  lifecycle {
    precondition {
      condition     = var.marker != var.rejected_marker
      error_message = "Marker was rejected by the mixed-outcome smoke test."
    }
  }
}
