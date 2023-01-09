"""This cloud function gets the last 1 complete day of historical forcasts.
Returns a JSON file with data for each hour of the day.

Unclear from the docs if this is the actual weather, or what was forecast.
And if forecast, how far out was the forecast made?

Cloud Function runs once per day just before midnight to fectch the predictions
for the last 24 hours into one json file.

API: https://www.weatherapi.com/docs/
"""

import os
import sys
import json
import logging
import requests
from datetime import datetime, timedelta
import base64

from google.cloud import storage
from google.api_core import exceptions

logging.basicConfig(level=logging.DEBUG)

API_KEY = os.environ["API_KEY"]
PROJECT_ID = os.environ["PROJECT_ID"]
STORAGE_CLIENT = storage.Client("PROJECT_ID")
BUCKET_NAME = os.environ["BUCKET_NAME"]


def write_to_storage(json_data: dict, yesterday: str) -> None:
    """Funtion to write json data to file in GCS.
    File name: historical_weather_<YYYY-MM-DD>
    """

    filename = f"historical_weather/manchester_weather_{yesterday}.json"
    try:
        bucket = STORAGE_CLIENT.get_bucket(BUCKET_NAME)
        blob = bucket.blob(filename)
        blob.upload_from_string(data=json_data, content_type="application/json")
        logging.info(f"File {filename} uploaded to {BUCKET_NAME}.")
    except exceptions.NotFound as e:
        logging.error(f"Bucket: {BUCKET_NAME} does not exist. Error: {e}")
    except Exception as e:
        logging.info(f"Something went wrong. Check the logs {e}")


def fetch_historical_data(date: str) -> dict:
    """Function to call API and fetch histotical weather data"""
    url = f"https://api.weatherapi.com/v1/history.json?key={API_KEY}&q=manchester&dt={date}"
    response = requests.request("GET", url)
    json_data = response.text
    logging.info(f"TYPE RESPONSE: {type(json_data)}")
    logging.info(f"Data collected for {date}: \n{json_data}")
    return json_data


def get_yesterday() -> str:
    """Function to get the date for yesterday as a string: `YYYY-MM-DD`"""
    today = datetime.today()
    delta = timedelta(days=1)
    yesterday = today - delta
    yesterday_formatted = yesterday.date().isoformat()
    logging.info(f"TYPE YESTERDAY: {type(yesterday_formatted)}")
    return yesterday_formatted


def main():
    """Function that calls other Functions"""
    logging.info("Starting main for historical data collection")
    yesterday = get_yesterday()
    logging.info(f"\nYESTERDAY: {yesterday}")
    json_data = fetch_historical_data(yesterday)
    logging.info("\nWRITING DATA TO STORAGE…")
    write_to_storage(json_data, yesterday)


def hello_fetch_historical_data(event, context=None) -> None:
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


# if __name__ == "__main__":
# logging.basicConfig(level=logging.DEBUG)
# fetch_historical_data(sys.argv[1])

if __name__ == "__main__":
    MESSAGE = "Historical Weather Begin!"
    EVENT_DATA = base64.b64encode(str(MESSAGE).encode("utf-8"))
    hello_fetch_historical_data(event={"data": EVENT_DATA})
