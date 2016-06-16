# azure-blobstore-concourse-resource

Versions objects in an Azure blobstore container, by pattern-matching filenames to identify
version numbers.

## Source Configuration

* `container`: *Required.* The name of the container.

* `storage_account_name`: *Required.* The name of the Azure storage account that has the container. **The storage account must use Standard storage, NOT Premium.**

* `storage_access_key`: *Optional.* The Azure storage access key for the storage account. If the storage access key is not specified, the container must be public ("Container" access policy, NOT "Blob" or "Private"), and `out` will throw an error.

* `regexp`: *Required.* The pattern to match filenames against within the Azure storage container. The first
  grouped match is used to extract the version. At least one capture group must be
  specified, with parentheses.

  The version extracted from this pattern is used to version the resource.
  Semantic versions, or just numbers, are supported. Accordingly, full regular
  expressions are supported, to specify the capture groups.

* `environment`: *Optional.* The Azure environment. Valid values are `AzureCloud` and `AzureChinaCloud`. If `environment` is not specified, the value defaults to `AzureCloud`.

## Behavior

### `check`: Extract versions from the bucket.

Objects will be found via the pattern configured by `regexp`. The versions
will be used to order them (using [semver](http://semver.org/)). Each
object's filename is the resulting version.


### `in`: Fetch an object from the bucket.

Places the following files in the destination:

* `(filename)`: The file fetched from the bucket.

* `version`: The version identified in the file name.

#### Parameters

*None.*


### `out`: Upload an object to the container.

Given a file specified by `file`, upload it to the Azure storage container. The new file will be uploaded to the directory that the regexp
searches in.


#### Parameters

* `file`: *Required.* Path to the file to upload, provided by an output of a task.
  If multiple files are matched by the glob, an error is raised. The file which
  matches will be placed into the directory structure on S3 as defined in `regexp`
  in the resource definition. The matching syntax is bash glob expansion, so
  no capture groups, etc.


## Example Configuration

The following concourse pipeline downloads the latest bosh-init release from a S3 bucket, and uploads to an Azure blobstore container in `bosh-init` folder, then downloads it again from that Azure blobstore container and uploads to another S3 bucket in `bosh` folder.

```
---
resource_types:
- name: azure-blob
  type: docker-image
  source:
    repository: cfcloudops/azure-blobstore-concourse-resource
jobs:
- name: s3-to-azure-blob
  serial: true
  plan:
  - get: bosh-init
    trigger: true
  - put: azure-blob
    params:
      file: bosh-init/bosh-init*

- name: azure-blob-to-s3china
  serial: true
  plan:
  - get: azure-blob
    passed: [s3-to-azure-blob]
    trigger: true
  - put: s3china
    params:
      file: azure-blob/bosh-init-*

resources:
- name: azure-blob
  type: azure-blob
  source:
    container: con1
    storage_account_name: your_storage_account_name
    storage_access_key: your_storage_access_key
    regexp: bosh-init/bosh-init-([0-9\.]+)-linux-amd64

- name: s3china
  type: s3
  source:
    regexp: bosh/bosh-init-([0-9\.]+)-linux-amd64
    bucket: your_bucket
    region_name: cn-north-1
    endpoint: s3.cn-north-1.amazonaws.com.cn
    access_key_id: your_aws_access_key
    secret_access_key: your_aws_secret

- name: bosh-init
  type: s3
  source:
    regexp: bosh-init-([0-9\.]+)-linux-amd64
    bucket: bosh-init-artifacts
```
