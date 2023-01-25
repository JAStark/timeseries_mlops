# Set up PubSub for Cloud Schedular
resource "google_pubsub_topic" "realtime_weather_topic" {
  name = "realtime-weather-topic-dev"
}

# Set up Cloud Schedular to trigger Cloud Function once per day
resource "google_cloud_scheduler_job" "realtime_weather_schedular" {
  name        = "realtime-weather-schedular-dev"
  description = "Cron Job to start the collection of realtime Weather"
  schedule    = "0 * * * *" # Run at 7am
  time_zone   = "Europe/London"
  region      = var.region
  pubsub_target {
    topic_name = google_pubsub_topic.realtime_weather_topic.id
    data       = base64encode("Realtime Weather Begin!")
  }
}

# Set up path to zip file containing code for this Cloud Function
resource "google_storage_bucket_object" "dev_realtime_weather_cloud_function" {
  name           = "dev-realtime-weather.zip"
  bucket         = google_storage_bucket.timeseries_mlops_cloud_functions.name
  source         = "/workspace/cloud_functions/realtime_weather.zip"
  detect_md5hash = true
}

# Set up the Cloud Function itself
resource "google_cloudfunctions_function" "dev_collect_realtime_weather" {
  name                  = "timeseries-mlops-collect-realtime-weather-dev"
  description           = "Function to collect realtime weather data every hour"
  runtime               = "python310"
  available_memory_mb   = 128
  timeout               = 120
  source_archive_bucket = google_storage_bucket.timeseries_mlops_cloud_functions.name
  source_archive_object = google_storage_bucket_object.dev_realtime_weather_cloud_function.name
  entry_point           = "hello_fetch_realtime_data"
  ingress_settings      = "ALLOW_INTERNAL_ONLY"
  service_account_email = "weather-cloud-functions@silver-antonym-326607.iam.gserviceaccount.com"
  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = google_pubsub_topic.realtime_weather_topic.id
    failure_policy {
      retry = false
    }
  }
  environment_variables = {
    PROJECT_ID  = var.project_id
    BUCKET_NAME = google_storage_bucket.timeseries_mlops_weather_api_data.name
  }
  secret_environment_variables {
    key        = "API_KEY"
    project_id = var.project_number
    secret     = google_secret_manager_secret.weather_api_key_dev.secret_id
    version    = "1"
  }
}
