# route53

Records-as-code for existing hosted zones. Zones are data lookups only; this
module never creates or deletes a zone. Onboard a zone incrementally: declare
its records, `import` the ones that already exist, and require a create-only
plan for anything new. Alias records set `alias`; plain records set
`ttl`/`values`.
