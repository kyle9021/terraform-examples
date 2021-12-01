
locals {
  control_fields = ["multiplier"]
  control_types  = ["FLOAT"]
  default_value  = ["1.0"]
}

resource "google_bigquery_table" "control_operations" {
  count      = length(local.control_fields)
  dataset_id = google_bigquery_dataset.ingress.dataset_id
  table_id   = "control_${element(local.control_fields, count.index)}"
  schema = templatefile(
    "${path.module}/schemas/control.template.schema.json", {
      FIELD = element(local.control_fields, count.index)
      TYPE  = element(local.control_types, count.index)
  })
  time_partitioning {
    field                    = "timestamp"
    type                     = "DAY"
    require_partition_filter = false
  }
  lifecycle {
    prevent_destroy = true
  }
  labels = {
    yor_trace = "1a4df265-11b8-4b02-bf06-aa89c1d10c1f"
  }
}

resource "google_bigquery_table" "control_range_view" {
  count      = length(local.control_fields)
  dataset_id = google_bigquery_dataset.views.dataset_id
  table_id   = "control_value_range_${element(local.control_fields, count.index)}"
  view {
    query = templatefile("${path.module}/sql/control_range_view.sql", {
      NAME       = element(local.control_fields, count.index),
      DEFAULT    = element(local.default_value, count.index)
      OPERATIONS = "${var.config.project}.${google_bigquery_table.control_operations[count.index].dataset_id}.${google_bigquery_table.control_operations[count.index].table_id}"
    })
    use_legacy_sql = false
  }
  labels = {
    yor_trace = "e8585cc8-7701-4986-8e2f-5b02e3fb19d9"
  }
}