# Set up PubSub for Cloud Schedular
resource "google_pubsub_topic" "historical_weather_topic" {
  name = "historical_weather_topic"
}

# Set uo Cloud Schedular to trigger Cloud Function once per day
resource "google_cloud_scheduler_job" "historical_weather_schedular" {
  name        = "historical_weather_schedular"
  description = "Cron Job to start the collection of Historical Weather"
  schedule    = "0 7 * * *" # Run at 7am
  time_zone   = "Europe/London"
  region      = var.region
  pubsub_target {
    topic_name = google_pubsub_topic.historical_weather_topic.id
    data       = base64encode("Historical Weather Begin!")
  }
}

# Set up Cloud Storage Bucket for Cloud Function to read code from
resource "google_storage_bucket" "timeseries_mlops_cloud_functions" {
  name = "timeseries_mlops_cloud_functions"
  location = var.region
}

# # Set up path to zip file containing code for this Cloud Function
# resource "google_storage_bucket_object" "historical_weather_cloud_function" {
#   name = "historical_weather.zip"
#   bucket = google_storage_bucket.timeseries_mlops_cloud_functions.name
#   source = "./cloud_functions"
# }
#
# # Set up the Cloud Function itself
# resource "google_cloudfunctions_function" "collect_historical_weather" {
#   name                  = "timeseries_mlops_collect_historical_weather"
#   description           = "Function to collect yesterday's hourly weather data"
#   runtime               = "python310"
#   available_memory_mb   = 128
#   timeout               = 120
#   source_archive_bucket = google_storage_bucket.timeseries_mlops_cloud_functions.name
#   source_archive_object = google_storage_bucket_object.historical_weather_cloud_function.name
#   entry_point           = "hello_fetch_historical_data"
#   # ingress_settings      = "ALLOW_INTERNAL_ONLY"
#   event_trigger {
#     event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
#     resource = google_pubsub_topic.historical_weather_topic.id
#     failure_policy {
#       retry = false
#     }
#   }
#   environment_variables = {
#   PROJECT_ID  = var.project_id
# }
# }
