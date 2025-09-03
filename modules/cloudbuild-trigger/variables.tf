variable "trigger_description" {
  description = "The description for the Google Cloud trigger."
  type        = string
  default     = null
}

variable "trigger_location" {
  description = "Google Cloud region/location for the Cloud Build trigger."
  type        = string
  default     = "us-central1"
}

variable "infra_project" {
  description = "The GPC project for the GFW infrastructure."
  type        = string
  default     = "gfw-int-infrastructure"
}

variable "registry_artifact" {
  description = "The Docker Image Registry artifact to use."
  type        = string
}

variable "registry_location" {
  description = "Google Cloud region/location for the Docker Image Registry."
  type        = string
  default     = "us-central1"
}

variable "repo_name" {
  description = "GitHub repository name."
  type        = string
}

variable "repo_owner" {
  description = "GitHub repository owner."
  type        = string
  default     = "GlobalFishingWatch"

}

variable "branch" {
  description = "Branch to trigger on."
  type        = string
  default     = null
}

variable "tag" {
  description = "Tag regex to trigger on."
  type        = string
  default     = null
}

variable "invert_regex" {
  description = "Invert regex for branch/tag match."
  type        = bool
  default     = false
}

variable "gke_deploy_enabled" {
  description = "Whether to run a Kubernetes deploy step after pushing the image."
  type        = bool
  default     = false
}

variable "gke_manifest" {
  description = "Path to Kubernetes manifest to apply."
  type        = string
  default     = "k8s/prod/deployment.yaml"
}

variable "gke_location" {
  description = "GKE location."
  type        = string
  default     = "us-central1"
}

variable "gke_cluster" {
  description = "GKE cluster."
  type        = string
  default     = ""
  validation {
    condition     = !var.gke_deploy_enabled || length(var.gke_cluster) > 0
    error_message = format(local.gke_required_msg, "gke_cluster")
  }
}

variable "gke_project" {
  description = "GKE project."
  type        = string
  default     = ""
  validation {
    condition     = !var.gke_deploy_enabled || length(var.gke_project) > 0
    error_message = format(local.gke_required_msg, "gke_project")
  }
}
