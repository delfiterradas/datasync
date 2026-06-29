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
        col.names = c("checksum", "file")
    )

    x
}

# Read generated checksums
generated <- read_checksum_file(generated_checksum)
expected <- read_checksum_file(input_checksum)

report <- merge(
    expected,
    generated,
    by = "file",
    all = TRUE,
    suffixes = c("_expected", "_observed")
)

report\$status <- ifelse(
    is.na(report\$checksum_expected),
    "UNEXPECTED",
    ifelse(
        is.na(report\$checksum_observed),
        "MISSING",
        ifelse(
            report\$checksum_expected == report\$checksum_observed,
            "MATCH",
            "MISMATCH"
        )
    )
)

# Write detailed report
write.csv(
    report[order(report\$file), ],
    paste0(prefix, ".checksum_validation.csv"),
    row.names = FALSE
)

# Write summary report
summary_df <- as.data.frame(table(report\$status))
colnames(summary_df) <- c("status", "count")

write.csv(
    summary_df[order(summary_df\$status), ],
    paste0(prefix, ".checksum_summary.csv"),
    row.names = FALSE
)

# ------------------------------------------------------------
# Versions file
# ------------------------------------------------------------

versions <- c(
    "\"${task.process}\":",
    paste0("    r-base: ", getRversion()),
    paste0("    comparechecksum: ", getRversion())
)

writeLines(
    versions,
    "versions.yml"
)
