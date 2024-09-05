+++
date = "2024-10-01"
description = "how to run an efficient prometheus for small clusters"
title = "Prometheus Minified"
slug = "2024-10-01-prometheus-minified"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["kubernetes", "observability", "prometheus"]
+++

Prometheus does not need to be hugely complicated, nor a massive resource hog, provided you follow some principles.

## Background
My last [#prometheus](/tags/prometheus/) posts have been exclusively about large scale production setups, and the difficulties this pulls in.

I would like to argue that these difficulties are largely self-imposed, and a combination result of missing [cardinality control](https://promcon.io/2019-munich/slides/containing-your-cardinality.pdf) and [induced demand](https://en.wikipedia.org/wiki/Induced_demand).

> clux: "You should be able to run a prometheus on your handful-of-machine-sized homelab with <10k time series active, using less than 1G memory, and 1m CPU."

## Signals, Symptoms & Causes

To illustrate this, let's try to answer the (perhaps obvious question): **why do you install a metrics system at all?**

Primarily; we want to be able to track and get notified on changes to key **signals**. At the very basic level you want to tell if your "service is down", because you want to be able to use it. That's the main, user-facing signal. Setup something that test if the service responds with a `2XX`, and alert on deviations. You [don't even need](https://www.checklyhq.com/product/api-monitoring/) prometheus for this.

However, while you can do basic sanity outside the cluster, you don't have a view of [utilisation and saturation](https://www.brendangregg.com/usemethod.html), so you cannot predict upcoming failures such as:

- **message queues full** :: rejected work
- **high cpu utilisation** :: degraded latency
- **memory utilisation high** :: oom kill imminent
- **disk space nearing full** :: failures imminent

You can argue a little more idealistically about whether you should only be "aware of something going wrong", or be "aware that something is in a risky state" (e.g. [symptoms not causes](https://cloud.google.com/blog/topics/developers-practitioners/why-focus-symptoms-not-causes)), but you can't avoid utilisation/saturation as a predictor for degraded performance (in the same sense as; you don't wait for a certificate to expire before renewing it).

## How Many Signals

> MAIN POINT: You should be able to enumerate the signals that you want to consider (be able to visualise and be used in alerts).

Let's do some simplified enumeration maths on how many signals you actually want to properly identify failures quickly.

### Compute Utilisation/Saturation
Consider the example of a cluster with 200 pods, and 5 nodes.

- Want {utilization,saturation} of cpu/memory :: 2 * 2 = 4
- Want to see them PER `Pod` :: 200 * 4 = 800
- Want to see them per `Node` :: 5 * 4 = 20

So, in theory, we should be able to visualise cluster, node, and pod level utilisation for cpu and memory with only 820 metrics (but likely more if you want to break down node metrics).

> NB: Pods are only found on one node, so `Pod` cardinality does not multiply with `Node` cardinality.

These will come from a combination of [cadvisor](https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md) and [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics), and they are huge - depending on how much of the [kubernetes mixin](https://monitoring.mixins.dev/kubernetes/) you consider to be important.

### Node State Breakdown

If you want to break down things within a node on a more physical level, then you you can also grab [node-exporter](https://github.com/prometheus/node_exporter).

Assuming, for simplicity, 10 cores per node, 10 disk devices per node, and 10 network interfaces:

- Want {utilization,saturation,errors} of cpu :: 3*10 * 5 = 60
- Want {utilization,saturation,errors} for memory :: 3*5 = 15
- Want {utilisation,saturation,errors} of disks :: 3*10 * 5 = 100
- Want {utilisation,saturation,errors} of network interfaces :: 10*3 * 5 = 150

In theory you should be able to get decent node monitoring with less than 400 metrics.

### Limitations

The problems with expecting this type of perfection in practice is that many metric producers are so inefficient / lenient with their output that you can expect a **5x inefficiency factor** to apply to the above in practice.


<details><summary style="cursor:pointer;color:#0af"><b>Addendum: Inefficiency Examples</b></summary>

Minor: `job="kube-state-metrics"` denormalising __disjoint phases__ (never letting old/zero phases go out of scope):

```promql
kube_pod_status_phase{phase="Pending", pod="forgejo-975b98575-fbjz8"} 0
kube_pod_status_phase{phase="Succeeded", pod="forgejo-975b98575-fbjz8"} 0
kube_pod_status_phase{phase="Failed", pod="forgejo-975b98575-fbjz8"} 0
kube_pod_status_phase{phase="Unknown", pod="forgejo-975b98575-fbjz8"} 0
kube_pod_status_phase{phase="Running", pod="forgejo-975b98575-fbjz8"} 1
```

This [may get a fix](https://github.com/kubernetes/kube-state-metrics/issues/2380).

Annoying: `job="node-exporter"` putting tons of labels on metrics such as `node_cpu_seconds_total`:

```promql
{cpu="15", mode="idle"} 1
{cpu="15", mode="iowait"} 1
{cpu="15", mode="irq"} 1
{cpu="15", mode="nice"} 1
{cpu="15", mode="softirq"} 1
{cpu="15", mode="steal"} 1
{cpu="15", mode="system"} 1
{cpu="15", mode="user"}
```

and you can't really do much about this even if you don't care to break down by mode because the [standard recording rules depend on mode](https://github.com/prometheus/node_exporter/blob/b9d0932179a0c5b3a8863f3d6cdafe8584cedc8e/docs/node-mixin/rules/rules.libsonnet#L9-L14) (but you could maybe avoid the per `cpu` breakdown).

Similarly, if you want to support a bunch of the mixin dashboards with container level breakdown, you are also forced to grab a bunch of container level info for e.g. [k8s.rules.container_resource](https://github.com/prometheus-community/helm-charts/blob/71845c4d5795ec552e3ea96036c39dcfb97132ad/charts/kube-prometheus-stack/templates/prometheus/rules-1.14/k8s.rules.container_resource.yaml#L43) unless if you want to rewrite the world.

</details>

### Biggest Lessons

Ultimately this is a numbers game, and you can sweat over details like the above but the biggest improvement comes from the following tiny-brain advice:

**DROP YOUR HISTOGRAMS**

Histograms easily account for 90% of your metric utilisation, so unless you have a need to see detailed breakdown of tail latencies, do not scrape these metrics. It's the easiest win you'll get in prometheus land.

Doing this is very simple, wildcard drop them from your servicemonitors:

```yaml
      metricRelabelings:
      - sourceLabels: [__name__]
        action: drop
        regex: '^.*bucket.*'
```

<details><summary style="cursor:pointer;color:#0af"><b>Addendum: Why does histograms suck?</b></summary>

1. **Multiplicative Cardinality**: histogram buckets multiply metric cardinality by 5-30x (the number of buckets).

This number is multiplicative with regular cardinality:
  * `pod` / `node` labels added by prometheus operator :: if 2000 metric per pod, and scaling to 20 pods, now you have 40000 metrics
  * request information added by users (endpoint, route, status, error) :: 5 eps * 10 routes * 8 statuses * 4 errors = 1600 metrics, but with 30 buckets = 48000

2. **Inefficiency** 30x multiplied information is a bad way to store a few additional signals

If you want P50s or P99s you can compute these in the app with things like [rolling averages](https://en.wikipedia.org/wiki/Moving_average) or rolling quantiles. Some of these are more annoying than others, but there's a lot you can do by just tracking a mean.

> If you want to answer one question, it can in theory be provided by one signal.

If you absolutely must use them, decouple them from your other labels, export them once (not for all your pods in a big deployment) so that you can get the answer you need cheaply.

TODO: link to native histograms
TODO: link to the talk everyone references

</details>

## Basic Prometheus Setup
How to deploy a base prometheus:


[![prometheus architecture diagram](/imgs/prometheus/prometheus-simple.webp)](/imgs/prometheus/prometheus-simple.webp)

This is basically my [2022 company setup](/post/2022-01-11-prometheus-ecosystem/), but with thanos ripped out. If you plan on running this on your own on prem setup, you could also rip out the adapter.

## Cardinality Control

- kubelet drops
- apiserver drops
- bucket drops
- go drops

grafana free tier is 10k, but default server is 5x that, and 11x if we didn't drop anything.

## TODO

- chart with setup
- factor out URL from charts?
- own repo for prom repo?
