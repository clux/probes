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

I would like to argue that these difficulties are largely self-imposed, and a combination result of inadequate [cardinality control](https://prometheus.io/docs/practices/instrumentation/#do-not-overuse-labels) and [induced demand](https://en.wikipedia.org/wiki/Induced_demand).

> 👺: You should be able to run a prometheus on your handful-of-machine-sized homelab with <10k time series active, using less than 512Mi memory, and 10m CPU.

## Signals, Symptoms & Causes

To illustrate this, let's try to answer the (perhaps obvious question): **why do you install a metrics system at all?**

Primarily; we want to be able to track and get notified on changes to key **signals**. At the very basic level you want to tell if your "service is down", because you want to be able to use it. That's the main, user-facing signal. Setup something that test if the service responds with a `2XX`, and alert on deviations. You [don't even need](https://www.checklyhq.com/product/api-monitoring/) prometheus for this.

However, while you can do basic sanity outside the cluster, you don't have a view of [utilisation and saturation](https://www.brendangregg.com/usemethod.html), so you cannot predict upcoming failures such as:

- **message queues full** :: rejected work
- **high cpu utilisation** :: degraded latency
- **memory utilisation high** :: oom kill imminent
- **disk space nearing full** :: failures imminent

You can argue __idealistically__ about whether you should only be "aware of something going wrong", or be "aware that something is in a risky state" (e.g. [symptoms not causes](https://cloud.google.com/blog/topics/developers-practitioners/why-focus-symptoms-not-causes)), but you can't avoid utilisation/saturation as a predictor for degraded performance (in the same sense as; you don't wait for a certificate to expire before renewing it).

## How Many Signals

> MAIN POINT: You should be able to enumerate the signals that you want to consider (be able to visualise and be used in alerts).

Let's do some simplified **enumeration maths** on **how many signals** you actually want to properly identify failures quickly.

### Compute Utilisation/Saturation
Consider the example of a cluster with 200 pods, and 5 nodes.

- Want {utilization,saturation} of cpu/memory :: 2 * 2 = **4 signals**
- Want to see them PER `Pod` :: 200 * 4 = **800 signals**
- Want to see them per `Node` :: 5 * 4 = **20 signals**

So, in theory, we should be able to visualise cluster, node, and pod level utilisation for cpu and memory with only 820 metrics (but likely more if you want to break down node metrics).

> NB: Pods are only found on one node, so `Pod` cardinality does not multiply with `Node` cardinality.

These will come from a combination of [cadvisor](https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md) and [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics), and they are huge - depending on how much of the [kubernetes mixin](https://monitoring.mixins.dev/kubernetes/) you consider to be important.

### Node State Breakdown

If you want to break down things within a node on a more physical level, then you you can also grab [node-exporter](https://github.com/prometheus/node_exporter).

Assuming, for simplicity, 10 cores per node, 10 disk devices per node, and 10 network interfaces:

- Want {utilization,saturation,errors} of cpu :: 3*10 * 5 = **60 signals**
- Want {utilization,saturation,errors} for memory :: 3*5 = **15 signals**
- Want {utilisation,saturation,errors} of disks :: 3*10 * 5 = **100 signals**
- Want {utilisation,saturation,errors} of network interfaces :: 10*3 * 5 = **150 signals**

In theory, you should be able to get decent node monitoring with less than 400 metrics.

### Limitations

The problems with expecting this type of perfection in practice is that many metric producers are very inefficient / overly lenient with their output. You can see below for some examples, but without extreme tuning you can generally expect a **5x inefficiency factor** to apply to the above in practice.

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

**REDUCE FREQUENCY**

You probably don't need 15s data fidelity / sensitivity in your homelab, so a 1m interval should be fine:

```yaml
scrapeInterval: 60s
evaluationInterval: 60s
```

(any longer and grafana starts to look less clean).

**DROP YOUR HISTOGRAMS**

Histograms easily account for 90% of your metric utilisation, so unless you have a need to see detailed breakdown of latency distributions, do not ingest these metrics. It's the easiest win you'll get in prometheus land.

Doing this is very simple, wildcard drop them from your `ServiceMonitor` (et al) objects:

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
  * See the [Containing Your Cardinality](https://promcon.io/2019-munich/slides/containing-your-cardinality.pdf) talk for more maths details

2. **Inefficiency** 30x multiplied information is a bad way to store a few additional signals

If you want P50s or P99s you can compute these in the app with things like [rolling averages](https://en.wikipedia.org/wiki/Moving_average) or rolling quantiles. Some of these are more annoying than others, but there's a lot you can do by just tracking a mean.

> If you want to answer one question, it can in theory be provided by one signal.

If you absolutely must use them, decouple them from your other labels, export them once (not for all your pods in a big deployment) so that you can get the answer you need cheaply.

> 👺: This will get better with the [native-histograms feature](https://prometheus.io/docs/prometheus/latest/feature_flags/#native-histograms) (see e.g. [this talk](https://www.youtube.com/watch?v=TgINvIK9SYc)). However, this requires the ecosystem to move on to protobufs and it being propagated into client libraries (and is at the moment still experimental at the [time of writing](https://github.com/prometheus/prometheus/releases/tag/v2.54.1)) despite it being documented [2 years ago](https://github.com/prometheus/prometheus/commit/41035469d32fe8fd436c55846a5b237a86e69dee).

</details>

## Basic Prometheus Setup
Basic prometheus architecture:

[![prometheus architecture diagram](/imgs/prometheus/prometheus-simple.webp)](/imgs/prometheus/prometheus-simple.webp)

This is basically my [2022 company setup](/post/2022-01-11-prometheus-ecosystem/), but with thanos ripped out.

## Chart

This type of setup I need all the time, so I have a chart for myself now.

It's just a wrapper chart over [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) and provides the following default [values.yaml](https://github.com/clux/homelab/blob/main/charts/promstack/values.yaml).
You can use it direct with:

```sh
helm repo add clux https://clux.github.io/homelab
helm install [RELEASE_NAME] clux/promstack
```

but I recommend you just take the [values.yaml](https://github.com/clux/homelab/blob/main/charts/promstack/values.yaml) file and run with it in your own similar subchart.

> 👺: You shouldn't trust me for maintenance of this, and you don't want to be any more steps abstracted away from kube-prometheus-stack.

By default the chart does not come with `prometheus-adapter`, but it comes with a light `tempo`.

## Features

## Cardinality Control
Drops **97% of kubelet metrics**, configures minimal `kube-state-metrics`, `node-exporter` (with some cli arg configurations and some relabelling based drops) and a few other apps. In the end we have a cluster running with **7000 metrics**.

[![cardinality control panel](/imgs/prometheus/cardinality-control.png)](/imgs/prometheus/cardinality-control.png)

It's higher than my idealistic estimate, but the [5x inefficiency factor](#limitations) is real. It can be tuned lower with extra effort, but at this point I am happy. This is low enough that [grafana cloud considers it free](https://grafana.com/pricing/), but is it?

### Low Utilization

The end result is a prometheus using <0.01 cores:

[![cpu utilisation panel](/imgs/prometheus/minimal-prom-cpu.png)](/imgs/prometheus/minimal-prom-cpu.png)

with 512Mi memory use:

[![memory utilisation panel](/imgs/prometheus/minimal-prom-mem.png)](/imgs/prometheus/minimal-prom-mem.png)

and this is with **`30d` retention**, mean values over 2 days.

### Extras: Metrics Adapter

If you plan on running this on your own on prem setup, you could also rip out the adapter. For homelab type setups, [keda](https://keda.sh/) is more attractive due to its ability to [scale to zero](https://keda.sh/docs/2.15/reference/scaledobject-spec/#minreplicacount).

### Extras: Dashboards

Some of the screenshots here are from my own homebrew panels. See the future post for these.
