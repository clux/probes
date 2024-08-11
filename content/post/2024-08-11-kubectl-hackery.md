+++
date = "2024-08-11"
description = "infrequently used complicated commands for platform engineers"
title = "kubectl hackery"
slug = "2024-08-11-kubectl-hackery"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["kubernetes"]
+++

Unusual helpers for cluster level resource debugging.

<!--more-->

**Disclaimer**: most of these are very infrequently used not may fail for certain edge cases.

Normally, I throw this type of stuff into my [.k8s-helpers dotfile](https://github.com/clux/dotfiles/blob/main/.k8s-helpers),
but what is rarely used tends to bitrot. So instead, am leaving these here as a potential pointer for others. If you know how to read these you should be able to modify them to your need.

## Tools
For convenience here;
- `k` and `kg` are aliases: `alias k=kubectl` + `alias kg=kubectl get`
- `choose` is [choose-rust](https://github.com/theryangeary/choose) (a `cut` / `awk` replacement)
- `yq` is [whyq](https://github.com/clux/whyq) but the python `yq` should also work
- `rg` is [ripgrep](https://github.com/BurntSushi/ripgrep)
- `numfmt` is [coreutils/numfmt](https://man.archlinux.org/man/core/coreutils/numfmt.1.en)
- `awk` is GNU awk.. use with `gawk` if you are on mac with an outdated one
- `xargs` is GNU xargs.. default mac one might fail you

## PVCs

```sh
# get all pvcs in the cluster in descending order of size
kg pvc --no-headers -A | sort -k5 -hr | choose 1 4

# sum all the pvc size across the cluster
kg pvc --no-headers -A | rg -v "Pending" | choose 4 | numfmt --from=iec-i | awk 'BEGIN {sum=0} {sum=sum+$1} END {printf "%.0f\n", sum}' | numfmt --to=iec-i
```

The [Kubernetes mixin dashboard for PVCs](https://github.com/kubernetes-monitoring/kubernetes-mixin/blob/master/dashboards/persistentvolumesusage.libsonnet) is of course useful as well, but it kind of misses orphaned resources, and doesn't let you get a cluster level overview.

## CPU / Memory

Usage (via builtin `kubectl top` which works if you have metrics-server installed):

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

More approachable alternatives here are recommended, in particular the [compute cluster dashboard from kubernetes mixin](https://YOURGRAFANA/d/efa86fd1d0c121a26444b636a3f509a8/), or with the [kubectl-view-allocations](https://github.com/davidB/kubectl-view-allocations) rust cli you can get a nice table:

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
kg prometheusrule -ojson -A | jq '.items[].spec.groups[].rules[] | select(.alert != null) | (.alert + " :: " + .labels["severity"])' -r
```

You can write good rules for consistent labelling using [pint](https://cloudflare.github.io/pint/), but that won't necessary help the stuff you have in the cluster already.

## Custom / Arbitrary Resources
Stuff for orphan management:

```sh
# find crds without instances
kubectl get crds -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | \
    xargs -P16 -I "{}" sh -c '[ "$(kubectl get {} --no-headers -A 2> /dev/null | wc -l)" -eq 0 ] && echo "{}"'
# find ANYTHING in a namespace
kubectl api-resources --verbs=list --namespaced -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found
```

I often just kill/recreate namespaces/crds to be sure things are truly gone in low-reliability environments, but nice to have a way to find out.

## Pods
Phase specific stuff:

```sh
# find pods in bad states
kubectl get pods --field-selector="status.phase!=Succeeded,status.phase!=Running" --no-headers -A
# bounce evicted pods
kubectl get pods | awk '/Evicted/ {print $1}' | xargs kubectl delete pod
```

ideally you have better ways to handle this, but sometimes nice for quick overview in simpler clusters.

## Fluff

Say hello on MASTADONLINK. See issues? Post an [issue](https://github.com/clux/probes/issues) or propose an edit.
