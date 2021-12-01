# Application insights instrumentation key
resource "azurerm_key_vault_secret" "app_insights_instrumentation_key" {
  key_vault_id = azurerm_key_vault.current.id
  name         = "app-insights-key"
  value        = azurerm_application_insights.current.instrumentation_key

  depends_on = [azurerm_key_vault_access_policy.principal]
  tags = {
    yor_trace = "5e89af07-4890-4b17-a12c-4100b14af269"
  }
}
