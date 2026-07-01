#!/usr/bin/env Rscript

# Template-interpolated by Nextflow
input_checksum     <- "${input_checksum}"
generated_checksum <- "${generated_checksum}"
prefix             <- "${prefix}"

read_checksum_file <- function(path) {

    x <- read.table(
        path,
        stringsAsFactors = FALSE,
        fill = TRUE,
        col.names = c("checksum", "File")
    )

    x
}

# Read generated checksums
generated <- read_checksum_file(generated_checksum)
expected <- read_checksum_file(input_checksum)

report <- merge(
    expected,
    generated,
    by = "File",
    all = TRUE,
    suffixes = c("_expected", "_observed")
)

report\$status <- ifelse(
    is.na(report\$checksum_expected),
    "Unexpected",
    ifelse(
        is.na(report\$checksum_observed),
        "Missing",
        ifelse(
            report\$checksum_expected == report\$checksum_observed,
            "Match",
            "Mismatch"
        )
    )
)

# Write detailed report
write.csv(
    report[order(report\$File), ],
    paste0(prefix, ".checksum_validation.csv"),
    row.names = FALSE
)

# Write summary report
summary_df <- as.data.frame(table(report\$status))
colnames(summary_df) <- c("status", "count")
summary_df <- cbind(Sample = prefix, summary_df)
status_counts <- table(
    factor(
        report\$status,
        levels = c("Match", "Mismatch", "Missing", "Unexpected")
    )
)

summary_df <- data.frame(
    Sample = prefix,
    Match = unname(status_counts["Match"]),
    Mismatch = unname(status_counts["Mismatch"]),
    Missing = unname(status_counts["Missing"]),
    Unexpected = unname(status_counts["Unexpected"]),
    check.names = FALSE
)

write.csv(
    summary_df,
    paste0(prefix, ".checksum_summary.csv"),
    row.names = FALSE
)

# ------------------------------------------------------------
# Versions file
# ------------------------------------------------------------

versions <- c(
    "\"${task.process}\":",
    paste0("    r-base: ", getRversion())
)

writeLines(
    versions,
    "versions.yml"
)
