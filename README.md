# Purpose

This is to attempt to demonstrate/reproduce an issue cropping up in a Terraform 0.12.29 -> 0.13.x migration

## What's the issue?

We use a system of nested modules. There is a module that deploys "core infrastructure" including a storage account. Only the storage account is relevant and reproduced here.

Redis is an optional component, so this is a separate module that can be used as needed. Where required, a Premium Redis cache is deployed and configured to do RDB replication to the storage account mentioned above. This requires the storage account to be a data source in the Redis module.

```
root
|__ module_infra
|   |  in:  resource_group_name
|   |  out: storage_account_name
|   |__ module_storage
|         in:  resource_group_name
|         out: storage_account_name
|__ module_redis
       in: resource_group_name
       in: storage_account_name
```

## To execute

* Create a resource group. Our module is used by deploying into an existing resource group, which is passed in as the `resource_group_name` variable and used as a data source to read the location, so that's the usage that this repo reproduces.
* Pick a Terraform version; I use `tfenv`
* Run `terraform plan -var=resource_group_name=${existing_group} -var=unique_id=${unique_id}`
* Check the `plan` output
* Edit `module_test.go` to include the name of this resource group
* From a shell with correctly set Azure credentials, run `go test -v -timeout 3h`
* Wait patiently...Azure Redis caches regularly take upwards of 30 minutes to complete successfully, and a similar amount of time to destroy.
* NOTE: this reproduction uses a `unique_id` variable to name resources since storage accounts have to be globally unique (the real modules don't do this, we name them according to policy). This should not affect this test because the ID is generated at the start of the test and then would be used for both the `Apply` and `Idempotent` steps of the test

## Expected results

Running `terraform plan` will show the creation of both a Storage Account resourse, and a Redis resource. The `terratest` test will run and complete successfully indicating that the `plan` succeeded, the `apply` succeeded, and a second `plan` reports no changes.

## Actual results

### 0.12.29

The `plan` [contains the expected resources](0.12.29.md). The test passes successfully.

### 0.13.3

The `plan` [fails](0.13.3.md). The test cannot be run in this state, because of the failing plan. It seems that the implicit dependency caused by referring to the output from the `core` module as an input to the `redis` module is no longer sufficient?

### 0.13.3 with depends_on

I also tried to use the new explicit module `depends_on` functionality.

With this in place, the `plan` [succeeds](0.13.3_depends_on.md). The test can now be run. However the `Idempotent` step fails because the second `plan` shows that the Redis cache must be replaced due to the "new" location (which isn't new at all since it's based off the location of the pre-existing resource group, which has not moved and is not controlled by this module).

## Summary

It seems like starting in 0.13.x, without using `depends_on`, `module.redis` is not dependent enough on `module.core` so the 
dependency between the modules is broken and they can't be deployed. But then module `depends_on` makes the module *too* dependent on `module.core` and it will show changes even when none have been made. The Terraform 0.12.x behaviour was the perfect balance and we've rolled out several of these modules both with and without a Redis cache successfully.