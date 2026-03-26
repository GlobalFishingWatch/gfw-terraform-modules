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
  description = "The GCP project for the GFW infrastructure."
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

variable "platform" {
  description = "Docker build platform (e.g. linux/amd64 or linux/arm64)"
  type        = string
  default     = "linux/amd64"
}

variable "machine_type" {
  type    = string
  default = "E2_MEDIUM"
}

variable "image_name_suffix" {
  description = "Suffix to add to the image name"
  type        = string
  default     = ""
}

variable "timeout" {
  description = "Timeout for the trigger"
  type        = string
  default     = "1200s"
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

variable "gke_compile_command" {
  description = "Optional command to compile/render manifests before deployment"
  type        = string
  default     = null
}

variable "gke_compile_image" {
  description = "Container image used to run the compile command"
  type        = string
  default     = "gcr.io/cloud-builders/kubectl"
}

variable "dataflow_deploy_enabled" {
  type    = bool
  default = false
}

variable "dataflow_template_gcs_prefix" {
  description = "Base GCS path for Dataflow templates (directory)."
  type        = string
  default     = ""

  validation {
    condition     = !var.dataflow_deploy_enabled || length(var.dataflow_template_gcs_prefix) > 0
    error_message = format(local.dataflow_required_msg, "dataflow_template_gcs_prefix")
  }
}

variable "dataflow_job_name" {
  type    = string
  default = ""

  validation {
    condition     = !var.dataflow_deploy_enabled || length(var.dataflow_job_name) > 0
    error_message = format(local.dataflow_required_msg, "dataflow_job_name")
  }
}

variable "dataflow_metadata_file" {
  type    = string
  default = "dataflow/metadata.json"
}

variable "dataflow_config_file" {
  description = "Path to pipeline --config-file to be used."
  type        = string
  default     = null
}

variable "dataflow_drain_script" {
  type    = string
  default = "./dataflow/drain.sh"
}

variable "dataflow_staging_location" {
  type    = string
  default = "gs://gfw-ingestion-us-central1-dataflow-staging"
}

variable "dataflow_temp_location" {
  type    = string
  default = "gs://gfw-ingestion-us-central1-dataflow-temp-ttl7"
}

variable "dataflow_region" {
  description = "Google Cloud region/location for the Dataflow job."
  type        = string
  default     = "us-central1"
}