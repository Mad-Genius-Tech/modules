

locals {
  template_files = fileset(var.templates_dir, "*/index.html")
  template_dirs = distinct([
    for file in local.template_files :
    split("/", file)[0]
  ])

  discovered_templates = {
    for dir in local.template_dirs : dir => {
      yaml_file    = fileexists("${var.templates_dir}/${dir}/main.yml") ? "${var.templates_dir}/${dir}/main.yml" : (fileexists("${var.templates_dir}/${dir}/main.yaml") ? "${var.templates_dir}/${dir}/main.yaml" : null)
      html_content = fileexists("${var.templates_dir}/${dir}/index.html") ? file("${var.templates_dir}/${dir}/index.html") : ""
      text_content = fileexists("${var.templates_dir}/${dir}/index.txt") ? file("${var.templates_dir}/${dir}/index.txt") : ""
    }
  }

  parsed_templates = {
    for dir, template in local.discovered_templates :
    dir => {
      # If yaml_file exists, parse it to get name and subject
      name      = template.yaml_file != null ? yamldecode(file(template.yaml_file))["name"] : dir
      subject   = template.yaml_file != null ? yamldecode(file(template.yaml_file))["subject"] : "Subject for ${dir}"
      html_part = template.html_content != "" ? template.html_content : null
      text_part = template.text_content != "" ? template.text_content : null
    }
  }
}

resource "aws_ses_template" "template" {
  for_each = local.parsed_templates
  name     = each.value.name
  subject  = each.value.subject
  html     = each.value.html_part
  text     = each.value.text_part
}
