
resource "aws_glue_catalog_database" "cf_logs_database" {
  name = "${local.name}-accesslogs-db"
}

resource "aws_glue_catalog_table" "partitioned_gz_table" {
  name          = "partitioned_gz"
  database_name = aws_glue_catalog_database.cf_logs_database.name
  description   = "Gzip logs delivered by Amazon CloudFront partitioned"
  table_type    = "EXTERNAL_TABLE"
  parameters = {
    "skip.header.line.count" = "2"
  }
  storage_descriptor {
    location      = "s3://${local.s3_bucket}/${var.gz_key_prefix}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    columns {
      name = "date"
      type = "date"
    }
    columns {
      name = "time"
      type = "string"
    }
    columns {
      name = "location"
      type = "string"
    }
    columns {
      name = "bytes"
      type = "bigint"
    }
    columns {
      name = "request_ip"
      type = "string"
    }
    columns {
      name = "method"
      type = "string"
    }
    columns {
      name = "host"
      type = "string"
    }
    columns {
      name = "uri"
      type = "string"
    }
    columns {
      name = "status"
      type = "int"
    }
    columns {
      name = "referrer"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "query_string"
      type = "string"
    }
    columns {
      name = "cookie"
      type = "string"
    }
    columns {
      name = "result_type"
      type = "string"
    }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "host_header"
      type = "string"
    }
    columns {
      name = "request_protocol"
      type = "string"
    }
    columns {
      name = "request_bytes"
      type = "bigint"
    }
    columns {
      name = "time_taken"
      type = "float"
    }
    columns {
      name = "xforwarded_for"
      type = "string"
    }
    columns {
      name = "ssl_protocol"
      type = "string"
    }
    columns {
      name = "ssl_cipher"
      type = "string"
    }
    columns {
      name = "response_result_type"
      type = "string"
    }
    columns {
      name = "http_version"
      type = "string"
    }
    columns {
      name = "fle_status"
      type = "string"
    }
    columns {
      name = "fle_encrypted_fields"
      type = "int"
    }
    columns {
      name = "c_port"
      type = "int"
    }
    columns {
      name = "time_to_first_byte"
      type = "float"
    }
    columns {
      name = "x_edge_detailed_result_type"
      type = "string"
    }
    columns {
      name = "sc_content_type"
      type = "string"
    }
    columns {
      name = "sc_content_len"
      type = "bigint"
    }
    columns {
      name = "sc_range_start"
      type = "bigint"
    }
    columns {
      name = "sc_range_end"
      type = "bigint"
    }
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = "\t"
        "serialization.format" = "\t"
      }
    }
  }
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
  partition_keys {
    name = "hour"
    type = "string"
  }
}

resource "aws_glue_catalog_table" "partitioned_parquet_table" {
  name          = "partitioned_parquet"
  database_name = aws_glue_catalog_database.cf_logs_database.name
  description   = "Parquet format access logs as transformed from gzip version"
  table_type    = "EXTERNAL_TABLE"
  parameters = {
    "has_encrypted_data"  = "false"
    "parquet.compression" = "SNAPPY"
  }
  storage_descriptor {
    location      = "s3://${local.s3_bucket}/${var.parquet_key_prefix}"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
    columns {
      name = "date"
      type = "date"
    }
    columns {
      name = "time"
      type = "string"
    }
    columns {
      name = "location"
      type = "string"
    }
    columns {
      name = "bytes"
      type = "bigint"
    }
    columns {
      name = "request_ip"
      type = "string"
    }
    columns {
      name = "method"
      type = "string"
    }
    columns {
      name = "host"
      type = "string"
    }
    columns {
      name = "uri"
      type = "string"
    }
    columns {
      name = "status"
      type = "int"
    }
    columns {
      name = "referrer"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "query_string"
      type = "string"
    }
    columns {
      name = "cookie"
      type = "string"
    }
    columns {
      name = "result_type"
      type = "string"
    }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "host_header"
      type = "string"
    }
    columns {
      name = "request_protocol"
      type = "string"
    }
    columns {
      name = "request_bytes"
      type = "bigint"
    }
    columns {
      name = "time_taken"
      type = "float"
    }
    columns {
      name = "xforwarded_for"
      type = "string"
    }
    columns {
      name = "ssl_protocol"
      type = "string"
    }
    columns {
      name = "ssl_cipher"
      type = "string"
    }
    columns {
      name = "response_result_type"
      type = "string"
    }
    columns {
      name = "http_version"
      type = "string"
    }
    columns {
      name = "fle_status"
      type = "string"
    }
    columns {
      name = "fle_encrypted_fields"
      type = "int"
    }
    columns {
      name = "c_port"
      type = "int"
    }
    columns {
      name = "time_to_first_byte"
      type = "float"
    }
    columns {
      name = "x_edge_detailed_result_type"
      type = "string"
    }
    columns {
      name = "sc_content_type"
      type = "string"
    }
    columns {
      name = "sc_content_len"
      type = "bigint"
    }
    columns {
      name = "sc_range_start"
      type = "bigint"
    }
    columns {
      name = "sc_range_end"
      type = "bigint"
    }
  }
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
  partition_keys {
    name = "hour"
    type = "string"
  }
}

resource "aws_glue_catalog_table" "combined_view" {
  name          = "combined"
  database_name = aws_glue_catalog_database.cf_logs_database.name
  description   = "combined view over gzip and parquet tables"
  table_type    = "VIRTUAL_VIEW"

  parameters = {
    "presto_view" = "true"
  }

  storage_descriptor {
    columns {
      name = "date"
      type = "date"
    }
    columns {
      name = "time"
      type = "string"
    }
    columns {
      name = "location"
      type = "string"
    }
    columns {
      name = "bytes"
      type = "bigint"
    }
    columns {
      name = "request_ip"
      type = "string"
    }
    columns {
      name = "method"
      type = "string"
    }
    columns {
      name = "host"
      type = "string"
    }
    columns {
      name = "uri"
      type = "string"
    }
    columns {
      name = "status"
      type = "int"
    }
    columns {
      name = "referrer"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "query_string"
      type = "string"
    }
    columns {
      name = "cookie"
      type = "string"
    }
    columns {
      name = "result_type"
      type = "string"
    }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "host_header"
      type = "string"
    }
    columns {
      name = "request_protocol"
      type = "string"
    }
    columns {
      name = "request_bytes"
      type = "bigint"
    }
    columns {
      name = "time_taken"
      type = "float"
    }
    columns {
      name = "xforwarded_for"
      type = "string"
    }
    columns {
      name = "ssl_protocol"
      type = "string"
    }
    columns {
      name = "ssl_cipher"
      type = "string"
    }
    columns {
      name = "response_result_type"
      type = "string"
    }
    columns {
      name = "http_version"
      type = "string"
    }
    columns {
      name = "fle_status"
      type = "string"
    }
    columns {
      name = "fle_encrypted_fields"
      type = "int"
    }
    columns {
      name = "c_port"
      type = "int"
    }
    columns {
      name = "time_to_first_byte"
      type = "float"
    }
    columns {
      name = "x_edge_detailed_result_type"
      type = "string"
    }
    columns {
      name = "sc_content_type"
      type = "string"
    }
    columns {
      name = "sc_content_len"
      type = "bigint"
    }
    columns {
      name = "sc_range_start"
      type = "bigint"
    }
    columns {
      name = "sc_range_end"
      type = "bigint"
    }
    columns {
      name = "year"
      type = "string"
    }
    columns {
      name = "month"
      type = "string"
    }
    columns {
      name = "day"
      type = "string"
    }
    columns {
      name = "hour"
      type = "string"
    }
    columns {
      name = "file"
      type = "string"
    }
  }

  view_original_text = jsonencode({
    originalSql = "SELECT *, \"$path\" as file FROM ${aws_glue_catalog_database.cf_logs_database.name}.${aws_glue_catalog_table.partitioned_gz_table.name} WHERE (concat(year, month, day, hour) >= date_format(date_trunc('hour', ((current_timestamp - INTERVAL '15' MINUTE) - INTERVAL '1' HOUR)), '%Y%m%d%H')) UNION ALL SELECT *, \"$path\" as file FROM ${aws_glue_catalog_database.cf_logs_database.name}.${aws_glue_catalog_table.partitioned_parquet_table.name} WHERE (concat(year, month, day, hour) < date_format(date_trunc('hour', ((current_timestamp - INTERVAL  '15' MINUTE) - INTERVAL '1' HOUR)), '%Y%m%d%H'))"
    catalog     = "awsdatacatalog"
    schema      = aws_glue_catalog_database.cf_logs_database.name

    columns = [
      {
        name = "date"
        type = "date"
      },
      {
        name = "time"
        type = "varchar"
      },
      {
        name = "location"
        type = "varchar"
      },
      {
        name = "bytes"
        type = "bigint"
      },
      {
        name = "request_ip"
        type = "varchar"
      },
      {
        name = "method"
        type = "varchar"
      },
      {
        name = "host"
        type = "varchar"
      },
      {
        name = "uri"
        type = "varchar"
      },
      {
        name = "status"
        type = "integer"
      },
      {
        name = "referrer"
        type = "varchar"
      },
      {
        name = "user_agent"
        type = "varchar"
      },
      {
        name = "query_string"
        type = "varchar"
      },
      {
        name = "cookie"
        type = "varchar"
      },
      {
        name = "result_type"
        type = "varchar"
      },
      {
        name = "request_id"
        type = "varchar"
      },
      {
        name = "host_header"
        type = "varchar"
      },
      {
        name = "request_protocol"
        type = "varchar"
      },
      {
        name = "request_bytes"
        type = "bigint"
      },
      {
        name = "time_taken"
        type = "real"
      },
      {
        name = "xforwarded_for"
        type = "varchar"
      },
      {
        name = "ssl_protocol"
        type = "varchar"
      },
      {
        name = "ssl_cipher"
        type = "varchar"
      },
      {
        name = "response_result_type"
        type = "varchar"
      },
      {
        name = "http_version"
        type = "varchar"
      },
      {
        name = "fle_status"
        type = "varchar"
      },
      {
        name = "fle_encrypted_fields"
        type = "integer"
      },
      {
        name = "c_port"
        type = "integer"
      },
      {
        name = "time_to_first_byte"
        type = "real"
      },
      {
        name = "x_edge_detailed_result_type"
        type = "varchar"
      },
      {
        name = "sc_content_type"
        type = "varchar"
      },
      {
        name = "sc_content_len"
        type = "bigint"
      },
      {
        name = "sc_range_start"
        type = "bigint"
      },
      {
        name = "sc_range_end"
        type = "bigint"
      },
      {
        name = "year"
        type = "varchar"
      },
      {
        name = "month"
        type = "varchar"
      },
      {
        name = "day"
        type = "varchar"
      },
      {
        name = "hour"
        type = "varchar"
      },
      {
        name = "file"
        type = "varchar"
      }
    ]
  })
}
