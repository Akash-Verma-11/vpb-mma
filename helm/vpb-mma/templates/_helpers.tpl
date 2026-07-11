{{- define "vpb-mma.labels" -}}
app.kubernetes.io/part-of: vpb-mma
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
