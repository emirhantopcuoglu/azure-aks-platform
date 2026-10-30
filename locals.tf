locals {
  # Shared by every resource name, e.g. rg-aks-platform-dev
  name_suffix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    },
    var.extra_tags,
  )
}
