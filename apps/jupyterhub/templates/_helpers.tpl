{{/*
Expand the name of the chart.
*/}}
{{- define "jupyterhub.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "jupyterhub.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "jupyterhub.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "jupyterhub.labels" -}}
helm.sh/chart: {{ include "jupyterhub.chart" . }}
{{ include "jupyterhub.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "jupyterhub.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jupyterhub.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
    Returns given number of random Hex characters.
    - randNumeric 4 | atoi generates a random number in [0, 10^4)
      This is a range range evenly divisble by 16, but even if off by one,
      that last partial interval offsetting randomness is only 1 part in 625.
    - mod N 16 maps to the range 0-15
    - printf "%x" represents a single number 0-15 as a single hex character
*/}}
{{- define "jupyterhub.randHex" -}}
    {{- $result := "" }}
    {{- range $i := until . }}
        {{- $rand_hex_char := mod (randNumeric 4 | atoi) 16 | printf "%x" }}
        {{- $result = print $result $rand_hex_char }}
    {{- end }}
    {{- $result }}
{{- end }}

{{- define "get.tokenName" }}
{{- $secretName := ""}}
{{- if .Values.secrets.nameOverride }}
{{- $secretName = .Values.secrets.nameOverride }}
{{- else }}
{{- $secretName = printf "%s-token-env" (include "jupyterhub.fullname" .) }}
{{- end }}
{{- $secretName }}
{{- end}}

{{- define "get.oauthName" }}
{{- $secretName := ""}}
{{- $secretName = printf "%s-oauth" (include "jupyterhub.fullname" .) }}
{{- $secretName }}
{{- end}}

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

{{- define "ingresses.jhub" -}}
{{- printf "%s%s" "opal" (include "domains.base" .) -}}
{{- end -}}
