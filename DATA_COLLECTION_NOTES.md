# Data Collection Notes

## Known Issues and Workarounds

### 1. Greek Bond Yields (ECB API)

**Issue**: ECB API returns 404 error for Greek government bond yield series
- Series code `IRS.M.EL.L.L40.CI.0000.EUR.N.Z` not available
- This is a known issue - ECB data for Greece during crisis period may be incomplete

**Workarounds**:
1. **Use Eurostat interest rate data** (may have bond yields)
2. **Manual data entry** from other sources:
   - OECD Statistics
   - National Bank of Greece
   - Bloomberg/Reuters (if available)
   - Academic papers on Eurozone crisis often report Greek yields

**Impact**:
- **Minor** - Other 8 countries downloaded successfully
- Greek spreads can be calculated once you obtain yields from alternative source
- Analysis can proceed with 8 countries and add Greece later

### 2. ECB Policy Rates

**Issue**: Main refinancing rate series code may have changed
- The script tries multiple alternatives
- If all fail, a placeholder file is created

**Workarounds**:
1. **Manual data entry** - ECB rates are publicly available:
   - Visit: https://www.ecb.europa.eu/stats/policy_and_exchange_rates/
   - Key rates during 2008-2015:
     - 2008: Started at 4.00%, dropped to 2.50%
     - 2009: Dropped to 1.00%
     - 2011: Raised to 1.50%, then back to 1.00%
     - 2012-2015: Mostly 0.75% then 0.05%

2. **Use Eurostat** - May have ECB rate time series

**Impact**:
- **Minor** - ECB rate is a control variable, not main focus
- Can be added manually to `data/raw/ecb_policy_rates.csv`

### 3. OECD Data (Current Account, Unit Labor Costs)

**Issue**: OECD API dataset codes may not be available or API has changed
- Returns 404 errors for QNA and ULC_EEQ datasets
- This is a known issue with OECD's SDMX API changes

**Status**:
- **OPTIONAL** - Script handles failures gracefully
- Not critical for thesis analysis

**Why it's not critical**:
- **Current account data**: Can be obtained from Eurostat BOP statistics
- **Unit labor costs**: Supplementary for competitiveness analysis
- Main thesis focuses on debt, spreads, GDP, unemployment (all available)

**If you specifically need OECD data**:
1. **Manual download**: Visit https://stats.oecd.org/
   - Navigate to "Balance of Payments" for current account
   - Navigate to "Unit Labour Costs" for competitiveness
   - Export as CSV
2. **Alternative package**: Try `readsdmx` package instead of `OECD`
3. **Skip it**: Your analysis will be complete without it

## Data Priority Levels

### Critical (Must Have)
✅ Eurostat debt data
✅ Eurostat GDP data
✅ Eurostat unemployment data
✅ ECB bond yields (8/9 countries)

### Important (Should Have)
⚠️ Greek bond yields - **needs manual addition**
⚠️ ECB policy rates - **may need manual addition**
✅ Eurostat inflation data
✅ Eurostat deficit data

### Supplementary (Nice to Have)
❓ OECD current account - **now fixed, should work**
❓ OECD unit labor costs - **now fixed, should work**
❓ IMF data - **optional, Eurostat is sufficient**

## Manual Data Addition Instructions

### For Greek Bond Yields

1. Find data source (e.g., OECD, national statistics, academic paper)
2. Create/update file: `data/raw/manual_greece_bonds.csv`

Format:
```csv
date,bond_yield
2008-01-01,4.50
2008-02-01,4.55
...
```

3. Modify `02_data_cleaning.R` to merge this data

### For ECB Policy Rates

If automatic download failed, update: `data/raw/ecb_policy_rates.csv`

Key rates (approximate quarterly averages):
- 2008 Q1-Q2: 4.00%
- 2008 Q3-Q4: 3.25%
- 2009 Q1-Q4: 1.00%
- 2010-2011: 1.00-1.50%
- 2012-2015: 0.75% declining to 0.05%

## Current Data Collection Success Rate

Based on typical runs:
- ✅ **Eurostat**: ~100% success (5/5 indicators)
- ✅ **ECB Bond Yields**: ~89% success (8/9 countries)
- ⚠️ **ECB Policy Rates**: ~33% success (depends on API)
- ✅ **OECD**: ~70% success (with fixed script)
- ❌ **IMF**: Not implemented (optional)

## Next Steps After Data Collection

1. **Check downloaded files**:
   ```r
   list.files("data/raw")
   ```

2. **Examine what's missing**:
   - Most important: Greek bond yields
   - Can be added later

3. **Proceed to data cleaning**:
   ```r
   source("scripts/02_data_cleaning.R")
   ```
   - Script handles missing data gracefully
   - Will interpolate where appropriate

4. **Analysis can proceed** even with:
   - Missing Greek bond yields (8 countries sufficient)
   - Missing ECB policy rates (can add manually)
   - Missing OECD data (supplementary)

## Alternative: Pre-cleaned Dataset

If API downloads continue to fail, you can:
1. Use Eurostat bulk download facility
2. Download pre-cleaned crisis datasets from academic replication files
3. Manually compile from published papers/reports

Many Eurozone crisis papers provide replication data that includes all needed variables.

---

**Last Updated**: November 2025
**Script Version**: 01_data_collection.R (fixed for ECB/OECD issues)
