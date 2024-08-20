{{- /*
    These helpers encapsulates logic on how we name resources. They also enable
    parent charts to reference these dynamic resource names.

    To avoid duplicating documentation, for more information, please see the the
    fullnameOverride entry in values.schema.yaml or the configuration reference
    that values.schema.yaml renders to.

    https://z2jh.jupyter.org/en/latest/resources/reference.html#fullnameOverride
*/}}



{{- /*
    Utility templates
*/}}

{{- /*
    Renders to a prefix for the chart's resource names. This prefix is assumed to
    make the resource name cluster unique.
*/}}
{{- define "jupyterhub.fullname" -}}
    {{- /*
        We have implemented a trick to allow a parent chart depending on this
        chart to call these named templates.

        Caveats and notes:

            1. While parent charts can reference these, grandparent charts can't.
            2. Parent charts must not use an alias for this chart.
            3. There is no failsafe workaround to above due to
               https://github.com/helm/helm/issues/9214.
            4. .Chart is of its own type (*chart.Metadata) and needs to be casted
               using "toYaml | fromYaml" in order to be able to use normal helm
               template functions on it.
    */}}
    {{- $fullname_override := .Values.fullnameOverride }}
    {{- $name_override := .Values.nameOverride }}
    {{- if ne .Chart.Name "jupyterhub" }}
        {{- if .Values.jupyterhub }}
            {{- $fullname_override = .Values.jupyterhub.fullnameOverride }}
            {{- $name_override = .Values.jupyterhub.nameOverride }}
        {{- end }}
    {{- end }}

    {{- if eq (typeOf $fullname_override) "string" }}
        {{- $fullname_override }}
    {{- else }}
        {{- $name := $name_override | default .Chart.Name }}
        {{- if contains $name .Release.Name }}
            {{- .Release.Name }}
        {{- else }}
            {{- .Release.Name }}-{{ $name }}
        {{- end }}
    {{- end }}
{{- end }}

{{- /*
    Renders to a blank string or if the fullname template is truthy renders to it
    with an appended dash.
*/}}

{{- /*
    Namespaced resources
*/}}

{{- /* hub Deployment */}}
{{- define "jupyterhub.hub.fullname" -}}
    {{- include "jupyterhub.fullname" . }}-hub
{{- end }}

{{- /* hub-serviceaccount ServiceAccount */}}
{{- define "jupyterhub.hub-serviceaccount.fullname" -}}
    {{- if .Values.serviceAccount.create }}
        {{- .Values.serviceAccount.name | default (include "jupyterhub.hub.fullname" .) }}
    {{- else }}
        {{- .Values.serviceAccount.name | default "default" }}
    {{- end }}
{{- end }}

{{- /* proxy Deployment */}}
{{- define "jupyterhub.proxy.fullname" -}}
    {{- include "jupyterhub.fullname" . }}-proxy
{{- end }}

{{- /* proxy-api Service */}}
{{- define "jupyterhub.proxy-api.fullname" -}}
    {{- include "jupyterhub.proxy.fullname" . }}-api
{{- end }}

{{- /* proxy-http Service */}}
{{- define "jupyterhub.proxy-http.fullname" -}}
    {{- include "jupyterhub.proxy.fullname" . }}-http
{{- end }}

{{- /* proxy-public Service */}}
{{- define "jupyterhub.proxy-public.fullname" -}}
    {{- include "jupyterhub.proxy.fullname" . }}-public
{{- end }}

{{- /* image-awaiter Job */}}
{{- define "jupyterhub.hook-image-awaiter.fullname" -}}
    {{- include "jupyterhub.fullname" . }}-hook-image-awaiter
{{- end }}

{{- /* image-awaiter-serviceaccount ServiceAccount */}}
{{- define "jupyterhub.hook-image-awaiter-serviceaccount.fullname" -}}
    {{- if .Values.prePuller.hook.serviceAccount.create }}
        {{- .Values.prePuller.hook.serviceAccount.name | default (include "jupyterhub.hook-image-awaiter.fullname" .) }}
    {{- else }}
        {{- .Values.prePuller.hook.serviceAccount.name | default "default" }}
    {{- end }}
{{- end }}

{{- /* hook-image-puller DaemonSet */}}
{{- define "jupyterhub.hook-image-puller.fullname" -}}
    {{- include "jupyterhub.fullname" . }}-hook-image-puller
{{- end }}

{{- /* continuous-image-puller DaemonSet */}}
{{- define "jupyterhub.continuous-image-puller.fullname" -}}
    {{- include "jupyterhub.fullname" . }}-continuous-image-puller
{{- end }}

{{- /* singleuser NetworkPolicy */}}
{{- define "jupyterhub.singleuser.fullname" -}}
    {{- include "jupyterhub.fullname" . }}-singleuser
{{- end }}

{{- /* image-pull-secret Secret */}}
{{- define "jupyterhub.image-pull-secret.fullname" -}}
    {{- include "jupyterhub.fullname" . }}-image-pull-secret
{{- end }}

{{- /* Ingress */}}
{{- define "jupyterhub.ingress.fullname" -}}
    {{- if (include "jupyterhub.fullname" .) }}
        {{- include "jupyterhub.fullname" . }}
    {{- else -}}
        jupyterhub
    {{- end }}
{{- end }}



{{- /*
    Cluster wide resources

    We enforce uniqueness of names for our cluster wide resources. We assume that
    the prefix from setting fullnameOverride to null or a string will be cluster
    unique.
*/}}

{{- /* Priority */}}
{{- define "jupyterhub.priority.fullname" -}}
    {{- if (include "jupyterhub.fullname" .) }}
        {{- include "jupyterhub.fullname" . }}
    {{- else }}
        {{- .Release.Name }}-default-priority
    {{- end }}
{{- end }}

{{- /* image-puller Priority */}}
{{- define "jupyterhub.image-puller-priority.fullname" -}}
    {{- if (include "jupyterhub.fullname" .) }}
        {{- include "jupyterhub.fullname" . }}-image-puller
    {{- else }}
        {{- .Release.Name }}-image-puller-priority
    {{- end }}
{{- end }}

{{- /*
    A template to render all the named templates in this file for use in the
    hub's ConfigMap.

    It is important we keep this in sync with the available templates.
*/}}
{{- define "jupyterhub.name-templates" -}}
fullname: {{ include "jupyterhub.fullname" . | quote }}
hub: {{ include "jupyterhub.hub.fullname" . | quote }}
hub-serviceaccount: {{ include "jupyterhub.hub-serviceaccount.fullname" . | quote }}
proxy: {{ include "jupyterhub.proxy.fullname" . | quote }}
proxy-api: {{ include "jupyterhub.proxy-api.fullname" . | quote }}
proxy-public: {{ include "jupyterhub.proxy-public.fullname" . | quote }}
{{- /*
image-puller-priority: {{ include "jupyterhub.image-puller-priority.fullname" . | quote }}
hook-image-awaiter: {{ include "jupyterhub.hook-image-awaiter.fullname" . | quote }}
hook-image-awaiter-serviceaccount: {{ include "jupyterhub.hook-image-awaiter-serviceaccount.fullname" . | quote }}
hook-image-puller: {{ include "jupyterhub.hook-image-puller.fullname" . | quote }}
continuous-image-puller: {{ include "jupyterhub.continuous-image-puller.fullname" . | quote }}
*/}}
singleuser: {{ include "jupyterhub.singleuser.fullname" . | quote }}
ingress: {{ include "jupyterhub.ingress.fullname" . | quote }}
priority: {{ include "jupyterhub.priority.fullname" . | quote }}
{{- end }}
