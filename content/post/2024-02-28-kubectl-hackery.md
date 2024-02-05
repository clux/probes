+++
date = "2024-02-28"
description = "wild commands from years as a platform engineer"
title = "kubectl hackery"
slug = "2024-02-28-kubectl-hackery"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["kubernetes"]
+++

wtf

<!--more-->

## Tools
For convenience here;
- `kg` is a shorthand alias: `alias kg=kubectl get`
- `choose` is [choose-rust](https://github.com/theryangeary/choose) (a `cut` / `awk` replacement)
- `awk` (replace with `gawk` if you are on mac)

cost-cutting talk: https://www.youtube.com/watch?v=6vNI_O6sdvY

## PVCs

```sh
# get all pvcs in the cluster in descending order of size
kg pvc --no-headers -A | sort -k5 -hr | choose 1 4

# sum all the pvc size across the cluster
kg pvc --no-headers -A | rg -v "Pending" | choose 4 | numfmt --from=iec-i | awk 'BEGIN {sum=0} {sum=sum+$1} END {printf "%.0f\n", sum}' | numfmt --to=iec-i
```

## CPU / Memory

Usage:
```sh
# total cpu usage in the cluster
k top pods -A --no-headers | choose 2 | gawk 'BEGIN {sum=0} {sum=sum+$1} END {printf "%.0f\n", sum}'
# total memory usage in the cluster
k top pods -A --no-headers | choose 3 | numfmt --from=iec-i | gawk 'BEGIN {sum=0} {sum=sum+$1} END {printf "%.0f\n", sum}' | numfmt --to=iec-i
```

Requests:

```sh
# sum cpu requests across the cluster
k get pods -A -oyaml | yq '.items[].spec.containers[].resources.requests.cpu' -r | awk 'BEGIN {sum=0} {sum=sum+$1} END {printf "%.0f\n", sum}'

# how much is overhead from daemonsets:
 k get ds -A -oyaml | yq '.items[].spec.template.spec.containers[].resources.requests.cpu' -r | grep -v null | awk 'BEGIN {sum=0} {sum=sum+$1} END {printf "%.0f\n", sum}'
```

## PrometheusRules

```sh
# detect duplicates (accidentally deployed to other namespaces)
kg prometheusrule -A --no-headers | sort -k 2 | gawk '{d[$2][a[$2]++]=$0} END{for (i in a) {if (a[i] > 1) for (j in d[i]) {print d[i][j]}}}'

# list all alerts with their severity (or other convention label)
kg prometheusrule -ojson -A | jq '.items[].spec.groups[]' | jq '.rules[] | select(.alert != null) | (.alert + " :: " + .labels["severity"])' -r
```
