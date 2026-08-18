{{- define "nginx.name" -}}
nginx
{{- end }}

{{- define "nginx.fullname" -}}
{{ include "nginx.name" . }}
{{- end }}

{{- define "nginx.labels" -}}
app.kubernetes.io/name: {{ include "nginx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "nginx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nginx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
