resource "google_pubsub_topic" "version_every_minute" {
  name = "version_every_minute"
  labels = {
    yor_trace = "03230c42-2e58-4db3-a145-511c95c353bf"
  }
}

resource "google_pubsub_topic" "version_every_two_minutes" {
  name = "version_every_two_minutes"
  labels = {
    yor_trace = "c80f19d5-49c8-4c0d-b88f-e38771cf6d97"
  }
}

resource "google_pubsub_topic" "version_every_hour" {
  name = "version_every_hour"
  labels = {
    yor_trace = "d112f33b-4536-416a-88b4-c6b812c0bbf8"
  }
}
