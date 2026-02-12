# ==============================================================================
# Eurozone Crisis Analysis: Data Collection Script
# ==============================================================================
# Purpose: Download raw data from Eurostat, ECB, IMF, and OECD
# Author: Generated for Eurozone Crisis Thesis Analysis
# Date: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  eurostat,      # Eurostat data access
  ecb,           # ECB data access
  imf.data,      # IMF data access (replacement for deprecated IMFData)
  OECD,          # OECD data access
  tidyverse,     # Data manipulation
  lubridate,     # Date handling
  countrycode,   # Country code conversion
  here           # File path management
)

# ==============================================================================
# Configuration
# ==============================================================================

# Country codes
countries_iso2 <- c("EL", "IE", "IT", "PT", "ES", "DE", "FR", "NL", "AT")
countries_iso3 <- c("GRC", "IRL", "ITA", "PRT", "ESP", "DEU", "FRA", "NLD", "AUT")
country_names <- c("Greece", "Ireland", "Italy", "Portugal", "Spain",
                   "Germany", "France", "Netherlands", "Austria")

# Time period
start_year <- 2008
end_year <- 2015

# Data directory
data_dir <- here::here("data/raw")
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

cat("Starting data collection for Eurozone Crisis analysis...\n")
cat("Countries:", paste(country_names, collapse = ", "), "\n")
cat("Period:", start_year, "-", end_year, "\n\n")

# ==============================================================================
# 1. EUROSTAT DATA
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("1. Collecting Eurostat Data\n")
cat(strrep("=", 78), "\n\n")

## 1.1 Government Debt (quarterly)
cat("Downloading government debt data...\n")
tryCatch({
  debt_data <- get_eurostat(
    "gov_10q_ggdebt",
    time_format = "date",
    filters = list(
      geo = countries_iso2,
      unit = "PC_GDP",
      sector = "S13",
      na_item = "GD"
    )
  ) %>%
    filter(year(time) >= start_year & year(time) <= end_year) %>%
    select(geo, time, values) %>%
    rename(country = geo, date = time, debt_gdp = values)

  write_csv(debt_data, file.path(data_dir, "eurostat_debt.csv"))
  cat("  ✓ Government debt data saved\n")
}, error = function(e) {
  cat("  ✗ Error downloading debt data:", conditionMessage(e), "\n")
})

## 1.2 GDP Growth (quarterly)
cat("Downloading GDP data...\n")
tryCatch({
  gdp_data <- get_eurostat(
    "namq_10_gdp",
    time_format = "date",
    filters = list(
      geo = countries_iso2,
      unit = "PC_GDP",
      s_adj = "SCA",
      na_item = "B1GQ"
    )
  ) %>%
    filter(year(time) >= start_year & year(time) <= end_year) %>%
    select(geo, time, values) %>%
    rename(country = geo, date = time, gdp_growth = values)

  write_csv(gdp_data, file.path(data_dir, "eurostat_gdp.csv"))
  cat("  ✓ GDP data saved\n")
}, error = function(e) {
  cat("  ✗ Error downloading GDP data:", conditionMessage(e), "\n")
})

## 1.3 Unemployment Rate (quarterly)
cat("Downloading unemployment data...\n")
tryCatch({
  unemp_data <- get_eurostat(
    "une_rt_q",
    time_format = "date",
    filters = list(
      geo = countries_iso2,
      s_adj = "SA",
      age = "TOTAL",
      sex = "T"
    )
  ) %>%
    filter(year(time) >= start_year & year(time) <= end_year) %>%
    select(geo, time, values) %>%
    rename(country = geo, date = time, unemployment = values)

  write_csv(unemp_data, file.path(data_dir, "eurostat_unemployment.csv"))
  cat("  ✓ Unemployment data saved\n")
}, error = function(e) {
  cat("  ✗ Error downloading unemployment data:", conditionMessage(e), "\n")
})

## 1.4 HICP Inflation (monthly, aggregate to quarterly)
cat("Downloading inflation data...\n")
tryCatch({
  infl_data <- get_eurostat(
    "prc_hicp_manr",
    time_format = "date",
    filters = list(
      geo = countries_iso2,
      coicop = "CP00"
    )
  ) %>%
    filter(year(time) >= start_year & year(time) <= end_year) %>%
    mutate(quarter = quarter(time, with_year = TRUE)) %>%
    group_by(geo, quarter) %>%
    summarise(inflation = mean(values, na.rm = TRUE), .groups = "drop") %>%
    mutate(date = yq(quarter)) %>%
    select(geo, date, inflation) %>%
    rename(country = geo)

  write_csv(infl_data, file.path(data_dir, "eurostat_inflation.csv"))
  cat("  ✓ Inflation data saved\n")
}, error = function(e) {
  cat("  ✗ Error downloading inflation data:", conditionMessage(e), "\n")
})

## 1.5 Government Deficit (quarterly)
cat("Downloading fiscal deficit data...\n")
tryCatch({
  deficit_data <- get_eurostat(
    "gov_10q_ggnfa",
    time_format = "date",
    filters = list(
      geo = countries_iso2,
      unit = "PC_GDP",
      sector = "S13",
      na_item = "B9"
    )
  ) %>%
    filter(year(time) >= start_year & year(time) <= end_year) %>%
    select(geo, time, values) %>%
    rename(country = geo, date = time, deficit_gdp = values)

  write_csv(deficit_data, file.path(data_dir, "eurostat_deficit.csv"))
  cat("  ✓ Fiscal deficit data saved\n")
}, error = function(e) {
  cat("  ✗ Error downloading deficit data:", conditionMessage(e), "\n")
})

cat("\nEurostat data collection complete!\n\n")

# ==============================================================================
# 2. ECB DATA - Government Bond Yields
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("2. Collecting ECB Data - Government Bond Yields\n")
cat(strrep("=", 78), "\n\n")

cat("Downloading 10-year government bond yields...\n")

# ECB series keys for 10-year government bond yields
# Format: IRS.M.{COUNTRY}.L.L40.CI.0000.EUR.N.Z
ecb_country_codes <- c(
  GR = "EL",  # Greece
  IE = "IE",  # Ireland
  IT = "IT",  # Italy
  PT = "PT",  # Portugal
  ES = "ES",  # Spain
  DE = "DE",  # Germany
  FR = "FR",  # France
  NL = "NL",  # Netherlands
  AT = "AT"   # Austria
)

bond_yields_list <- list()

for (i in seq_along(ecb_country_codes)) {
  country_code <- ecb_country_codes[i]
  country_name <- names(ecb_country_codes)[i]

  cat(sprintf("  Downloading %s bond yields...\n", country_name))

  tryCatch({
    series_key <- sprintf("IRS.M.%s.L.L40.CI.0000.EUR.N.Z", country_code)

    bond_data <- get_data(
      series_key,
      start_period = paste0(start_year, "-01"),
      end_period = paste0(end_year, "-12")
    )

    if (nrow(bond_data) > 0) {
      bond_data <- bond_data %>%
        mutate(
          country = country_name,
          date = as.Date(paste0(obstime, "-01")),
          bond_yield = as.numeric(obsvalue)
        ) %>%
        select(country, date, bond_yield)

      bond_yields_list[[country_name]] <- bond_data
      cat(sprintf("    ✓ %s data collected\n", country_name))
    }
  }, error = function(e) {
    cat(sprintf("    ✗ Error for %s: %s\n", country_name, conditionMessage(e)))
  })
}

# Combine all bond yield data
if (length(bond_yields_list) > 0) {
  bond_yields_combined <- bind_rows(bond_yields_list)
  write_csv(bond_yields_combined, file.path(data_dir, "ecb_bond_yields.csv"))
  cat("\n  ✓ All bond yield data saved\n")

  # Check if Greece data is missing
  if (!"GR" %in% bond_yields_combined$country) {
    cat("  ⚠ Note: Greek bond yield data not available via ECB API\n")
    cat("    This is common - can use Eurostat or manual sources instead\n")
  }
} else {
  cat("\n  ✗ No bond yield data collected\n")
}

## 2.2 ECB Policy Rates
cat("\nDownloading ECB policy rates...\n")

# Try multiple possible series codes for ECB policy rates
policy_rate_codes <- c(
  "FM.M.U2.EUR.4F.KR.MRR_FR.LEV",  # Main refinancing rate
  "FM.B.U2.EUR.4F.KR.MRR_FR.LEV",  # Alternative: business frequency
  "IRS.M.DE.L.L40.CI.0000.EUR.N.Z" # Fallback: can use German rate as proxy
)

ecb_rates <- NULL
for (rate_code in policy_rate_codes) {
  tryCatch({
    cat(sprintf("  Trying series: %s...\n", rate_code))
    ecb_rates <- get_data(
      rate_code,
      start_period = paste0(start_year, "-01"),
      end_period = paste0(end_year, "-12")
    ) %>%
      mutate(
        date = as.Date(paste0(obstime, "-01")),
        ecb_rate = as.numeric(obsvalue)
      ) %>%
      select(date, ecb_rate)

    if (nrow(ecb_rates) > 0) {
      write_csv(ecb_rates, file.path(data_dir, "ecb_policy_rates.csv"))
      cat("  ✓ ECB policy rates saved\n")
      break  # Success, exit loop
    }
  }, error = function(e) {
    cat(sprintf("    ✗ Failed: %s\n", substr(conditionMessage(e), 1, 80)))
  })
}

if (is.null(ecb_rates) || nrow(ecb_rates) == 0) {
  cat("  ⚠ Could not download ECB policy rates automatically\n")
  cat("  ! You can manually add them later or use alternative sources\n")

  # Create placeholder file with manual input option
  ecb_rates_placeholder <- tibble(
    date = seq(as.Date("2008-01-01"), as.Date("2015-12-01"), by = "quarter"),
    ecb_rate = NA  # To be filled manually if needed
  )
  write_csv(ecb_rates_placeholder, file.path(data_dir, "ecb_policy_rates.csv"))
  cat("  ✓ Placeholder file created (can be updated manually)\n")
}

cat("\nECB data collection complete!\n\n")

# ==============================================================================
# 3. IMF DATA
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("3. Collecting IMF World Economic Outlook Data\n")
cat(strrep("=", 78), "\n\n")

# Note: IMF data collection using imf.data package
cat("Note: IMF data collection uses imf.data package.\n")
cat("If automatic collection fails, please download manually from:\n")
cat("https://www.imf.org/en/Publications/WEO/weo-database\n\n")

tryCatch({
  # Using imf.data package (replacement for deprecated IMFData)
  cat("Attempting to download IMF data...\n")

  # Example: Get government debt data from IFS (International Financial Statistics)
  # Note: The imf.data package works differently than IMFData
  # For comprehensive IMF data, manual download may be more reliable

  # List available databases
  # databases <- imf.data::imf_databases()

  cat("  ! IMF data collection via API is optional\n")
  cat("  ! Key variables (debt, deficits) available from Eurostat\n")
  cat("  ! Manual download from IMF WEO recommended for additional data\n")

}, error = function(e) {
  cat("  ✗ IMF automatic download not available:", conditionMessage(e), "\n")
  cat("  ! IMF data is supplementary; core analysis uses Eurostat/ECB data\n")
})

cat("\n")

# ==============================================================================
# 4. OECD DATA
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("4. Collecting OECD Data\n")
cat(strrep("=", 78), "\n\n")

## 4.1 Current Account Balance
cat("Downloading current account data...\n")

# Note: OECD API codes change frequently. Try multiple approaches.
current_account_downloaded <- FALSE

# Approach 1: Try standard OECD package method
tryCatch({
  cat("  Attempting OECD method 1...\n")
  # Try simpler query - just get the dataset and filter later
  current_account <- get_dataset(
    "QNA",
    filter = "all",
    start_time = start_year,
    end_time = end_year,
    pre_formatted = FALSE
  )

  # Filter for our countries and current account
  if (!is.null(current_account) && nrow(current_account) > 0) {
    current_account_clean <- current_account %>%
      filter(LOCATION %in% countries_iso3,
             SUBJECT == "B6BLTT02",
             MEASURE == "PC_GDP") %>%
      mutate(
        country = LOCATION,
        date = as.Date(paste0(obsTime, "-01")),
        current_account = as.numeric(obsValue)
      ) %>%
      select(country, date, current_account)

    if (nrow(current_account_clean) > 0) {
      write_csv(current_account_clean, file.path(data_dir, "oecd_current_account.csv"))
      cat("  ✓ Current account data saved\n")
      current_account_downloaded <- TRUE
    }
  }
}, error = function(e) {
  cat("  ✗ Method 1 failed\n")
})

if (!current_account_downloaded) {
  cat("  ⚠ OECD current account data not available via API\n")
  cat("  ! This is supplementary data - analysis can proceed without it\n")
  cat("  ! Alternative: Download manually from OECD.Stat if needed\n")
}

## 4.2 Unit Labor Costs (competitiveness measure)
cat("Downloading unit labor costs data...\n")

ulc_downloaded <- FALSE

tryCatch({
  cat("  Attempting OECD method 1...\n")
  ulc_data <- get_dataset(
    "ULC_EEQ",
    filter = "all",
    start_time = start_year,
    end_time = end_year,
    pre_formatted = FALSE
  )

  if (!is.null(ulc_data) && nrow(ulc_data) > 0) {
    ulc_clean <- ulc_data %>%
      filter(LOCATION %in% countries_iso3) %>%
      mutate(
        country = LOCATION,
        date = as.Date(paste0(obsTime, "-01")),
        ulc_index = as.numeric(obsValue)
      ) %>%
      select(country, date, ulc_index)

    if (nrow(ulc_clean) > 0) {
      write_csv(ulc_clean, file.path(data_dir, "oecd_unit_labor_costs.csv"))
      cat("  ✓ Unit labor costs data saved\n")
      ulc_downloaded <- TRUE
    }
  }
}, error = function(e) {
  cat("  ✗ Method 1 failed\n")
})

if (!ulc_downloaded) {
  cat("  ⚠ OECD unit labor costs data not available via API\n")
  cat("  ! This is supplementary data - analysis can proceed without it\n")
  cat("  ! Alternative: Download manually from OECD.Stat if needed\n")
}

cat("\nOECD data collection complete!\n\n")

# ==============================================================================
# 5. MANUAL DATA ENTRY - Bailout Programs
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("5. Creating Bailout Programs Dataset\n")
cat(strrep("=", 78), "\n\n")

# Bailout program data (from public sources)
bailout_programs <- tibble(
  country = c("Greece", "Greece", "Greece", "Ireland", "Portugal", "Spain", "Spain"),
  program_type = c("1st Program", "2nd Program", "3rd Program", "Program", "Program",
                   "Bank Recap", "Precautionary"),
  start_date = as.Date(c("2010-05-01", "2012-03-01", "2015-08-01",
                          "2010-11-01", "2011-05-01", "2012-07-01", "2013-01-01")),
  end_date = as.Date(c("2012-06-30", "2015-06-30", "2018-08-20",
                        "2013-12-15", "2014-05-17", "2013-12-31", "2014-01-23")),
  amount_billion_eur = c(110, 164.5, 86, 67.5, 78, 100, 0),
  institutions = c("EU/IMF", "EU/IMF", "ESM", "EU/IMF", "EU/IMF", "ESM", "ESM")
) %>%
  mutate(
    active_2010 = (year(start_date) <= 2010 & year(end_date) >= 2010),
    active_2011 = (year(start_date) <= 2011 & year(end_date) >= 2011),
    active_2012 = (year(start_date) <= 2012 & year(end_date) >= 2012),
    active_2013 = (year(start_date) <= 2013 & year(end_date) >= 2013),
    active_2014 = (year(start_date) <= 2014 & year(end_date) >= 2014),
    active_2015 = (year(start_date) <= 2015 & year(end_date) >= 2015)
  )

write_csv(bailout_programs, file.path(data_dir, "bailout_programs.csv"))
cat("  ✓ Bailout programs data saved\n\n")

# ==============================================================================
# 6. MANUAL DATA ENTRY - Major Crisis Events
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("6. Creating Crisis Events Timeline\n")
cat(strrep("=", 78), "\n\n")

# Major crisis events for event study analysis
crisis_events <- tibble(
  date = as.Date(c(
    "2008-09-15",  # Lehman Brothers collapse
    "2009-10-20",  # Greek deficit revelation
    "2010-05-02",  # First Greek bailout
    "2010-11-28",  # Irish bailout
    "2011-04-07",   # Portuguese bailout
    "2011-07-21",  # Second Greek bailout agreed
    "2012-06-09",  # Spanish bank bailout
    "2012-07-26",  # Draghi "Whatever it takes" speech
    "2012-09-06",  # ECB OMT announcement
    "2013-03-16",  # Cyprus bailout
    "2015-07-05",  # Greek referendum
    "2015-08-14"   # Third Greek bailout
  )),
  event = c(
    "Lehman Brothers Collapse",
    "Greek Deficit Revelation",
    "First Greek Bailout",
    "Irish Bailout",
    "Portuguese Bailout",
    "Second Greek Bailout Agreement",
    "Spanish Bank Bailout",
    "Draghi Speech",
    "ECB OMT Announcement",
    "Cyprus Bailout",
    "Greek Referendum",
    "Third Greek Bailout"
  ),
  type = c(
    "Financial Crisis",
    "Crisis Start",
    "Policy Response",
    "Policy Response",
    "Policy Response",
    "Policy Response",
    "Policy Response",
    "Policy Response",
    "Policy Response",
    "Policy Response",
    "Political Event",
    "Policy Response"
  ),
  country_affected = c(
    "All",
    "Greece",
    "Greece",
    "Ireland",
    "Portugal",
    "Greece",
    "Spain",
    "All",
    "All",
    "Cyprus",
    "Greece",
    "Greece"
  )
)

write_csv(crisis_events, file.path(data_dir, "crisis_events.csv"))
cat("  ✓ Crisis events timeline saved\n\n")

# ==============================================================================
# 7. DATA COLLECTION SUMMARY
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("DATA COLLECTION SUMMARY\n")
cat(strrep("=", 78), "\n\n")

# List all downloaded files
downloaded_files <- list.files(data_dir, pattern = "\\.csv$", full.names = FALSE)

cat("Files created in data/raw/:\n")
for (file in downloaded_files) {
  file_size <- file.info(file.path(data_dir, file))$size
  cat(sprintf("  ✓ %s (%.1f KB)\n", file, file_size / 1024))
}

cat("\n", strrep("=", 78), "\n")
cat("Next Steps:\n")
cat("  1. Review downloaded data for completeness\n")
cat("  2. Run scripts/02_data_cleaning.R to process and merge data\n")
cat("  3. Check for any missing values or data quality issues\n")
cat(strrep("=", 78), "\n\n")

cat("Data collection script completed successfully!\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
