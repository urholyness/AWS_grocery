# ── SNS Topic ────────────────────────────────────────────────────────────────
# This is the "notification channel". The CloudWatch alarm sends alerts here,
# and everyone subscribed to this topic receives them.

resource "aws_sns_topic" "cpu_alert" {
  name = "${var.project_name}-cpu-alert"

  tags = {
    Name    = "${var.project_name}-cpu-alert"
    Project = var.project_name
  }
}

# ── SNS Subscription (Email) ─────────────────────────────────────────────────
# Subscribes your email address to the topic.
# After terraform apply, AWS will send a confirmation email — you MUST click
# the link in it or the alarm notifications will never arrive.

resource "aws_sns_topic_subscription" "cpu_alert_email" {
  topic_arn = aws_sns_topic.cpu_alert.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── CloudWatch Alarm ─────────────────────────────────────────────────────────
# Watches the EC2 instance's CPU utilization every 5 minutes.
# If the average goes above 80% for 1 consecutive period, it fires the alarm
# and sends a message to the SNS topic above.

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  alarm_description   = "Triggers when EC2 CPU utilization exceeds 80% for 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1       # how many periods must breach before alarm fires
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300     # 300 seconds = 5 minutes
  statistic           = "Average"
  threshold           = 80      # percentage

  dimensions = {
    InstanceId = aws_instance.aws_grocery_instance.id
  }

  alarm_actions = [aws_sns_topic.cpu_alert.arn]  # what to do when alarm fires
  ok_actions    = [aws_sns_topic.cpu_alert.arn]  # also notify when it recovers

  tags = {
    Name    = "${var.project_name}-high-cpu-alarm"
    Project = var.project_name
  }
}

# ── Output ───────────────────────────────────────────────────────────────────
output "sns_topic_arn" {
  description = "ARN of the SNS topic used for CPU alerts"
  value       = aws_sns_topic.cpu_alert.arn
}
