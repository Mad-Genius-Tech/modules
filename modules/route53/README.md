# route53

Records-as-code for existing hosted zones. Zones are data lookups only; this
module never creates or deletes a zone. Onboard a zone incrementally: declare
its records, `import` the ones that already exist, and require a create-only
plan for anything new. Alias records set `alias`; plain records set
`ttl`/`values`.

For an Application Load Balancer alias, set
`alias.application_load_balancer_name`. The module resolves the ALB DNS name
and hosted-zone ID and emits the `dualstack.` alias target that Route53 stores.
For other alias targets, set both `alias.name` and `alias.zone_id` explicitly.
