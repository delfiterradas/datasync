# nf-core/datasync: Output

## Introduction

This document describes the reports produced by nf-core/datasync. Paths below are relative to the directory supplied with `--outdir`.

> [!IMPORTANT]
> The copied payload is written to each samplesheet row's `output_path`. It is not placed in `--outdir` unless `output_path` explicitly points there.

## Output overview

```text
<OUTDIR>/
├── rclone/
│   ├── <sample>-rclone-copy.log
│   ├── <sample>.combined.txt
│   ├── <sample>.match.txt
│   ├── <sample>.differ.txt
│   ├── <sample>.missing_on_dst.txt
│   ├── <sample>.missing_on_src.txt
│   └── <sample>.error.txt
├── multiqc/
│   ├── multiqc_report.html
│   └── multiqc_data/
└── pipeline_info/
    ├── nf_core_datasync_software_mqc_versions.yml
    └── execution_* / pipeline_dag_*
```

## Rclone transfer and integrity reports

<details markdown="1">
<summary>Output files</summary>

- `rclone/`
  - `<sample>-rclone-copy.log`: informational log from the copy operation.
  - `<sample>.combined.txt`: combined comparison status, one path per line.
  - `<sample>.match.txt`: paths whose content matched (`=`).
  - `<sample>.differ.txt`: paths present on both sides but with different content (`*`).
  - `<sample>.missing_on_dst.txt`: paths found in the source or manifest but absent from the checked data (`-`).
  - `<sample>.missing_on_src.txt`: paths found in the checked data but absent from the source or manifest (`+`).
  - `<sample>.error.txt`: paths that could not be read or hashed (`!`).

</details>

Two integrity stages create reports:

1. **Pre-copy checksum validation** uses each supplied MD5 and/or SHA-256 manifest to check the source.
2. **Post-copy validation** compares the source with the destination after the copy task finishes.

Both stages use the same `<sample>.*.txt` naming convention and publish to `rclone/`. When a row supplies a checksum manifest, similarly named pre-copy and post-copy files may target the same published path; use the consolidated MultiQC sections for the stage-specific summary and retain the Nextflow work directory if both raw report sets must be audited independently.

The combined files use rclone's one-character status prefixes:

| Prefix | Meaning                  | Action                                                                                                                      |
| ------ | ------------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| `=`    | File matches             | No action required.                                                                                                         |
| `-`    | Missing from destination | Investigate an incomplete source checksum set or transfer.                                                                  |
| `+`    | Missing from source      | Review unexpected destination content. The post-copy check uses `--one-way`, so destination-only files are tolerated there. |
| `*`    | Content differs          | Re-copy or investigate source/destination mutation.                                                                         |
| `!`    | Read/hash error          | Inspect permissions, credentials, connectivity, and the copy log.                                                           |

Empty category files mean that rclone reported no entries in that category. The commands are designed to preserve these reports rather than terminate the whole workflow on comparison differences. Always inspect the reports; workflow success alone is not an integrity guarantee.

## MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: standalone report viewable in a browser.
  - `multiqc_data/`: machine-readable data, logs, source inventory, software versions, and parsed rclone tables.

</details>

The MultiQC report consolidates:

- checksum validation status for MD5 and/or SHA-256 manifests;
- post-copy source-to-destination validation status;
- the validated samplesheet and workflow parameter summary; and
- pipeline and tool versions.

Open `multiqc_report.html` after every run and investigate any non-matching, missing, or error entries. Data under `multiqc_data/` can be retained for automated auditing or downstream reporting; exact filenames may vary with the MultiQC version and the checksum types present in the samplesheet.

## Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - `nf_core_datasync_software_mqc_versions.yml`: versions of the pipeline and tools collected for MultiQC.
  - `execution_timeline_<timestamp>.html`: chronological task execution view.
  - `execution_report_<timestamp>.html`: task runtime and resource report.
  - `execution_trace_<timestamp>.txt`: tabular task-level execution trace.
  - `pipeline_dag_<timestamp>.html`: workflow dependency graph.
  - Completion reports generated when `--email` or `--email_on_fail` is configured may also be present.

</details>

These files provide operational provenance and help diagnose performance or failures. Archive them with the MultiQC and rclone reports. The Nextflow `work/` directory and `.nextflow.log` remain in the launch directory rather than `--outdir`; keep them until transfer verification is complete if detailed troubleshooting or `-resume` may be needed.
