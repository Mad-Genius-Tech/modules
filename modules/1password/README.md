# 1Password to Secrets Manager

This module copies selected 1Password item fields into AWS Secrets Manager.

Use `password_whitelist` to select field labels. When an item contains the same
field labels in more than one section, also set `password_section` to the exact
1Password section label. Section selection happens before whitelist or exclude
filtering, so fields with matching labels elsewhere in the item cannot override
the intended values through merge ordering.

```hcl
secrets = {
  "basic-auth" = {
    secret_prefix      = "example/dev"
    password_vault     = "example-vault-id"
    password_title     = "Example Basic Auth"
    password_section   = "BasicAuth"
    password_whitelist = ["username", "password"]
  }
}
```

When `password_section` is set, the plan fails unless that exact section-map
label exists. Whitelisted fields must also exist and be populated in that
section. Section labels used for secret sync must be unique within the item.
Omitting `password_section` preserves the module's existing behavior of
merging matching labels across all item sections.
