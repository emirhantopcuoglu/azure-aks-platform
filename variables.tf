variable "project_name" {
  description = "Short project name used in every resource name."
  type        = string
  default     = "aks-platform"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "project_name must be 3-20 characters: lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment; becomes part of resource names and tags."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "swedencentral"
}

variable "extra_tags" {
  description = "Additional tags merged into the common tags."
  type        = map(string)
  default     = {}
}
