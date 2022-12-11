"""This cloud function gets the last 1 complete day of historical forcasts.
Returns a JSON file with data for each hour of the day.

Unclear from the docs if this is the actual weather, or what was forecast.
And if forecast, how far out was the forecast made?

Cloud Function runs once per day.

API: https://www.weatherapi.com/docs/
"""

import os
import sys
import json
import logging
import requests
from datetime import datetime, timedelta

# from google.cloud import exceptions
from google.cloud import storage

API_KEY = os.environ["API_KEY"]
PROJECT_ID = os.environ["PROJECT_ID"]
BUCKET = storage.Client("PROJECT_ID")


def write_to_storage(json_data: dict, yesterday: str) -> None:
    """Funtion to write json data to file in GCS.
    File name: historical_weather_<YYYY-MM-DD>
    """
    filename = f"historical_weather/{json_data}.json"
    try:
        bucket = BUCKET.get_bucket(bucket_name)
        blob = bucket.blob()
    except Exception as e:
        logging.info(f"Something went wrong. Check the logs {e}")


def get_yesterday() -> str:
    """Function to get the date for yesterday as a string: `YYYY-MM-DD`"""
    today = datetime.today()
    delta = timedelta(days=1)
    yesterday = today - delta
    yesterday_formatted = yesterday.date().isoformat()
    return yesterday_formatted


def fetch_historical_data(date):
    url = f"https://api.weatherapi.com/v1/history.json?key={API_KEY}&q=manchester&dt={date}"
    response = requests.request("GET", url)
    logging.info(f"Data collected for {date}: \n{response.text}")


def main():
    yesterday = get_yesterday()
    fetch_historical_data(yesterday)


def hello_fetch_historical_data(date: str) -> None:
    """Entry point for the Cloud Function.
    Args:
        event (dict): Event payload from the Cloud Scheduler
        context (google.cloud.functions.Context): Metadata for the event.
    """

    if context:
        logging.info(f"CONTEXT: {context}")
        logging.info(
            f"Function triggered by messageId {context.event_id} published at {context.timestamp}"
        )

    if "data" in event:
        logging.info(f"EVENT: {event}")
        data = base64.b64decode(event["data"]).decode("utf-8")

        if data == "Historical Weather Begin!":
            main()
        else:
            raise Exception(
                f'Expected Message: "Historical Weather Begin!"\nActual Message: "{data}"'
            )
    else:
        raise Exception(f"No data received in pubsub event. Event: {event}")


if __name__ == "__main__":
    logging.basicConfig(
        log_filename="historical_weather.log", encoding="utf-8", level=logging.DEBUG
    )
    fetch_historical_data(sys.argv[1])
