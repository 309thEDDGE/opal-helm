{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "minio-operator.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "minio-operator.fullname" -}}
{{- $name := default .Chart.Name -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the Operator Console.
*/}}
{{- define "minio-operator.console-name" -}}
{{- printf "%s-%s" .Chart.Name "console" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified console name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "minio-operator.console-fullname" -}}
{{- printf "%s-%s" .Release.Name "console" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "minio-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels for operator
*/}}
{{- define "minio-operator.labels" -}}
helm.sh/chart: {{ include "minio-operator.chart" . }}
{{ include "minio-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels Operator
*/}}
{{- define "minio-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "minio-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Common labels for console
*/}}
{{- define "minio-operator.console-labels" -}}
helm.sh/chart: {{ include "minio-operator.chart" . }}
{{ include "minio-operator.console-selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels Operator
*/}}
{{- define "minio-operator.console-selectorLabels" -}}
app.kubernetes.io/name: {{ include "minio-operator.name" . }}
app.kubernetes.io/instance: {{ printf "%s-%s" .Release.Name "console" }}
{{- end -}}

{{/* Big Bang Added Helpers Start Here */}}

{{/*
Create the name of the service used to access the Minio object UI.
Note: the Minio operator has a fixed name of "minio" for the service it creates.
*/}}
{{- define "minio-operator.serviceName" }}
{{- if .Values.upgradeTenants.enabled -}}
minio
{{- else -}}
{{- default (include "minio.fullname" .) .Values.service.nameOverride }}
{{- end }}
{{- end }}

{{/*
Create the port used to communicate with the Minio service.
Note: the Minio operator has a fixed name of "minio" for the service it creates.
*/}}
{{- define "minio-operator.servicePort" -}}
{{- if or .Values.tenant.certificate.requestAutoCert .Values.tenant.certificate.externalCertSecret }}
443
{{- else }}
9090
{{- end }}
{{- end }}

{{/*
Create the port used to communicate with the Minio API service.
Note: the Minio operator has a fixed name of "minio" for the service it creates.
*/}}
{{- define "api.servicePort" -}}
80
{{- end }}

{{- define "render-url" -}}
{{- tpl .value .context }}
{{- end }}

{{- define "domains.base" -}}
{{- $base := .Values.baseDns -}}
{{- if not (hasPrefix "." $base) -}}
{{- $base = print "." $base -}}
{{- end -}}
{{- if .Values.domainExtension -}}
{{- $base = print "-" .Values.domainExtension $base -}}
{{- end -}}
{{- print $base -}}
{{- end -}}

{{- define "domains.minio" -}}
{{- printf "%s%s" "https://minio" (include "domains.base" .) -}}
{{- end -}}

{{- define "domains.keycloak" -}}
{{- printf "%s%s" "https://keycloak" (include "domains.base" .) -}}
{{- end -}}

{{- define "domains.jhub" -}}
{{- printf "%s%s" "https://opal" (include "domains.base" .) -}}
{{- end -}}

{{- define "ingresses.minio" -}}
{{- printf "%s%s" "minio" (include "domains.base" .) -}}
{{- end -}}
