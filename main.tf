data "aws_region" "current" {}

# =====================================================================
# Security Groups chaines : Internet -> ALB (80) -> instances (80)
# Regles en ressources separees : evite la dependance circulaire
# entre les deux SG (chacun reference l'autre).
# =====================================================================

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "ALB ${var.name} - HTTP depuis Internet"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260:ALB public, seul point d entree de l application. Voir SECURITE.md
  security_group_id = aws_security_group.alb.id
  description       = "HTTP public"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Vers les instances web uniquement"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.web.id
}

resource "aws_security_group" "web" {
  name        = "${var.name}-web"
  description = "Instances ${var.name} - HTTP depuis ALB uniquement"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  #checkov:skip=CKV_AWS_260:Faux positif, la source est le SG de l ALB (referenced_security_group_id), aucun CIDR
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP depuis ALB seulement"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb.id
}

# Seule sortie autorisee : HTTPS (depots de paquets Amazon Linux, API SSM)
resource "aws_vpc_security_group_egress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS sortant - paquets et API AWS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# =====================================================================
# Description d'une instance
# =====================================================================

resource "aws_launch_template" "web" {
  name_prefix   = "${var.name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  # IMDSv2 exige : les metadonnees ne repondent qu'avec un jeton de session
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Disque racine chiffre
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted             = true
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  # Le script recoit le NOM de l'environnement et le CHEMIN du secret, jamais sa valeur
  user_data = base64encode(templatefile("${path.module}/bootstrap.sh", {
    environment           = var.environment
    region                = data.aws_region.current.region
    secret_parameter_name = var.secret_parameter_name
  }))
}

# =====================================================================
# Repartiteur de charge
# =====================================================================

resource "aws_lb" "web" {
  #checkov:skip=CKV_AWS_150:Protection contre la suppression desactivee, l infrastructure est detruite apres chaque session de lab
  #checkov:skip=CKV_AWS_91:Journaux d acces ALB non actives, ils exigent un bucket S3 cree par Terraform (interdit dans le cadre du lab)
  #checkov:skip=CKV2_AWS_28:Pas de WAF, hors perimetre du projet
  #checkov:skip=CKV2_AWS_20:Pas de redirection vers HTTPS, aucun certificat disponible dans le lab
  name                       = var.name
  load_balancer_type         = "application"
  subnets                    = var.subnet_ids
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "web" {
  #checkov:skip=CKV_AWS_378:HTTP entre ALB et instances dans le VPC, pas de certificat dans le lab
  name                 = "${var.name}-web"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:Pas de HTTPS, le lab ne fournit ni domaine ni certificat. Voir SECURITE.md
  #checkov:skip=CKV_AWS_103:Pas de TLS pour la meme raison
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# =====================================================================
# Groupe d'auto-scaling
# =====================================================================

resource "aws_autoscaling_group" "web" {
  name                      = "${var.name}-web"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  # Un changement de Launch Template remplace les instances progressivement
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-web"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "NovaSphere"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}
