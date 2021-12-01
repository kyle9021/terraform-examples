resource "google_bigquery_dataset" "ingress" {
  dataset_id  = "ingress"
  description = "Raw event data"
  location    = "EU"
  labels = {
    yor_trace = "48db095d-25ad-4088-abca-d1e81e05e05b"
  }
}

resource "google_bigquery_table" "vendor1_ingress" {
  dataset_id = google_bigquery_dataset.ingress.dataset_id
  table_id   = "vendor1_ingress"
  schema     = file("${path.module}/schemas/vendor1.schema.json")
  time_partitioning {
    field                    = "timestamp"
    type                     = "DAY"
    require_partition_filter = true
  }
  lifecycle {
    prevent_destroy = true
  }
  labels = {
    yor_trace = "698fcf9f-996f-458a-b35a-16b2e7d99ad3"
  }
}

resource "google_bigquery_table" "prober_ingress" {
  dataset_id = google_bigquery_dataset.ingress.dataset_id
  table_id   = "prober_ingress"
  schema     = "${file("${path.module}/schemas/prober.schema.json")}"
  time_partitioning {
    field                    = "timestamp"
    type                     = "DAY"
    require_partition_filter = true
  }
  lifecycle {
    prevent_destroy = true
  }
  labels = {
    yor_trace = "3e44bc01-82c1-404c-9fe3-675109e75a62"
  }
}

