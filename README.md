# Promfetcher-release

This is the bosh release for deploying [promfetcher](https://github.com/orange-cloudfoundry/promfetcher) alongside cloud foundry.

[promfetcher](https://github.com/orange-cloudfoundry/promfetcher) was made for [cloud foundry](https://cloudfoundry.org) and the idea behind is to give ability to fetch 
metrics from all app instances in a cloud foundry environment.

User can retrieve is metrics by simply call `/v1/apps/[org_name]/[space_name]/[app_name]/metrics` which will merge all metrics 
from instances and add labels:
- `organization_id`
- `space_id` 
- `app_id`
- `organization_name`
- `space_name` 
- `app_name`
- `index` - app instance index
- `instance_id` - the same as index
- `instance` - real container address

It also a service broker for cloud foundry to be able to set metrics endpoint for a particular which not use `/metrics` by default.

## Example

Metrics from app instance 0:
```
go_memstats_mspan_sys_bytes{} 65536
```

Metrics from app instance 1:
```
go_memstats_mspan_sys_bytes{} 5600
```

become:
```
go_memstats_mspan_sys_bytes{organization_id="7d66c7e7-196a-40e5-a259-f5afaf6a56f4",space_id="2ac205af-e18f-49a9-9a8b-48ef2bab2292",app_id="621617db-9dd9-4211-8848-b245f3ea16b2",organization_name="system",space_name="tools",app_name="app",index="0",instance_id="0",instance="172.76.112.90:61038"} 65536
go_memstats_mspan_sys_bytes{organization_id="7d66c7e7-196a-40e5-a259-f5afaf6a56f4",space_id="2ac205af-e18f-49a9-9a8b-48ef2bab2292",app_id="621617db-9dd9-4211-8848-b245f3ea16b2",organization_name="system",space_name="tools",app_name="app",index="1",instance_id="1",instance="172.76.112.91:61010"} 65536
```

## Deploy on cloud foundry

Manifest has been created to be set as an ops file for [cloud foundry deployment](https://github.com/cloudfoundry/cf-deployment).

Simply add ops file to your [cf-deployment](https://github.com/cloudfoundry/cf-deployment):
- [/manifests/operations/cf/cf.yml](/manifests/operations/cf/cf.yml)
- *(Optional)* [/manifests/operations/cf/enable-router-routing.yml](/manifests/operations/cf/enable-router-routing.yml):
 for using a route registrar to be able to resolve https://promfetcher.system.domain . But using it will make gorouter a bottleneck to get 
 metrics, prefer using a proper dns entry for resolving https://promfetcher.system.domain and set entries to your load balancer to point directly to vm
 instead of using gorouter
- *(Optional)* [/manifests/operations/cf/enable-backup.yml](/manifests/operations/cf/enable-backup.yml): Enable bbr backup/restore.
- *(Optional)* [/manifests/operations/cf/disable-broker.yml](/manifests/operations/cf/disable-broker.yml): Disable broker functionality and remove database link because it becomes unnecessary.

## Add broker for let user choose its endpoint

Run: `bosh -d cf run-errand --instance=promfetch/0 promfetch-broker-registrar`