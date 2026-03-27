mock_provider "google" {
  # Mocking disables real API calls and avoids credential requirements
}

variables {
  repo_name         = "my-app-repo"
  repo_owner        = "my-org"
  registry_artifact = "my-docker-registry"
  infra_project     = "mock-infra-project"
  registry_location = "us-central1"
  trigger_location  = "us-central1"

  dataflow_template_gcs_prefix = "gs://my-bucket/templates"
  dataflow_job_name            = "my-job"
  dataflow_project             = "my-dataflow-project"
  dataflow_service_account     = "dataflow@my-project.iam.gserviceaccount.com"
}

run "basic_trigger_creation_plan" {
  command = plan

  assert {
    condition     = google_cloudbuild_trigger.manual_deploy_dataflow.name == "my-app-repo-dataflow-deploy"
    error_message = "Expected trigger name to be 'my-app-repo-dataflow-deploy'."
  }

  assert {
    condition     = google_cloudbuild_trigger.manual_deploy_dataflow.project == "mock-infra-project"
    error_message = "Expected project to match infra_project."
  }

  assert {
    condition     = google_cloudbuild_trigger.manual_deploy_dataflow.location == "us-central1"
    error_message = "Expected trigger location to be 'us-central1'."
  }
}