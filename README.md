# Project to experiment with MLOps using GCP
Powered by <a href="https://www.weatherapi.com/" title="Free Weather API">WeatherAPI.com</a>


## Ingredients
**An ML problem**
It's important – and difficult – to not get too carried away on the ML problem itself.
Therefore I am going to use the Keras example for weather timeseries. This provides me
with something that can be predicted, with rapid feedback regarding the accuracy or
correctness of the prediction (eg the next day or the next hour). There are several
APIs for weather, and I want to make this more personal, so instead of the dataset provided
in the Keras example I will be using data from another API … but which one? OpenWeather Data looks like a good start, but it's £140 per month :sob:
- https://openweather.co.uk/api-products provides historical, current, and forecast.
    - Time range: Historical data for 40 years back, current weather and different forecasts. Minute, hourly, and daily forecasts are        available for a different time period, from a few hours (minute forecast), up to a year ahead (climate forecast).
    - Essential weather parameters: Temperature, precipitation, probability of precipitation, humidity, feels like, pressure, cloudiness, wind, etc.
    - Availability: Any geographical location | Global coverage
    - API: Pull and push for all products | Industry standards | Fast, reliable, simple syntax

Weather API
- https://www.weatherapi.com which is free for
  - 1,000,000 calls per month
  - history for only 7 days

## Infrastructure
- IaC using Terraform with the Google Provider
- Cloud Functions to call the weather API
- JSON file outputs to go to Google Cloud Storage
- Cloud Schedular to trigger the Cloud Function every hour or 30 minutes or something to collect data. Frequency will depend on the endpoint.
- Google Secrets Manager for the API key

## Data Collection
- 7 day historical collection limit. Need to start collecting!
- Current data.
- 14 day forecast
  Having both current and forecast data could be really interesting as I can compare my predictions with the API's predictions _and_ the real outcome.
  I can also use their predictions _and/or_ the current values (truth) to track my algorithm performance against, and use to determine when to retrain my algorithm.
- Collect at the highest frequency on my plan: 25 calls per day, or once every hour.

## Repo configuration notes:
- GitOps as described [here](https://cloud.google.com/architecture/managing-infrastructure-as-code) where we have:
- a `dev` branch and a `prod` branch
- cloud build app configured in GitHub and a Cloud Build trigger configured in GCP so that when I push to GitHub, it triggers a build.
- `dev` and `prod` branches protected, in that only when the feature branch cloud build passes, can `dev` be merged into, and likewise for `dev` into `prod`.  
