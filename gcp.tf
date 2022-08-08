provider "google" {
  project = "member-gentei"
}

resource "google_service_account" "gentei" {
  account_id   = "gentei"
  display_name = "gentei"
  description  = "API server, queue worker, and pretty much everything else that doesn't use Discord."
}

resource "google_service_account" "bot" {
  account_id   = "discord-bot"
  display_name = "discord-bot"
  description  = "Discord bot and messaging worker"
}

resource "google_project_iam_member" "logging_logWriter" {
  for_each = toset([for sa in [
    google_service_account.bot,
    google_service_account.gentei,
  ] : sa.email])
  project = "member-gentei"
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${each.key}"
}

resource "google_project_iam_member" "monitoring_metricWriter" {
  for_each = toset([for sa in [
    google_service_account.bot,
    google_service_account.gentei,
  ] : sa.email])
  project = "member-gentei"
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${each.key}"
}

# pubsub topics, subscriptions, and IAM policies
resource "google_pubsub_topic" "async" {
  name = "async"
}

resource "google_pubsub_topic_iam_binding" "async" {
  project = "member-gentei"
  topic   = google_pubsub_topic.async.name
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.gentei.email}"
  ]
}

resource "google_pubsub_subscription" "general" {
  name                 = "general"
  topic                = google_pubsub_topic.async.name
  filter               = "attributes.type = \"general\""
  ack_deadline_seconds = 600
}

resource "google_pubsub_subscription_iam_binding" "general" {
  project      = "member-gentei"
  subscription = google_pubsub_subscription.general.name
  role         = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${google_service_account.gentei.email}"
  ]
}

resource "google_pubsub_subscription" "bot-apply-membership" {
  name                 = "bot-apply-membership"
  topic                = google_pubsub_topic.async.name
  filter               = "attributes.type = \"apply-membership\""
  ack_deadline_seconds = 600
}

resource "google_pubsub_subscription_iam_binding" "bot-apply-membership" {
  project      = "member-gentei"
  subscription = google_pubsub_subscription.bot-apply-membership.name
  role         = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${google_service_account.bot.email}"
  ]
}

resource "google_logging_project_bucket_config" "default" {
  project        = "projects/member-gentei"
  location       = "global"
  retention_days = 30
  bucket_id      = "_Default"
}
