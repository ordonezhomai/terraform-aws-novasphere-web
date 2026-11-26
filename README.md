# terraform-aws-novasphere-web

Module de l'equipe NovaSphere : la « pile web » commune a dev et prod.

| Ressource | Role |
|---|---|
| `aws_security_group.alb` + regles | HTTP 80 depuis Internet, sortie uniquement vers le SG des instances |
| `aws_security_group.web` + regles | HTTP 80 **depuis le SG de l'ALB uniquement**, sortie HTTPS 443 seulement, aucun SSH |
| `aws_launch_template.web` | Amazon Linux 2023, **IMDSv2 exige**, disque chiffre, profil d'instance, amorcage `bootstrap.sh` |
| `aws_lb.web`, `aws_lb_target_group.web`, `aws_lb_listener.http` | ALB, health check HTTP sur `/` |
| `aws_autoscaling_group.web` | min 2 / max 4, `health_check_type = "ELB"`, instance refresh |

`bootstrap.sh` installe et demarre nginx, puis lit le secret de **son** environnement dans Parameter Store
grace au profil d'instance. Le script recoit le nom de l'environnement et le chemin du secret par
`templatefile`, jamais la valeur du secret.

## Entrees

| Nom | Type | Defaut | Validation |
|---|---|---|---|
| `name` | string | — | 3 a 28 caracteres `[a-z0-9-]` |
| `environment` | string | — | `dev` ou `prod` |
| `vpc_id` | string | — | |
| `subnet_ids` | list(string) | — | au moins 2 |
| `ami_id` | string | — | |
| `instance_type` | string | `t3.micro` | |
| `instance_profile_name` | string | — | |
| `secret_parameter_name` | string | — | sous `/novasphere/dev/` ou `/novasphere/prod/` |
| `min_size` / `max_size` / `desired_capacity` | number | 2 / 4 / 2 | `min_size >= 2` |

## Sorties

`alb_dns_name`, `target_group_arn`, `asg_name`, `alb_security_group_id`, `web_security_group_id`.

## Versions

Une version par evolution, jamais modifiee apres publication.

| Tag | Changement |
|---|---|
| v1.0.0 | Premiere version |
| v1.0.1 | Descriptions de SG sans apostrophe (refusee par AWS) |
| v1.1.0 | Regles de SG en ressources separees, sortie des instances limitee a 443, disque chiffre, output `target_group_arn`, validations supplementaires, `bootstrap.sh` |

## Utilisation

```hcl
module "web" {
  source = "git::https://github.com/ordonezhomai/terraform-aws-novasphere-web.git?ref=v1.1.0"

  name                  = "novasphere-dev"
  environment           = "dev"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnets
  ami_id                = data.aws_ami.al2023.id
  instance_profile_name = "LabInstanceProfile"
  secret_parameter_name = aws_ssm_parameter.db_password.name
}
```
