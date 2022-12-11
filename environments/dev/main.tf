resource "google_cloud_scheduler_job" "historical_weather_data_collection" {
  name        = "historical_weather_data_collection"
  description = "Cron Job to start the collection of Historical Weather"
  schedule    = "0 7 * * *" # Run at 7am
  time_zone   = "Europe/London"
  region      = "europe-west1"
  pubsub_target {
    topic_name = "projects/${var.project_id}/topics/${google_pubsub_topic.start_facebook_comments_data_collection_topic.name}"
    data       = base64encode("Facebook Comments Begin!")
  }
}
