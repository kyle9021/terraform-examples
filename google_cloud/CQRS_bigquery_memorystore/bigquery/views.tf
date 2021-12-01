resource "google_bigquery_dataset" "views" {
  dataset_id  = "views"
  description = "Data processing"
  location    = "EU"
  labels = {
    yor_trace = "fbb9fd95-58be-42f3-b4e3-8fc870aeb724"
  }
}

resource "google_bigquery_table" "vendor1" {
  dataset_id = google_bigquery_dataset.views.dataset_id
  table_id   = "vendor1"
  view {
    query = templatefile("${path.module}/sql/vendor1_cleanup.sql", {
      urdfs   = "${var.config.project}.${google_bigquery_dataset.urdfs.dataset_id}"
      ingress = "${var.config.project}.${google_bigquery_table.vendor1_ingress.dataset_id}.${google_bigquery_table.vendor1_ingress.table_id}"
    })
    use_legacy_sql = false
  }
  depends_on = [null_resource.CUSTOM_JSON_EXTRACT_ARRAY_FLOAT]
  labels = {
    yor_trace = "680fd419-ea9a-4147-b248-155b668f7f4a"
  }
}

resource "google_bigquery_table" "unified_values" {
  dataset_id = google_bigquery_dataset.views.dataset_id
  table_id   = "unified_values"
  view {
    query = templatefile("${path.module}/sql/unified_values.sql", {
      prober  = "${var.config.project}.${google_bigquery_table.prober_ingress.dataset_id}.${google_bigquery_table.prober_ingress.table_id}",
      vendor1 = "${var.config.project}.${google_bigquery_table.vendor1.dataset_id}.${google_bigquery_table.vendor1.table_id}"
    })
    use_legacy_sql = false
  }
  labels = {
    yor_trace = "28183437-f349-4781-be56-08179622e96c"
  }
}

resource "google_bigquery_table" "daily_adjusted_totals" {
  dataset_id = google_bigquery_dataset.views.dataset_id
  table_id   = "daily_adjusted_totals"
  view {
    query = templatefile("${path.module}/sql/daily_adjusted_totals.sql", {
      values         = "${var.config.project}.${google_bigquery_table.unified_values.dataset_id}.${google_bigquery_table.unified_values.table_id}",
      control_prefix = "${var.config.project}.${google_bigquery_table.control_range_view[0].dataset_id}.control_value_range_",
      control_fields = ["multiplier"]
    })
    use_legacy_sql = false
  }
  labels = {
    yor_trace = "41e37a02-74a5-4ce0-937f-30d904202ac4"
  }
}

resource "google_bigquery_table" "current_totals_latest" {
  dataset_id = google_bigquery_dataset.views.dataset_id
  table_id   = "current_totals"
  view {
    query = templatefile("${path.module}/sql/last_n_days_totals.sql", {
      n_days       = 1
      PREFIX       = "current_totals/"
      daily_totals = "${var.config.project}.${google_bigquery_table.daily_adjusted_totals.dataset_id}.${google_bigquery_table.daily_adjusted_totals.table_id}"
    })
    use_legacy_sql = false
  }
  labels = {
    yor_trace = "f84a24f5-566a-4ef4-bfda-90874043be3d"
  }
}

resource "google_bigquery_table" "historical_totals_latest" {
  dataset_id = google_bigquery_dataset.views.dataset_id
  table_id   = "historical_totals"
  view {
    query = templatefile("${path.module}/sql/last_n_days_totals.sql", {
      n_days       = "${var.config.retention_days}"
      PREFIX       = "historic_totals/"
      daily_totals = "${var.config.project}.${google_bigquery_table.daily_adjusted_totals.dataset_id}.${google_bigquery_table.daily_adjusted_totals.table_id}"
    })
    use_legacy_sql = false
  }
  labels = {
    yor_trace = "0aa23c9e-9cdb-43cd-9092-4a6e4c703b0d"
  }
}
