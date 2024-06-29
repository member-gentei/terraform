
locals {
  monitoring_sa = "service-${data.google_project.current.number}@gcp-sa-monitoring-notification.iam.gserviceaccount.com"
}


resource "google_pubsub_topic" "alerting" {
  name = "alerting"
}

resource "google_monitoring_notification_channel" "pubsub" {
  display_name = "Alerting Channel"
  type         = "pubsub"
  labels = {
    topic = google_pubsub_topic.alerting.id
  }
}

resource "google_pubsub_topic_iam_binding" "publisher" {
  topic = google_pubsub_topic.alerting.name
  role  = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${local.monitoring_sa}"
  ]
}

resource "google_service_account" "alerting-discord" {
  account_id = "alerting-discord"
}

resource "google_project_iam_member" "alerting-discord_logReader" {
  project = "member-gentei"
  role    = "roles/logging.viewer"
  member  = google_service_account.alerting-discord.member
}

resource "google_cloud_run_service_iam_binding" "alerting-discord" {
  role     = "roles/run.invoker"
  location = "us-central1"
  service  = google_cloudfunctions2_function.discord-alert.name
  members = [
    "serviceAccount:${google_service_account.alerting-discord.email}"
  ]
}

resource "google_secret_manager_secret_iam_binding" "alerting-discord" {
  role      = "roles/secretmanager.secretAccessor"
  secret_id = data.google_secret_manager_secret.alerting-discord-webhook-url.secret_id
  members = [
    "serviceAccount:${google_service_account.alerting-discord.email}"
  ]
}

resource "google_cloudfunctions2_function" "discord-alert" {
  name     = "discord-alert"
  location = "us-central1"

  build_config {
    entry_point = "HandlePubSubAlert"
    runtime     = "go122"
    # gcloud invocations mutate the source {} block
  }
  service_config {
    all_traffic_on_latest_revision = true
    available_cpu                  = "83m"
    available_memory               = "128Mi"
    service_account_email          = google_service_account.alerting-discord.email
    environment_variables = {
      LOG_EXECUTION_ID = "true"
    }
    secret_environment_variables {
      key        = "DISCORD_WEBHOOK_URL"
      project_id = data.google_project.current.number
      secret     = data.google_secret_manager_secret.alerting-discord-webhook-url.secret_id
      version    = "latest"
    }
  }
  event_trigger {
    event_type   = "google.cloud.pubsub.topic.v1.messagePublished"
    retry_policy = "RETRY_POLICY_DO_NOT_RETRY"
  }
  lifecycle {
    ignore_changes = [build_config[0].source]
  }
}

data "google_secret_manager_secret" "alerting-discord-webhook-url" {
  secret_id = "alerting-discord-webhook-url"
}
