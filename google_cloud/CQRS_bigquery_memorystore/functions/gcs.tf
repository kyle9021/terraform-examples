resource "google_storage_bucket" "memorystore_uploads" {
  name     = "${var.config.project}_memorystore_uploads"
  location = "${var.config.region}"
  labels = {
    yor_trace = "1fe9561e-546d-49a7-b063-56549c2009fa"
  }
}
