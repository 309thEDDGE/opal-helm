# keycloak

![Version: 18.4.3-bb.2](https://img.shields.io/badge/Version-18.4.3--bb.2-informational?style=flat-square) ![AppVersion: 21.1.1](https://img.shields.io/badge/AppVersion-21.1.1-informational?style=flat-square)

Open Source Identity and Access Management For Modern Applications and Services

## Learn More
* [Application Overview](docs/overview.md)
* [Other Documentation](docs/)

## Pre-Requisites

* Kubernetes Cluster deployed
* Kubernetes config installed in `~/.kube/config`
* Helm installed

Install Helm

https://helm.sh/docs/intro/install/

## Deployment

* Clone down the repository
* cd into directory
```bash
helm install keycloak chart/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` |  |
| nameOverride | string | `""` |  |
| replicas | int | `1` |  |
| image.repository | string | `"registry1.dso.mil/ironbank/opensource/keycloak/keycloak"` |  |
| image.tag | string | `"21.1.2"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| imagePullSecrets[0].name | string | `"regcred"` |  |
| hostAliases | list | `[]` |  |
| enableServiceLinks | bool | `true` |  |
| podManagementPolicy | string | `"Parallel"` |  |
| updateStrategy | string | `"RollingUpdate"` |  |
| restartPolicy | string | `"Always"` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.labels | object | `{}` |  |
| serviceAccount.imagePullSecrets | list | `[]` |  |
| rbac.create | bool | `false` |  |
| rbac.rules | list | `[]` |  |
| podSecurityContext.fsGroup | int | `1000` |  |
| securityContext.runAsUser | int | `1000` |  |
| securityContext.runAsNonRoot | bool | `true` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| extraInitContainers | string | `""` |  |
| skipInitContainers | bool | `false` |  |
| extraContainers | string | `""` |  |
| lifecycleHooks | string | `""` |  |
| terminationGracePeriodSeconds | int | `60` |  |
| clusterDomain | string | `"cluster.local"` |  |
| command[0] | string | `"/opt/keycloak/bin/kc.sh"` |  |
| args[0] | string | `"start"` |  |
| extraEnv | string | `""` |  |
| extraEnvFrom | string | `"- secretRef:\n    name: '{{ include \"keycloak.fullname\" . }}-env'\n"` |  |
| priorityClassName | string | `""` |  |
| affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          {{- include \"keycloak.selectorLabels\" . \| nindent 10 }}\n        matchExpressions:\n          - key: app.kubernetes.io/component\n            operator: NotIn\n            values:\n              - test\n      topologyKey: kubernetes.io/hostname\n  preferredDuringSchedulingIgnoredDuringExecution:\n    - weight: 100\n      podAffinityTerm:\n        labelSelector:\n          matchLabels:\n            {{- include \"keycloak.selectorLabels\" . \| nindent 12 }}\n          matchExpressions:\n            - key: app.kubernetes.io/component\n              operator: NotIn\n              values:\n                - test\n        topologyKey: failure-domain.beta.kubernetes.io/zone\n"` |  |
| topologySpreadConstraints | string | `nil` |  |
| nodeSelector | object | `{}` |  |
| tolerations | list | `[]` |  |
| podLabels | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| livenessProbe | string | `"httpGet:\n  path: /auth/realms/master\n  port: http\n  scheme: HTTP\nfailureThreshold: 15\ntimeoutSeconds: 2\nperiodSeconds: 15\n"` |  |
| readinessProbe | string | `"httpGet:\n  path: /auth/realms/master\n  port: http\n  scheme: HTTP\nfailureThreshold: 15\ntimeoutSeconds: 2\n"` |  |
| startupProbe | string | `"httpGet:\n  path: /auth/realms/master\n  port: http\ninitialDelaySeconds: 90\ntimeoutSeconds: 2\nfailureThreshold: 60\nperiodSeconds: 5\n"` |  |
| resources.requests.cpu | string | `"1"` |  |
| resources.requests.memory | string | `"1Gi"` |  |
| resources.limits.cpu | string | `"1"` |  |
| resources.limits.memory | string | `"1Gi"` |  |
| extraVolumes | string | `""` |  |
| extraVolumeMounts | string | `""` |  |
| extraPorts | list | `[]` |  |
| podDisruptionBudget | object | `{}` |  |
| statefulsetAnnotations | object | `{}` |  |
| statefulsetLabels | object | `{}` |  |
| secrets.env.stringData.JAVA_TOOL_OPTIONS | string | `"-Dcom.redhat.fips=false"` |  |
| secrets.env.stringData.KEYCLOAK_ADMIN | string | `"user"` |  |
| secrets.env.stringData.KEYCLOAK_ADMIN_PASSWORD | string | `""` |  |
| secrets.env.stringData.JAVA_OPTS_APPEND | string | `"-Djgroups.dns.query={{ include \"keycloak.fullname\" . }}-headless"` |  |
| secrets.env.stringData.BOOTSTRAPPER_CLIENT_SECRET | string | ``""`` |  |
| service.annotations | object | `{}` |  |
| service.labels | object | `{}` |  |
| service.type | string | `"ClusterIP"` |  |
| service.loadBalancerIP | string | `""` |  |
| service.httpPort | int | `80` |  |
| service.httpNodePort | string | `nil` |  |
| service.httpsPort | int | `8443` |  |
| service.httpsNodePort | string | `nil` |  |
| service.extraPorts | list | `[]` |  |
| service.loadBalancerSourceRanges | list | `[]` |  |
| service.externalTrafficPolicy | string | `"Cluster"` |  |
| service.sessionAffinity | string | `""` |  |
| service.sessionAffinityConfig | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.ingressClassName | string | `""` |  |
| ingress.servicePort | string | `"http"` |  |
| ingress.annotations | object | `{}` |  |
| ingress.labels | object | `{}` |  |
| ingress.rules[0].host | string | `""` |  |
| ingress.rules[0].paths[0].path | string | `"/"` |  |
| ingress.rules[0].paths[0].pathType | string | `"Prefix"` |  |
| ingress.console.enabled | bool | `false` |  |
| ingress.console.ingressClassName | string | `""` |  |
| ingress.console.annotations | object | `{}` |  |
| ingress.console.rules[0].host | string | `"{{ .Release.Name }}.keycloak.example.com"` |  |
| ingress.console.rules[0].paths[0].path | string | `"/auth/admin/"` |  |
| ingress.console.rules[0].paths[0].pathType | string | `"Prefix"` |  |
| ingress.console.tls | list | `[]` |  |
| networkPolicy.enabled | bool | `false` |  |
| networkPolicy.labels | object | `{}` |  |
| networkPolicy.extraFrom | list | `[]` |  |
| route.enabled | bool | `false` |  |
| route.path | string | `"/"` |  |
| route.annotations | object | `{}` |  |
| route.labels | object | `{}` |  |
| route.host | string | `""` |  |
| route.tls.enabled | bool | `true` |  |
| route.tls.insecureEdgeTerminationPolicy | string | `"Redirect"` |  |
| route.tls.termination | string | `"edge"` |  |
| keycloakSetup.enabled | bool | `true` |  |
| keycloakSetup.backoffLimit |int | `5` |  |
| keycloakSetup.cleanupAfterFinished.enabled | bool | `false` |  |
| keycloakSetup.cleanupAfterFinished.seconds | int | `10` |  |
| keycloakSetup.podLabels | object | `{}` |  |
| keycloakSetup.restartPolicy | string | `Never` |  |
| keycloakSetup.jhub_client_id | string | `"opal-jupyterhub"` |  |
| pgchecker.image.repository | string | `"registry1.dso.mil/ironbank/opensource/postgres/postgresql12"` |  |
| pgchecker.image.tag | float | `12.15` |  |
| pgchecker.image.pullPolicy | string | `"IfNotPresent"` |  |
| pgchecker.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| pgchecker.securityContext.runAsUser | int | `1000` |  |
| pgchecker.securityContext.runAsGroup | int | `1000` |  |
| pgchecker.securityContext.runAsNonRoot | bool | `true` |  |
| pgchecker.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| pgchecker.resources.requests.cpu | string | `"20m"` |  |
| pgchecker.resources.requests.memory | string | `"32Mi"` |  |
| pgchecker.resources.limits.cpu | string | `"20m"` |  |
| pgchecker.resources.limits.memory | string | `"32Mi"` |  |
| postgresql.enabled | bool | `true` |  |
| postgresql.postgresqlUsername | string | `"keycloak"` |  |
| postgresql.postgresqlPassword | string | `"keycloak"` |  |
| postgresql.postgresqlDatabase | string | `"keycloak"` |  |
| postgresql.networkPolicy.enabled | bool | `false` |  |
| postgresql.global.imagePullSecrets[0] | string | `"private-registry"` |  |
| postgresql.image.registry | string | `"registry1.dso.mil"` |  |
| postgresql.image.repository | string | `"ironbank/opensource/postgres/postgresql12"` |  |
| postgresql.image.tag | float | `12.15` |  |
| postgresql.securityContext.enabled | bool | `true` |  |
| postgresql.securityContext.fsGroup | int | `26` |  |
| postgresql.securityContext.runAsUser | int | `26` |  |
| postgresql.securityContext.runAsGroup | int | `26` |  |
| postgresql.containerSecurityContext.enabled | bool | `true` |  |
| postgresql.containerSecurityContext.runAsUser | int | `26` |  |
| postgresql.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| postgresql.resources.requests.cpu | string | `"250m"` |  |
| postgresql.resources.requests.memory | string | `"256Mi"` |  |
| postgresql.resources.limits.cpu | string | `"250m"` |  |
| postgresql.resources.limits.memory | string | `"256Mi"` |  |
| serviceMonitor.enabled | bool | `false` |  |
| serviceMonitor.namespace | string | `""` |  |
| serviceMonitor.namespaceSelector | object | `{}` |  |
| serviceMonitor.annotations | object | `{}` |  |
| serviceMonitor.labels | object | `{}` |  |
| serviceMonitor.interval | string | `"10s"` |  |
| serviceMonitor.scrapeTimeout | string | `"10s"` |  |
| serviceMonitor.path | string | `"/metrics"` |  |
| serviceMonitor.port | string | `"http"` |  |
| serviceMonitor.scheme | string | `""` |  |
| serviceMonitor.tlsConfig | object | `{}` |  |
| extraServiceMonitor.enabled | bool | `false` |  |
| extraServiceMonitor.namespace | string | `""` |  |
| extraServiceMonitor.namespaceSelector | object | `{}` |  |
| extraServiceMonitor.annotations | object | `{}` |  |
| extraServiceMonitor.labels | object | `{}` |  |
| extraServiceMonitor.interval | string | `"10s"` |  |
| extraServiceMonitor.scrapeTimeout | string | `"10s"` |  |
| extraServiceMonitor.path | string | `"/auth/realms/master/metrics"` |  |
| extraServiceMonitor.port | string | `"http"` |  |
| prometheusRule.enabled | bool | `false` |  |
| prometheusRule.annotations | object | `{}` |  |
| prometheusRule.labels | object | `{}` |  |
| prometheusRule.rules | list | `[]` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.labels | object | `{}` |  |
| autoscaling.minReplicas | int | `3` |  |
| autoscaling.maxReplicas | int | `10` |  |
| autoscaling.metrics[0].type | string | `"Resource"` |  |
| autoscaling.metrics[0].resource.name | string | `"cpu"` |  |
| autoscaling.metrics[0].resource.target.type | string | `"Utilization"` |  |
| autoscaling.metrics[0].resource.target.averageUtilization | int | `80` |  |
| autoscaling.behavior.scaleDown.stabilizationWindowSeconds | int | `300` |  |
| autoscaling.behavior.scaleDown.policies[0].type | string | `"Pods"` |  |
| autoscaling.behavior.scaleDown.policies[0].value | int | `1` |  |
| autoscaling.behavior.scaleDown.policies[0].periodSeconds | int | `300` |  |

