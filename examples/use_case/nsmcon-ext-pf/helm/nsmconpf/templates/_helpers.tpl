{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "nsmconpf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nsmconpf.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nsmconpf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create interface names for VPP based on PCI device IDs
*/}}
{{- define "intf.left" -}}
{{- $dot := split "." .Values.extport.left -}}
{{- $colon := split ":" $dot._0 -}}
{{- printf "TenGigabitEthernet%s/0/%s" $colon._1 $dot._1 -}}
{{- end -}}

{{- define "intf.right" -}}
{{- $dot := split "." .Values.extport.right -}}
{{- $colon := split ":" $dot._0 -}}
{{- printf "TenGigabitEthernet%s/0/%s" $colon._1 $dot._1 -}}
{{- end -}}
