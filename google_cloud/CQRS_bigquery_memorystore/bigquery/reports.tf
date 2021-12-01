
resource "google_bigquery_dataset" "reports" {
  dataset_id  = "reports"
  description = "Materialized reports"
  location    = "EU"
  labels = {
    yor_trace = "a6881560-817b-411d-8f42-b00020eae9b1"
  }
}

resource "google_bigquery_table" "current_totals" {
  dataset_id = google_bigquery_dataset.reports.dataset_id
  table_id   = "current_totals"
  schema     = "${file("${path.module}/schemas/report.schema.json")}"
  labels = {
    yor_trace = "7d50c23f-05b5-4573-8328-ad3b7e75d40a"
  }
}

resource "google_bigquery_table" "historical_totals" {
  dataset_id = google_bigquery_dataset.reports.dataset_id
  table_id   = "historical_totals"
  schema     = "${file("${path.module}/schemas/report.schema.json")}"
  time_partitioning {
    field                    = "day"
    type                     = "DAY"
    require_partition_filter = true
  }
  labels = {
    yor_trace = "cd9bff4c-9c7c-4820-a7d2-466bec66595d"
  }
}
