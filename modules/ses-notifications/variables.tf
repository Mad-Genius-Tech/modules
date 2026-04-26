# --- HTTPS callbacks (optional: omit or leave empty to skip subscription) ---

variable "bounce_https_endpoint" {
  type        = string
  default     = null
  description = "HTTPS URL for the bounce SNS topic subscription. If null or empty, no subscription is created."
}

variable "complaint_https_endpoint" {
  type        = string
  default     = null
  description = "HTTPS URL for the complaint SNS topic subscription."
}

variable "delivery_https_endpoint" {
  type        = string
  default     = null
  description = "HTTPS URL for the delivery (success) SNS topic subscription."
}

variable "reputation_metrics_alarm_period_seconds" {
  type        = number
  default     = 3600
  description = "Period for Reputation.BounceRate and Reputation.ComplaintRate alarm metrics (seconds)."
}

variable "reputation_metrics_alarm_evaluation_periods" {
  type        = number
  default     = 1
  description = "Number of periods to evaluate for reputation alarms."
}

variable "reputation_bounce_rate_warn_threshold" {
  type        = number
  default     = 0.03
  description = "Trigger bounce warn alarm when Reputation.BounceRate >= this value (0.03 = 3%)."
}

variable "reputation_bounce_rate_page_threshold" {
  type        = number
  default     = 0.05
  description = "Trigger bounce page alarm when Reputation.BounceRate >= this value (0.05 = 5%)."
}

variable "reputation_complaint_rate_warn_threshold" {
  type        = number
  default     = 0.0005
  description = "Trigger complaint warn alarm when Reputation.ComplaintRate >= this value (0.0005 = 0.05%)."
}

variable "reputation_complaint_rate_page_threshold" {
  type        = number
  default     = 0.001
  description = "Trigger complaint page alarm when Reputation.ComplaintRate >= this value (0.001 = 0.1%)."
}

variable "reputation_alarm_sns_topic_arn" {
  type        = string
  default     = null
  description = "Single SNS topic ARN (or any CloudWatch alarm action) used by both warn and page reputation alarms. Empty disables alarm actions."
}

variable "reputation_alarms_enabled" {
  type        = bool
  default     = true
  description = "When false, no CloudWatch reputation alarms are created."
}

