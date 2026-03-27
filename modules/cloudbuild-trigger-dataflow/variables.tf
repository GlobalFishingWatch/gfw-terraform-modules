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

variable "dataflow_template_gcs_prefix" {
  description = "Base GCS path for Dataflow templates (directory)."
  type        = string
}

variable "dataflow_job_name" {
  type = string
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

variable "dataflow_project" {
  description = "GCP project to use when dataflow deployment is enabled."
  type        = string
}

variable "dataflow_service_account" {
  type = string
}