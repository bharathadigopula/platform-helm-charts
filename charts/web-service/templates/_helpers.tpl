{{/* ========================================================================== */}}
{{/* SHARED NAMES AND FAIL-CLOSED RELEASE INPUTS                                 */}}
{{/* ========================================================================== */}}
{{- define "web.name" -}}
{{- if gt (len .Release.Name) 40 }}{{ fail "Release name must be at most 40 characters" }}{{ end -}}
{{- .Release.Name -}}
{{- end -}}
{{- define "web.guard" -}}
{{- if has .Release.Namespace (list "default" "kube-system" "kube-public" "kube-node-lease") }}{{ fail "A dedicated application namespace is required" }}{{ end -}}
{{- if not (regexMatch "^[a-zA-Z0-9][a-zA-Z0-9./:_-]*@sha256:[a-f0-9]{64}$" .Values.image) }}{{ fail "An immutable image digest is required" }}{{ end -}}
{{- $_ := required "runtimeSecret must name an existing Secret" .Values.runtimeSecret -}}
{{- if .Values.migration.enabled -}}
{{- if not (regexMatch "^[a-zA-Z0-9][a-zA-Z0-9./:_-]*@sha256:[a-f0-9]{64}$" .Values.migration.image) }}{{ fail "An immutable migration image digest is required" }}{{ end -}}
{{- end -}}
{{- if .Values.database.enabled -}}
{{- $_ := required "database.existingSecret is required" .Values.database.existingSecret -}}
{{- if not (regexMatch "^[a-zA-Z0-9][a-zA-Z0-9./:_-]*@sha256:[a-f0-9]{64}$" .Values.database.image) }}{{ fail "An immutable PostgreSQL image digest is required" }}{{ end -}}
{{- end -}}
{{- if .Values.ingress.enabled }}{{ $_ := required "ingress.hostname is required" .Values.ingress.hostname }}{{ end -}}
{{- end -}}