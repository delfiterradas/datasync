#!/usr/bin/env Rscript

# Template-interpolated by Nextflow
input_checksum     <- "${input_checksum}"
generated_checksum <- "${generated_checksum}"
prefix             <- "${prefix}"
md5sum             <- "${meta.md5}"
shasum             <- "${meta.sha}"

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

# Case 1: expected checksum file provided
if (!is.na(input_checksum) && file.exists(input_checksum)) {
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

# Case 2: use checksum stored in metadata
} else {
    expected_checksum <- NULL

    if (!is.na(md5sum)) {
        expected_checksum <- md5sum
    } else if (!is.na(shasum)) {
        expected_checksum <- shasum
    } else {
        stop(
            "No checksum file provided and neither meta.md5 nor meta.sha are available"
        )
    }

    if (nrow(generated) != 1) {
        stop(
            paste(
                "Metadata checksum provided but generated checksum file contains",
                nrow(generated),
                "entries. Expected exactly one."
            )
        )
    }

    report <- data.frame(
        file = generated\$file,
        checksum_expected = expected_checksum,
        checksum_observed = generated\$checksum,
        status = ifelse(
            generated\$checksum == expected_checksum,
            "MATCH",
            "MISMATCH"
        ),
        stringsAsFactors = FALSE
    )
}

# Write detailed report
write.csv(
    report,
    paste0(prefix, ".checksum_validation.csv"),
    row.names = FALSE
)

# Write summary report
summary_df <- as.data.frame(table(report\$status))
colnames(summary_df) <- c("status", "count")

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
    paste0("    r-base: ", getRversion()),
    paste0("    comparechecksum: ", getRversion())
)

writeLines(
    versions,
    "versions.yml"
)
