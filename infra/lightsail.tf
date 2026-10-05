# =============================================================================
# Lightsail origin — Rails API + Postgres + Caddy on one instance
# =============================================================================
# Postgres data lives on the instance disk. Replacing the instance (bundle or
# blueprint change) wipes it, so prevent_destroy guards against that. To resize:
# take a fresh backup, create a new instance, restore (see docs/RUNBOOK.md).

resource "aws_lightsail_key_pair" "admin" {
  name       = "justinnegron-admin"
  public_key = var.admin_ssh_public_key
}

resource "aws_lightsail_instance" "app" {
  name              = "justinnegron-app"
  availability_zone = "${var.aws_region}a"
  blueprint_id      = "ubuntu_24_04"
  bundle_id         = var.lightsail_bundle_id
  key_pair_name     = aws_lightsail_key_pair.admin.name
  ip_address_type   = "dualstack"

  # Daily snapshot (UTC), after the 08:30 pg_dump to S3
  add_on {
    type          = "AutoSnapshot"
    snapshot_time = "09:00"
    status        = "Enabled"
  }

  tags = {
    Environment = var.environment
    Project     = "justinnegron-dev"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_lightsail_static_ip" "app" {
  name = "justinnegron-app-ip"
}

resource "aws_lightsail_static_ip_attachment" "app" {
  static_ip_name = aws_lightsail_static_ip.app.name
  instance_name  = aws_lightsail_instance.app.name
}

# Replaces Lightsail's default rules (22 + 80 open to the world)
resource "aws_lightsail_instance_public_ports" "app" {
  instance_name = aws_lightsail_instance.app.name

  # HTTPS for CloudFront and Let's Encrypt (TLS-ALPN challenge). Requests without
  # the CloudFront secret header are rejected by the app.
  port_info {
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidrs      = ["0.0.0.0/0"]
    ipv6_cidrs = ["::/0"]
  }

  # SSH from your IP plus the Lightsail browser console
  port_info {
    protocol          = "tcp"
    from_port         = 22
    to_port           = 22
    cidrs             = ["${var.ssh_allowed_ip}/32"]
    cidr_list_aliases = ["lightsail-connect"]
  }
}

resource "aws_route53_record" "origin" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "origin.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_lightsail_static_ip.app.ip_address]
}
