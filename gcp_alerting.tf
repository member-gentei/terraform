
locals {
  monitoring_sa = "service-${data.google_project.current.number}@gcp-sa-monitoring-notification.iam.gserviceaccount.com"
}

resource "google_pubsub_topic" "alerting" {
  name = "alerting"
}

resource "google_monitoring_notification_channel" "pubsub" {
  display_name = "Alerting Channel"
  type = "pubsub"
  labels = {
    topic = google_pubsub_topic.alerting.id
  }
}

resource "google_pubsub_topic_iam_binding" "publisher" {
  topic = google_pubsub_topic.alerting.name
  role = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${local.monitoring_sa}"
  ]
}
