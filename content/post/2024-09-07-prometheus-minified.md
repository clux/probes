+++
date = "2024-09-07"
description = "how to setup an efficient prometheus for small clusters"
title = "Running a Minimal Prometheus"
slug = "2024-09-07-prometheus-minified"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["kubernetes", "observability", "prometheus", "homelab"]
+++

Prometheus does not need to be hugely complicated, nor a massive resource hog, provided you follow some principles.

## Background
My last [#prometheus](/tags/prometheus/) posts have been exclusively about large scale production setups, and the difficulties this pulls in.

I would like to argue that these difficulties are largely self-imposed, and a combination result of inadequate [cardinality control](https://prometheus.io/docs/practices/instrumentation/#do-not-overuse-labels) and [induced demand](https://en.wikipedia.org/wiki/Induced_demand).

> 👺: You should be able to run a prometheus on your handful-of-machine-sized homelab with <10k time series active, using less than 512Mi memory, and 10m CPU.

<details><summary style="cursor:pointer;color:#0af"><b>Disclaimer: Who am I?</b></summary>

[I](https://github.com/clux) am a platform engineer working maintenance of observability infrastructure, and a maintainer of [kube-rs](https://kube.rs) working on rust integration of observability with Kubernetes platforms. My knowledge of prometheus is superficial and mostly based on practical observations around operating it for years. Suggestions or corrections are welcome (links at bottom).

</details>

## Signals, Symptoms & Causes

To illustrate this, let's try to answer the (perhaps obvious question): **why do you install a metrics system at all?**

Primarily; we want to be able to track and get notified on changes to key **signals**. At the very basic level you want to tell if your "service is down", because you want to be able to use it. That's the main, user-facing signal. Setup something that test if the service responds with a `2XX`, and alert on deviations. You [don't even need](https://www.checklyhq.com/product/api-monitoring/) prometheus for this.

However, while you can do basic sanity outside the cluster, you need [utilisation and saturation](https://www.brendangregg.com/usemethod.html), to tell you about less obvious / upcoming failures:

- **message queues full** :: rejected work
- **high cpu utilisation** :: degraded latency
- **memory utilisation high** :: oom kill imminent
- **disk space nearing full** :: failures imminent

You can argue __idealistically__ about whether you should only be "aware of something going wrong", or be "aware that something is in a risky state" (e.g. [symptoms not causes](https://cloud.google.com/blog/topics/developers-practitioners/why-focus-symptoms-not-causes)), but it's silly to avoid utilisation/saturation as a predictor for degraded performance (in the same sense as; you don't wait for a certificate to expire before renewing it).

## How Many Signals

> MAIN POINT: You should be able to enumerate the **basic** signals that you want to have visibility of.

Let's do some simplified **enumeration maths** on **how many signals** you actually want to properly identify failures quickly.

### Compute Utilisation/Saturation
Consider an **example cluster with 200 pods, and 5 nodes**.

- Want {utilization,saturation} of {cpu,memory} at cluster level :: 2 * 2 = **4 signals**
- Want to break these down per `Pod` :: 200 * 4 = **800 signals**
- Want to break these down per `Node` :: 5 * 4 = **20 signals**

So, in theory, we should be able to visualise cluster, node, and pod level utilisation for cpu and memory with only 820 metrics (but likely more if you want to break down node metrics).

> NB: Pods are only found on one node, so `Pod` cardinality does not multiply with `Node` cardinality.

These will come from a combination of [cadvisor](https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md) and [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics); huge beasts with lots of functionality and way more signals than we need. Depending on how much of the [kubernetes mixin](https://monitoring.mixins.dev/kubernetes/) you want, you may want more signals.

### Node State Breakdown

If you want to break down things **within a node** on a more physical level, then you you can also grab [node-exporter](https://github.com/prometheus/node_exporter).

Assuming, for simplicity, 10 cores per node, 10 disk devices per node, and 10 network interfaces:

- Want {utilization,saturation,errors} of cpu :: 3*10 * 5 = **60 signals**
- Want {utilization,saturation,errors} for memory :: 3*5 = **15 signals**
- Want {utilisation,saturation,errors} of disks :: 3*10 * 5 = **100 signals**
- Want {utilisation,saturation,errors} of network interfaces :: 10*3 * 5 = **150 signals**

In theory, you should be able to get decent node monitoring with less than 400 metrics.

## In Practice

Doing this type of enumeration is helpful as a way to tell how close you are to your theoretical 100% optimised system, but how does the number hold up in practice?

### Metric Inefficiencies

The problems with expecting this type of perfection in practice is that many metric producers are very inefficient / overly lenient with their output. You can click on the addendum below for some examples, but without extreme tuning you can generally expect a **5x inefficiency factor** to apply to the above in practice.

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

and while you can `action: labeldrop` the `cpu` breakdown, you can't do the same for `mode` because the [standard recording rules depend on mode](https://github.com/prometheus/node_exporter/blob/b9d0932179a0c5b3a8863f3d6cdafe8584cedc8e/docs/node-mixin/rules/rules.libsonnet#L9-L14).

Similarly, if you want to support a bunch of the mixin dashboards with container level breakdown, you are also forced to grab a bunch of container level info for e.g. [k8s.rules.container_resource](https://github.com/prometheus-community/helm-charts/blob/71845c4d5795ec552e3ea96036c39dcfb97132ad/charts/kube-prometheus-stack/templates/prometheus/rules-1.14/k8s.rules.container_resource.yaml#L43) unless if you want to rewrite the world.

</details>

### Visualising Cardinality

I have a [dashboard](https://github.com/clux/homelab/blob/main/dashboards/prometheus.json) for this with this panel:

[![cardinality control panel](/imgs/prometheus/cardinality-control.png)](/imgs/prometheus/cardinality-control.png)

Shows metrics produced, how many we decided to keep, and a breakdown link leading to `topk(50, count({job="JOB-IN-ROW"}) by (__name__))`. It's probably the panel that has helped the most in slimming down prometheus.

### Outing Out

The most unfortunate reality is that this stuff is all opt-out. The [defaults are crazy inclusive](https://github.com/prometheus-community/helm-charts/blob/ecc58b9baecc43b0d5719ed509a89e7ca5a7e8e3/charts/kube-prometheus-stack/values.yaml#L47-L83), and new versions of exporters introduce new metrics forcing you to watch your usage graph upgrades.

Thankfully, in a [gitops repo](https://github.com/clux/homelab) this is easy to do (if you [actually generate your helm templates](https://hachyderm.io/@clux/113044641297413034) into a `deploy` folder) because all your dashboards and recording rules live there.

**Procedure**: Unsure if you need this `container_sockets` metric? `rg container_sockets deploy/` and see if anything comes up:

1. No hits? `action: drop`.
2. Only used in a dashboard? Do you care about this dashboard? No? `action: drop`.
3. Used in a recording rule? Does the recording rule go towards an alert/dashboard you care about? No? `action: drop`.
4. Partially used in dashboard or recording rule? `labeldrop` subset.

Grafana cloud has its own opt-out ML based [adaptive metrics thing](https://www.youtube.com/watch?v=ZkXJIQYbUVs) to do this, and while this is probably helpful if you are locked into their cloud, the solution definitely has a __big engineering solution__ feel to it:

![fraction of my power meme comparing grafana adaptive metrics to just a git repo with grep](/imgs/prometheus/adaptive-metric-power-meme.png)

## Things You Don't Need

### Sub Minute Data Fidelity
You are probably checking your homelab once every few days at most, so why do you expect you would need 15s/30s data fidelity? You can set `60s` scrape/eval intervals and be fine:

```yaml
scrapeInterval: 60s
evaluationInterval: 60s
```

You could go even higher, but above `1m` grafana does starts to look less clean.

To compensate, you [can hack your mixin dashboards](https://github.com/clux/homelab/blob/main/justfile) to increase the time window, and set a less aggressive refresh:

```sh
# change default refreshes on grafana dashboards to be 1m rather than 10s
fd -g '*.yaml' deploy/promstack/promstack/charts/kube-prometheus-stack/templates/grafana/dashboards-1.14/ \
   -x sd '"refresh":"10s"' '"refresh":"1m"' {}
# change default time range to be now-12h rather than now-1h on boards that cannot handle 2 days...
fd -g '*.yaml' deploy/promstack/promstack/charts/kube-prometheus-stack/templates/grafana/dashboards-1.14/ \
   -x sd '"from":"now-1h"' '"from":"now-12h"' {}
# change default time range to be now-2d rather than now-1h on solid dashboards...
fd -g 'k8s*.yaml' deploy/promstack/promstack/charts/kube-prometheus-stack/templates/grafana/dashboards-1.14/ \
   -x sd '"from":"now-12h"' '"from":"now-2d"' {}
```

..which is [actually practical](https://github.com/clux/homelab/blob/ff02315f3280c8199451160ab82a8e35a48f5cb1/justfile#L36-L51) if you use `helm template` rather than `helm upgrade`.

### Kubelet Metrics

97% of kubelet metrics are junk. In a small cluster it's the biggest waste producer in a small cluster, often producing 10x more metrics than anything else. Look at the top 10 metrics they produce with just 1 node and 30 pods:

[![kubelet metrics top 10](/imgs/prometheus/kublet-defaults-1-node.png)](/imgs/prometheus/kublet-defaults-1-node.png)

None of these are useful / contribute towards my above goal. Number 4 and 5 on that list __together__ produce more signals than I consume in TOTAL in my actual setup. The `kube-prometheus-stack` chart does [attempt to reduce this somewhat](https://github.com/prometheus-community/helm-charts/blob/ecc58b9baecc43b0d5719ed509a89e7ca5a7e8e3/charts/kube-prometheus-stack/values.yaml#L1331-L1456), but it by far too little.

### Histograms

Histograms generally account for a huge percentage of your metric utilisation. On a default `kube-prometheus-stack` install with one node, the distribution is >70% histograms:

[![histograms vs non histograms on default kube-prometheus-stack > 70%](/imgs/prometheus/histogram-defaults.png)](/imgs/prometheus/histogram-defaults.png)

Of course, this is largely due to `kubelet` metric inefficiencies, but it's a trend you will see repeated elsewhere (thankfully usually with less eye-watering percentages).

Unless you have a need to see/debug detailed breakdown of latency distributions, do not ingest or produce these metrics (see addendum for more info). It's the easiest win you'll get in prometheus land; wildcard drop them from your `ServiceMonitor` (et al) objects:

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

> Strive for one signal per question where possible.

That said, if you do actually need them, try to decouple them from your other labels (drop pod labels, drop peripheral information) so that you can get the answer you need cheaply. A histogram should answer one question, if your histogram has extra parameters, you can break them down to smaller histograms (addition beats multiplication for cardinality)

> 👺: Histograms will get better with the [native-histograms feature](https://prometheus.io/docs/prometheus/latest/feature_flags/#native-histograms) (see e.g. [this talk](https://www.youtube.com/watch?v=TgINvIK9SYc)). However, this requires the ecosystem to move on to protobufs and it being propagated into client libraries (and is at the moment still experimental at the [time of writing](https://github.com/prometheus/prometheus/releases/tag/v2.54.1)), it's only been [2 years](https://github.com/prometheus/prometheus/commit/41035469d32fe8fd436c55846a5b237a86e69dee) though.

</details>

## A Solution

Because I keep needing an efficient, low-cost setup for prometheus (that still has the signals I care about), so now here is a chart.

It's mostly a wrapper chart over [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) with aggressive tunings / dropping (of what can't be tuned), and it provides the following default [values.yaml](https://github.com/clux/homelab/blob/main/charts/promstack/values.yaml).

You can use it direct with:

```sh
helm repo add clux https://clux.github.io/homelab
helm install [RELEASE_NAME] clux/promstack
```

but I recommend you just take/dissect the [values.yaml](https://github.com/clux/homelab/blob/main/charts/promstack/values.yaml) file and run with it in your own similar subchart.

> 👺: You shouldn't trust me for maintenance of this, and you don't want to be any more steps abstracted away from kube-prometheus-stack.

## Architecture Diagram

The chart is effectively a slimmed down [2022 company setup](/post/2022-01-11-prometheus-ecosystem/); no HA (1 replica everywhere), no `thanos`, no `prometheus-adapter`, but a including a lightweight `tempo` for exemplars:

[![prometheus architecture diagram](/imgs/prometheus/prometheus-simple.png)](/imgs/prometheus/prometheus-simple.png)

## Features

A low-compromises prometheus, all the signals you need at near minimum cost.

### Cardinality Control
Drops **97% of kubelet metrics**, configures minimal `kube-state-metrics`, `node-exporter` (with some cli arg configurations and some relabelling based drops) and a few other apps. In the end we have a cluster running with **7000 metrics**.

[![cardinality control panel](/imgs/prometheus/cardinality-control.png)](/imgs/prometheus/cardinality-control.png)

It's higher than my idealistic estimate - particularly considering this is a one node cluster atm. It can definitely be tuned lower with extra effort, but this is a good checkpoint. This is low enough that [grafana cloud considers it free](https://grafana.com/pricing/). So is it?

### Low Utilization

The end result is a prometheus averaging `<0.01` cores and with `<512Mi` memory use over a week with `30d` retention:

![cpu / memory utilisation 7d means](/imgs/prometheus/minimal-prom.png)

### Auxilary Features

1. Tempo for [exemplars](https://github.com/kube-rs/controller-rs/pull/72#issuecomment-2335150121), so we can cross-link from metric panels to grafana's trace viewer.
2. Metrics Server for basic HPA scaling and `kubectl top`.

> 👺: You technically don't need `metrics-server` if you are in an unscalable homelab, but having access to `kubectl top` is nice. Another avenue for homelab scaling is [keda](https://keda.sh/) with its [scale to zero](https://keda.sh/docs/2.15/reference/scaledobject-spec/#minreplicacount) ability.

### CX Dashboards

The screenshots here are from my own homebrew [dashboards](https://github.com/clux/homelab/tree/main/dashboards) released separately. See the future post for these.

## Links / Comments

Posted on [mastodon](https://hachyderm.io/@clux/113097824893646159). Feel free to comment / [raise issues](https://github.com/clux/homelab/issues) / [suggest an edit](https://github.com/clux/probes/edit/main/content/post/2024-09-07-prometheus-minified.md).
