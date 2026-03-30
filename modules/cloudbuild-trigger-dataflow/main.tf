locals {
  service_account            = "projects/${var.infra_project}/serviceAccounts/cloudbuild@${var.infra_project}.iam.gserviceaccount.com"
  image_name                 = "${var.registry_location}-docker.pkg.dev/${var.infra_project}/${var.registry_artifact}/${var.repo_name}${var.image_name_suffix}"
  dataflow_template_gcs_path = "${var.dataflow_template_gcs_prefix}/${var.repo_name}/$TAG_NAME.json"
}

output "trigger_id" {
  description = "Cloud Build trigger id"
  value       = google_cloudbuild_trigger.manual_deploy_dataflow.id
}

resource "google_cloudbuild_trigger" "manual_deploy_dataflow" {
  name        = "${var.repo_name}-dataflow-deploy"
  description = "Manually deploys a Dataflow job using a Flex Template."
  location    = var.trigger_location
  project     = var.infra_project

  service_account = local.service_account

  source_to_build {
    uri       = "https://github.com/${var.repo_owner}/${var.repo_name}.git"
    ref       = "refs/tags/$TAG_NAME"
    repo_type = "GITHUB"
  }

  substitutions = {
    _IMAGE_NAME = local.image_name
  }

  build {
    step {
      id         = "validate-tag"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "bash"
      args = ["-c", <<-EOT
        if [[ -z "$TAG_NAME" ]]; then
          echo "ERROR: TAG_NAME must be provided"
          exit 1
        fi
      EOT
      ]
    }

    step {
      id         = "check-image"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "bash"
      args = ["-c", <<-EOT
        gcloud artifacts docker images describe "$_IMAGE_NAME:$TAG_NAME" || {
          echo "ERROR: Image does not exist"
          exit 1
        }
      EOT
      ]
    }

    step {
      id         = "dataflow-build-template"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"

      args = [
        "dataflow", "flex-template", "build", local.dataflow_template_gcs_path,
        "--image", "$_IMAGE_NAME:$TAG_NAME",
        "--sdk-language", "PYTHON",
        "--metadata-file", var.dataflow_metadata_file,
      ]
    }

    step {
      id         = "dataflow-drain"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "bash"
      args = [
        var.dataflow_drain_script,
        var.dataflow_project,
        var.dataflow_region,
        var.dataflow_job_name,
      ]
    }

    step {
      id         = "dataflow-deploy"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"

      args = compact([
        "dataflow", "flex-template",
        "run", var.dataflow_job_name,
        "--region=${var.dataflow_region}",
        "--service-account-email=${var.dataflow_service_account}",
        "--project=${var.dataflow_project}",
        "--template-file-gcs-location", local.dataflow_template_gcs_path,
        "--temp-location=${var.dataflow_temp_location}/${var.repo_name}",
        "--staging-location=${var.dataflow_staging_location}/${var.repo_name}",
        var.dataflow_config_file != null ? "--parameters=config-file=${var.dataflow_config_file}" : null,
        "--parameters=sdk_container_image=$_IMAGE_NAME:$TAG_NAME",
      ])
    }

    timeout = var.timeout

    options {
      logging               = "CLOUD_LOGGING_ONLY"
      dynamic_substitutions = true
      machine_type          = var.machine_type
    }
  }
}
