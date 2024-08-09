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
# by name:
k get pods -A -oyaml | yq '.items[] | .metadata.name + " " + .spec.containers[].resources.requests.cpu' -r
# top 20 by name
k get pods -A -oyaml | yq '.items[] | .metadata.name + " " + .spec.containers[].resources.requests.cpu' -r | numfmt --field=2 --from=iec --suffix=000m --to=si --invalid=ignore | sort -hk2 --reverse | head -n 20

# how much is overhead from daemonsets:
 k get ds -A -oyaml | yq '.items[].spec.template.spec.containers[].resources.requests.cpu' -r | grep -v null | awk 'BEGIN {sum=0} {sum=sum+$1} END {printf "%.0f\n", sum}'
```

More approachable alternatives here are recommended, in particular the [compute cluster dashboard from kubernetes mixin](https://YOURGRAFANA/d/efa86fd1d0c121a26444b636a3f509a8/), or with the rust cli [kubectl-view-allocations](https://github.com/davidB/kubectl-view-allocations):

```sh
$ kubectl-view-allocations -g resource -u
 Resource              Utilization     Requested          Limit  Allocatable  Free
  cpu                   (10%) 28.2   (93%) 272.3    (535%) 1.6k        293.6   0.0
  ephemeral-storage             __    (24%) 1.1T  (24%) 975.9Gi         4.4T  3.3T
  memory             (29%) 208.2Gi  (81%) 622.7G    (288%) 2.2T       765.6G   0.0
  pods                          __    (45%) 1.0k     (45%) 1.0k         2.2k  1.2k
```

## PrometheusRules

```sh
# detect duplicates (accidentally deployed to other namespaces)
kg prometheusrule -A --no-headers | sort -k 2 | gawk '{d[$2][a[$2]++]=$0} END{for (i in a) {if (a[i] > 1) for (j in d[i]) {print d[i][j]}}}'

# list all alerts with their severity (or other convention label)
kg prometheusrule -ojson -A | jq '.items[].spec.groups[]' | jq '.rules[] | select(.alert != null) | (.alert + " :: " + .labels["severity"])' -r
```
