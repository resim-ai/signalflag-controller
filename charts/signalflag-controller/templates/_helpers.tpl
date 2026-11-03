{{/* The name of the controller's Deployment, ServiceAccount and bindings. */}}
{{- define "signalflag-controller.name" -}}
signalflag-controller
{{- end }}

{{- define "signalflag-controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "signalflag-controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "signalflag-controller.labels" -}}
{{ include "signalflag-controller.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end }}

{{/*
signalflag-controller.generated returns the objects in a file under generated/ as a YAML list, with the chart's
labels added. Callers read it with fromYamlArray.
*/}}
{{- define "signalflag-controller.generated" -}}
{{- $root := index . 0 }}
{{- $objects := list }}
{{- range $doc := regexSplit "(?m)^---[ \t]*$" ($root.Files.Get (index . 1)) -1 }}
{{- $obj := fromYaml $doc }}
{{- if hasKey $obj "Error" }}
{{- fail (printf "%s: %s" (index $ 1) $obj.Error) }}
{{- end }}
{{- if $obj.kind }}
{{- $labels := merge (include "signalflag-controller.labels" $root | fromYaml) ($obj.metadata.labels | default dict) }}
{{- $_ := set $obj.metadata "labels" $labels }}
{{- $objects = append $objects $obj }}
{{- end }}
{{- end }}
{{- if not $objects }}
{{- fail (printf "%s holds no objects" (index . 1)) }}
{{- end }}
{{- toYaml $objects }}
{{- end }}
