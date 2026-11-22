# terraform-aws-novasphere-web

Module NovaSphere : application web derriere un ALB, sur un groupe d'auto-scaling.

- Security Groups chaines : Internet -> ALB (80) -> instances (80 depuis l'ALB uniquement), pas de SSH
- Launch Template Amazon Linux 2023, IMDSv2 exige, amorcage court (bootstrap.sh.tftpl)
- Le secret est lu au demarrage dans Parameter Store via le profil d'instance, jamais ecrit dans user_data
- ASG avec health check ELB et instance refresh

Entrees principales : name, environment, vpc_id, subnet_ids, ami_id, instance_profile_name, secret_parameter_name.
Sorties : alb_dns_name, asg_name, alb_security_group_id, web_security_group_id.
