# ==============================================================================
# Quick Script: Download Unemployment Data
# ==============================================================================
# Purpose: Download missing unemployment data from Eurostat
# ==============================================================================

# Load packages
library(eurostat)
library(tidyverse)
library(here)

# Configuration
countries_iso2 <- c("EL", "IE", "IT", "PT", "ES", "DE", "FR", "NL", "AT")
start_year <- 2008
end_year <- 2015
data_dir <- here("data/raw")

cat("Downloading unemployment data from Eurostat...\n\n")

# Try Method 1: Quarterly unemployment data
cat("Method 1: Quarterly unemployment rate (une_rt_q)...\n")
tryCatch({
  unemp_data <- get_eurostat(
    "une_rt_q",
    time_format = "date",
    filters = list(
      geo = countries_iso2,
      s_adj = "SA",      # Seasonally adjusted
      age = "TOTAL",
      sex = "T"          # Total (both sexes)
    )
  ) %>%
    filter(year(time) >= start_year & year(time) <= end_year) %>%
    select(geo, time, values) %>%
    rename(country = geo, date = time, unemployment = values)

  if (nrow(unemp_data) > 0) {
    write_csv(unemp_data, file.path(data_dir, "eurostat_unemployment.csv"))
    cat("  ✓ SUCCESS! Unemployment data saved\n")
    cat(sprintf("  ✓ Downloaded %d observations\n", nrow(unemp_data)))
    cat(sprintf("  ✓ Countries: %s\n", paste(unique(unemp_data$country), collapse = ", ")))
  } else {
    cat("  ✗ No data returned\n")
  }
}, error = function(e) {
  cat("  ✗ Method 1 failed:", conditionMessage(e), "\n")
  cat("\nTrying Method 2: Annual unemployment data...\n")

  # Try Method 2: Annual data (more reliable)
  tryCatch({
    unemp_annual <- get_eurostat(
      "une_rt_a",
      time_format = "date",
      filters = list(
        geo = countries_iso2,
        age = "TOTAL",
        sex = "T"
      )
    ) %>%
      filter(year(time) >= start_year & year(time) <= end_year) %>%
      select(geo, time, values) %>%
      rename(country = geo, date = time, unemployment = values)

    if (nrow(unemp_annual) > 0) {
      write_csv(unemp_annual, file.path(data_dir, "eurostat_unemployment.csv"))
      cat("  ✓ SUCCESS! Annual unemployment data saved\n")
      cat("  (Note: Annual data - will be interpolated to quarterly in cleaning)\n")
      cat(sprintf("  ✓ Downloaded %d observations\n", nrow(unemp_annual)))
    }
  }, error = function(e2) {
    cat("  ✗ Method 2 also failed:", conditionMessage(e2), "\n")
    cat("\n⚠️ Unemployment data not available via automatic download\n")
    cat("See instructions below for manual download\n")
  })
})

# Check if file was created
if (file.exists(file.path(data_dir, "eurostat_unemployment.csv"))) {
  cat("\n", strrep("=", 60), "\n")
  cat("✓ UNEMPLOYMENT DATA SUCCESSFULLY DOWNLOADED\n")
  cat(strrep("=", 60), "\n")

  # Show preview
  unemp_preview <- read_csv(file.path(data_dir, "eurostat_unemployment.csv"),
                            show_col_types = FALSE)
  cat("\nData preview:\n")
  print(head(unemp_preview, 10))

  cat("\nYou can now proceed to data cleaning:\n")
  cat("  source('scripts/02_data_cleaning.R')\n")
} else {
  cat("\n", strrep("=", 60), "\n")
  cat("⚠️ AUTOMATIC DOWNLOAD FAILED\n")
  cat(strrep("=", 60), "\n")
  cat("\nMANUAL DOWNLOAD INSTRUCTIONS:\n")
  cat("1. Visit: https://ec.europa.eu/eurostat/databrowser/\n")
  cat("2. Search for: 'Unemployment rate - quarterly data'\n")
  cat("3. Select:\n")
  cat("   - Countries: Greece, Ireland, Italy, Portugal, Spain,\n")
  cat("                Germany, France, Netherlands, Austria\n")
  cat("   - Time period: 2008-2015\n")
  cat("   - Seasonally adjusted data\n")
  cat("4. Download as CSV\n")
  cat("5. Save to: data/raw/eurostat_unemployment.csv\n")
  cat("\nAlternative: Use OECD data\n")
  cat("  https://data.oecd.org/unemp/unemployment-rate.htm\n")
  cat("\nThe cleaning script can handle manually downloaded data!\n")
}
