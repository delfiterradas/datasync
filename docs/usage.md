# nf-core/datasync: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/datasync/usage](https://nf-co.re/datasync/usage)

> Pipeline parameter documentation is generated automatically from [`nextflow_schema.json`](../nextflow_schema.json). This page explains how to prepare a transfer and operate the pipeline.

## Prerequisites

Install Nextflow 25.10.4 or later and use a supported software profile. Docker or Singularity/Apptainer is recommended for reproducibility. Ensure that the account running Nextflow can read each source and checksum manifest and can write to every destination.

For cloud or other authenticated rclone remotes, create an [rclone configuration](https://rclone.org/docs/) and pass it with `--rclone_config`. The configuration applies to remote **sources and destinations**. The pipeline has currently been tested for transfers between S3 buckets. Other rclone-supported layouts, such as Azure Blob Storage to S3 or transfers between S3-compatible providers, should be configured and validated against the upstream rclone documentation for each provider before use.

## Samplesheet input

Supply a comma-separated samplesheet with `--input`:

```bash
--input /path/to/samplesheet.csv
```

Each row describes an independent transfer. The header names are fixed; columns may be in any order.

| Column         | Required            | Description                                                                                                                                                                                                                             |
| -------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`       | Yes                 | Unique identifier used in task labels and output report names. It must not contain whitespace. Use a unique value for each row to prevent published report files from colliding.                                                        |
| `input`        | Yes                 | Source file or directory. This can be a local path, HTTP(S) URL, object-storage URL such as `s3://bucket/prefix`, or configured remote such as `source_s3:bucket/prefix` or `source_azure:container/prefix`. Whitespace is not allowed. |
| `output_path`  | Yes                 | Destination directory understood by rclone, such as `/archive/runs`, `s3://bucket/prefix`, or a configured `remote:path`. Whitespace is not allowed.                                                                                    |
| `checksum_md5` | One checksum column | MD5 sum file (`.csv` or `.tsv`) used to validate `input` before copying. Leave empty when using SHA-256 only.                                                                                                                           |
| `checksum_sha` | One checksum column | SHA-256 sum file (`.csv` or `.tsv`) used to validate `input` before copying. Leave empty when using MD5 only.                                                                                                                           |

At least one checksum manifest is required on every row. If both are supplied, both validations run. Checksum files must use the format accepted by [`rclone checksum`](https://rclone.org/commands/rclone_checksum/): one hash and one path per line, with paths relative to the source root. Despite the permitted `.csv`/`.tsv` filename suffix, the contents are checksum-manifest text rather than a table with a header.

Example:

```csv title="samplesheet.csv"
sample,input,output_path,checksum_md5,checksum_sha
run_001,/data/run_001,s3://archive/runs,/data/checksums/run_001_md5.tsv
reference,https://example.org/reference.fa,/data/references,,/data/checksums/reference_sha256.tsv
run_002,/data/run_002,archive:runs,/data/checksums/run_002_md5.tsv,/data/checksums/run_002_sha256.tsv
```

An [example samplesheet](../assets/samplesheet.csv) is included in the repository.

## Configuring rclone remotes

The file supplied with `--rclone_config` uses rclone's INI-style format. Each `[name]` section defines a remote, and samplesheet paths refer to it as `name:path`. The remote name is an arbitrary local label; it does not need to match the provider or bucket name. The pipeline's documented and tested configuration pattern is S3-to-S3 transfer. One file may contain several sections, so other cloud-to-cloud transfers can define both providers in the same file, but provider-specific options should be taken from the relevant rclone documentation rather than inferred from the S3 example:

```text
source_s3:incoming/run_001
archive_azure:research-archive/run_001
```

Create the file interactively where possible:

```bash
rclone config --config /secure/rclone.conf
rclone listremotes --config /secure/rclone.conf
```

Then provide that exact file to the pipeline:

```bash
nextflow run nf-core/datasync \
    -profile docker \
    --input samplesheet.csv \
    --outdir results \
    --rclone_config /secure/rclone.conf
```

### S3 and S3-compatible storage

The main use case tested for nf-core/datasync is transferring files between S3 buckets. An S3 remote specifies the provider, region, and credentials. For example:

```ini title="rclone.conf"
[s3]
type = s3
provider = AWS
access_key_id = YOUR_ACCESS_KEY_ID
secret_access_key = YOUR_SECRET_ACCESS_KEY
region = eu-central-1
```

The corresponding input values could be `source_s3:incoming/run_001` and `institutional_s3:project/run_002`. Provider-specific settings vary: consult the [rclone S3 documentation](https://rclone.org/s3/) and your storage provider's endpoint, region, addressing-style, and credential documentation rather than copying example values unchanged.

The pipeline also accepts an `s3://bucket/path` source or destination. In that form, ensure credentials and provider settings are available to both Nextflow and rclone in the execution environment. A named remote such as `source_s3:bucket/path` makes the selected configuration section explicit and is preferable when a config file contains multiple S3 providers.

## Destination layout

The pipeline preserves the source basename:

- for a file source, rclone copies the file into `output_path`, and validation expects `output_path/<source filename>`;
- for a directory source, the pipeline appends the source directory name, so `/data/run_001` with `output_path=/archive/runs` is copied and checked at `/archive/runs/run_001`.

A trailing slash on `output_path` is removed before these paths are constructed. Ensure that a destination does not already contain unrelated files: post-copy validation uses `rclone check --one-way`, which checks that source content exists and matches at the destination while tolerating destination-only files.

## Running the pipeline

A typical local-to-cloud run is:

```bash
nextflow run nf-core/datasync \
    -r <VERSION> \
    -profile docker \
    --input /data/samplesheet.csv \
    --outdir /data/datasync-results \
    --rclone_config /secure/rclone.conf
```

`--outdir` stores logs, integrity reports, MultiQC, and execution metadata. It does **not** override the transfer destinations in the samplesheet.

To inspect the proposed copy without writing destination data:

```bash
nextflow run nf-core/datasync \
    -r <VERSION> \
    -profile docker \
    --input /data/samplesheet.csv \
    --outdir /data/datasync-dry-run \
    --rclone_config /secure/rclone.conf \
    --rclone_dry_run
```

The checksum and post-copy check stages still run during a dry run. Consequently, post-copy results reflect whatever was already present at the destination rather than a simulated final state.

### Parameter files

Frequently reused settings can be stored in YAML or JSON and loaded with `-params-file`:

```yaml title="params.yaml"
input: /data/samplesheet.csv
outdir: /data/datasync-results
rclone_config: /secure/rclone.conf
multiqc_title: July archive transfer
```

```bash
nextflow run nf-core/datasync -r <VERSION> -profile docker -params-file params.yaml
```

Do not use `-c` for pipeline parameters. Use it only for Nextflow executor, resources, and other infrastructure configuration.

## Understanding completion and integrity

For each row, the pipeline first validates supplied checksum manifests, performs the copy, and then compares source and destination. Rclone comparison commands write status reports even when differences are found, allowing all results to be collected in MultiQC. Therefore, a successful Nextflow run means the workflow completed; it does **not by itself** prove every object matched. Review `multiqc/multiqc_report.html` and the reports under `rclone/`, especially lines marked `-`, `+`, `*`, or `!` (see [output documentation](output.md)).

## Resuming and reproducibility

Pin a released pipeline version with `-r` and record the samplesheet, parameter file, rclone configuration provenance (without exposing secrets), and generated `pipeline_info/` directory. To restart an interrupted run with unchanged inputs and parameters, add `-resume`:

```bash
nextflow run nf-core/datasync -r <VERSION> -profile docker -params-file params.yaml -resume
```

Nextflow may reuse completed tasks from its work directory. Before retrying a partial transfer, confirm the destination contents are acceptable; rclone copy skips identical files but may update changed ones.

Update the locally cached pipeline when intentionally moving to a newer release:

```bash
nextflow pull nf-core/datasync
```

## Resource configuration

The `rclone` processes use the `process_low` label. Configure executors and override CPU, memory, or time in a Nextflow config, for example:

```groovy title="resources.config"
process {
    withLabel: process_low {
        cpus = 8
        memory = '16 GB'
        time = '12h'
    }
}
```

Run with `-c resources.config`. `rclone` derives its checker count from allocated CPUs, and the copy step uses roughly half that count (minimum one) for parallel transfers.
