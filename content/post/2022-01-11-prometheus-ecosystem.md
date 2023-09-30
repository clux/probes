+++
date = "2022-01-11"
description = "operating the stateful metrics system on kubernetes"
title = "Prometheus Stack Review"
slug = "2022-01-11-prometheus-ecosystem"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["kubernetes", "observability"]
+++

As part of my work life in the past year, a chunk of my day-to-day life has consisted of maintaining a `prometheus` installation on top of a sizable kubernetes cluster. My original feeling was "this is not that bad with `kube-prometheus-stack`", but this sentiment has worsened somewhat with the realisation that more and more customizations and pieces were needed for large scale use. Half a year later (and 6+ charts deep), I thought I'd collect my thoughts on the ecosystem - from an operational perspective - with a rough architecture overview post.

<!--more-->

## Disclaimer

1. Information here is based on my own learnings. Some details **might** be wrong. Please submit an [issue](https://github.com/clux/probes/issues) / [fix](https://github.com/clux/probes/edit/master/content/post/2022-01-11-prometheus-ecosystem.md) if you see anything glaring.
2. This post uses the classical open source `prometheus` setup with HA pairs and `thanos` on top. There are other promising setups such as agent mode with remote write.
3. We are following the most-standard `helm` approach and using charts directly (i.e. [avoiding direct use of jsonnet](https://github.com/prometheus-operator/kube-prometheus/))

You can debate the last point, but if you are optimizing for **user-editability** of the prometheus-stack, then `jsonnet` is kind of the opposite of that - particularly when the rest of the cloud is installed with `helm`.

## Architecture Overview

The TL;DR image. Open it up in a new tab, and cycle between if you want to read about specific components below.

[![prometheus ecosystem architecture diagram](/imgs/prometheus/ecosystem-miro.webp)](/imgs/prometheus/ecosystem-miro.webp)

**Legend**:

- **user** components and the user **read path** is <i style="color:green">green</i>
- prometheus/thanos write path is <i style="color:red">red</i>.
- `helm charts` are denoted with **thick dashed lines**
- arrows flow **from** the instigator of the verb **to** the object acted upon

## Developer Interaction

A **user** / developer on a kubernetes cluster with the prometheus stack installed can be expected to:

- **develop applications with hpas** and have them **scraped** by prometheus for metrics
- **create dashboards** in grafana and save them as `ConfigMap` entries
- **create alerting rules** to be triggered when metrics exceed thresholds (and maybe even tweak existing mixins)
- **query metrics** directly on grafana's explore and thanos's queryfrontend

..and the user should not have to know too much about the complicated spaghetti setup that this diagram might give a scary impression of.

## Part 1: kube-prometheus-stack

The blue dashed line represents a set of components that are commonly deployed together on kubernetes due to their interdependence, and these are managed together in the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) helm chart.

It is a [~3k LOC yaml values file](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml) with a further 71k LOC of yaml in that chart folder alone (what could go wrong), and it configures the following components:

- prometheus
- alertmanager
- prometheus-operator
- grafana
- kube-state-metrics
- node-exporter
- kubernetes specific monitors
- monitoring mixins

`24k` lines here are **just** the absolutely **massive** prometheus-operator crds (that are now [too big to apply](https://github.com/prometheus-community/helm-charts/issues/1500)), but it's still an astonishing amount of yaml. Typically you'll end up with between `20-40k` (excluding the crds) with a 100-500 line values file that you have to maintain <small>(you generally don't want your values file to be too large as it becomes harder and harder to keep track of the breaking changes in the stringly typed helm chart apis)</small>.

### prometheus

The octopus at the base of our architecture. Prometheus **scrapes** the metrics endpoints of virtually **every** application you have, **stores** the data **locally** in a low-retention (a week or two) time series database that you can query. <small>(The grey scrape arrows are illustrative, whereas they would usually hit everything, and also hit it from every prometheus pod in the statefulset for redundancy).</small>

It also continually computes configured **evaluation rules**, and raises alerts on configured metric thresholds.

Prometheus is [over 9 years old](https://github.com/prometheus/prometheus/commit/734d28b515026ca9f429eba0a7d09954bceb6387), and has [graduate maturity in cncf](https://www.cncf.io/projects/prometheus/).

In theory, you can run it directly, tell it to scrape this-and-this and be done, but that will lead to downtime quickly. You are going to need at least two replicas for failover, and these are going to need mounted volumes to store their data. A [`StatefulSet`](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) in kubernetes.

For configuration; how to scrape metrics can be tweaked through a mounted `scrape_config` (a [pretty complicated yaml DSL](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config) using `snake_case`). If you get the syntax wrong, prometheus hates your config and won't boot. `promtool` can validate it.

```yaml
relabel_configs:
- source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
  action: keep
  regex: true
- source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
  action: replace
  target_label: __scheme__
  regex: (https?)
- source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
  action: replace
  target_label: __metrics_path__
  regex: (.+)
- source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
  action: replace
  target_label: __address__
  regex: ([^:]+)(?::\d+)?;(\d+)
  replacement: $1:$2
- action: labelmap
  regex: __meta_kubernetes_service_label_(.+)
```

This config is pretty awful to write and debug manually, so imo, you should probably avoid writing it yourself (see the operator below).

Consider importing the [semi-standardised `prometheus.io/scrape`](https://github.com/prometheus-community/helm-charts/blob/970e1334813f90348b849f0a3850262a61f82797/charts/prometheus/values.yaml#L1516-L1759) ones from the main prometheus chart if you wish (they slightly clash with the root chart), but those should be it. Scrape config also needs you to inline secrets, so not great from a security perspective.

[Alerting and recording rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) are similarly configured and has same caveats (don't write them manually).

### alertmanager

Alerts (the data in the special `ALERTS{alertstate="firing"}` metric) are sent from `prometheus` to `alertmanager`.

![how alerts should look](/imgs/prometheus/eva-alert.webp)

At least, this is usually what happens. The communication **to** and **within** `alertmanager` is probably the most **annoying** parts of this entire architecture.

A problem that keeps biting me is how [prometheus can lose track of alertmanager ips, and fail to send alerts for hours](https://github.com/prometheus/prometheus/issues/7063). There are many [issues related to this](https://github.com/prometheus/prometheus/search?q=%22error+sending+alert%22&type=issues).

When alerts do actually get passed to alertmanager, they go through a [pretty complicated internal architecture](https://github.com/prometheus/alertmanager/blob/main/doc/arch.svg), before ultimately being sent to **configured receivers**. Alertmanager contains **deduplication** mechanisms, and a **custom** UDP & TCP **gossip protocol** (that keeps breaking in HA setups - causing [duplicate alerts](https://github.com/prometheus/alertmanager/issues?q=is%3Aissue+duplicate+alerts)).

The built-in receivers for slack/pagerduty seem to handle deduplicating alerts themselves, so if you can get by without HA and don't need a custom webhook, you might be ok.

Still, **your mileage will definitely vary** with this component.

Alertmanager is [almost 9 years old](https://github.com/prometheus/alertmanager/commit/f86966a0e75dfa52f068d3a085753518bd4aea74), has [2 maintainers](https://github.com/prometheus/alertmanager/blob/main/MAINTAINERS.md), and is a sub-project of the prometheus org.

### prometheus-operator

A system that sits on top of prometheus, and extends the configuration with the large [`monitoring.coreos.com` CRDs](https://github.com/prometheus-operator/prometheus-operator/tree/main/example/prometheus-operator-crd). This operator watches these CRDs, validates them via [admission](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/), converts them to a prometheus compatible format, and injects them into the running prometheus via a `config-reloader` sidecar on the prometheus statefulset. The most commonly used configuration CRDs are `PrometheusRule` and `ServiceMonitor`.

This setup avoids you taking down prometheus when you/users write new or invalid configuration or alerts. It also provides a mechanism for referencing kubernetes `Secret` objects (avoiding encryption needs on the base configuration), and it is generally considered the standard abstraction for configuring prometheus scraping.

A minor, but debatable choice they have made, is to re-map the `scrape_config` keys to `camelCase` forcing you have to write half of your `ServiceMonitor` in `camelCase` (the keys), and the other half in `snake_case` (the values):

```yaml
    - relabelings:
      - action: replace
        sourceLabels:
         - __meta_kubernetes_namespace
         targetLabel: kubernetes_namespace
```

The operator **configures** `prometheus`, `alertmanager`, and optionally also thanos `ruler`.

It is over 5 years old and considered `beta`. It's [maintained by](https://github.com/prometheus-operator/prometheus-operator/blob/main/MAINTAINERS.md) people who are mostly disjoint from the the [prometheus maintainers](https://github.com/prometheus/prometheus/blob/main/MAINTAINERS.md). I.e. while this is not a first-class supported thing from prometheus, everyone uses it - and it is [well-documented](https://prometheus-operator.dev/docs/prologue/introduction/).

### grafana

While prometheus does have sufficient querying functionality built in, it does not let you save these queries other than by a long-ass url, so realistically, users will want Grafana for dashboards and cool panel customization.

The key strength of Grafana lies in how it becomes the one-stop shop for __querying & visualising anything__ when you buy into the ecosystem, and the huge amount of data sources they have available:

- [anything prometheus-like](https://grafana.com/docs/grafana/latest/datasources/prometheus/#prometheus-api)
- [cloudwatch](https://grafana.com/grafana/plugins/cloudwatch/)
- [honeycomb](https://grafana.com/blog/2021/08/30/introducing-the-honeycomb-plugin-for-grafana/)
- [tempo](https://grafana.com/docs/tempo/latest/getting-started/tempo-in-grafana/)
- [loki](https://grafana.com/docs/loki/latest/getting-started/grafana/)
- [elastic](https://grafana.com/blog/2021/03/04/why-were-partnering-with-elastic-to-build-the-elasticsearch-plugin-for-grafana/)
- [sentry](https://grafana.com/blog/2021/12/16/introducing-the-sentry-data-source-plugin-for-grafana/)

..plus tons more that you are less likely to run into (`cloudwatch` shown as one common case). Even if you only use if it against `prometheus`, it's still a **generally painless** component to install with tons of **benefits**.

Grafana is packaged as a small-ish [grafana-maintained helm chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana), which is **pinned** as a [subchart under kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-prometheus-stack/Chart.yaml#L45-L48).

The chart contains some nice ways of making **dashboard provisioning** automatic (dashboards as configmaps), but this comes with its own **pain points**:

- need to verify dashboard json out-of-band (validity + uid presence)
- dashboards incur k8s size limits - 1MB on ConfigMap, 256kB applied annotation
- HA setups could split brain dashboards with [partial saves](https://github.com/grafana/grafana/issues/37679) (seems fixed now)
- [provisioned dashboards are incompatible with built-in alerts](https://github.com/grafana/grafana/issues/36328)
- future [dashboard-as-code direction is very undecided](https://github.com/grafana/grafana/issues/31038)

Regardless, the diagram shows how the user flow would be for this, and how it ends up being picked up by a sidecar in the grafana statefulset.

<details><summary style="cursor:pointer;color:#0af"><b>Addendum: Governance & Grafana Labs Sidenotes</b></summary>

Grafana has a more [company driven governance model](https://github.com/grafana/grafana/blob/main/GOVERNANCE.md) - it's maintained almost exclusively by people employed by Grafana Labs - and the company is clearly optimizing for their own cloud offering of a parallel subset of this ecosystem; [Grafana Cloud](https://grafana.com/products/cloud/).

This obvious _conflict of interest_ does pollute the purity of ecosystem somewhat, but at least they have **financing** to move at the great pace they are moving. Some examples of their recent efforts:

- [loki](https://github.com/grafana/loki) - a serious elastic contender for logs that integrates with grafana
- [tempo](https://github.com/grafana/tempo) - a super clean tracing backend that integrates with grafana
- [well maintained helm charts for grafana/tempo/loki](https://github.com/grafana/helm-charts/tree/main/charts)
- [prometheus agent mode](https://grafana.com/blog/2021/11/16/why-we-created-a-prometheus-agent-mode-from-the-grafana-agent/)

Of course, there is the expectation that open source functionality not related to grafana cloud **might** be receiving **less attention**, but I can't really blame them for pursuing a sensible monetisation strategy.

I do hope [Grafana OnCall](https://grafana.com/blog/2021/11/09/announcing-grafana-oncall/) manages to get something contributed upstream (outside the grafana monolith) so we can have a better alternative to alertmanager (as alertmanager has lots of issues and can only alert on prometheus data sources).

</details>

### Monitoring Mixins

A default grafana/prometheus-operator installation is not going to be very helpful without some dashboards that tell you about the state of your system(s).

Common patterns for alerts/dashboards/recording rules are encapsulated in a collection of mixins that are browsable on [monitoring.mixins.dev](https://monitoring.mixins.dev/).

The [`kubernetes-mixin`](https://monitoring.mixins.dev/kubernetes/) stands out in particular, providing excellent, [high maturity](https://grafana.com/docs/grafana/latest/best-practices/dashboard-management-maturity-levels/), drill-down-linked dashboards that are going to be vital for a large percentage of kubernetes related incidents.

In general, these provide a great starting point for most clusters (despite [sometimes](https://monitoring.mixins.dev/kubernetes/#kubernetes-system-kubelet) being [overly noisy](https://github.com/kubernetes-monitoring/kubernetes-mixin/search?q=KubeletTooManyPods&type=issues)). You likely have to re-configure some **thresholds**, and remove some of these alerts as you see fit you your production cluster, but the defaults are generally intelligent.

Unfortunately, there are [many operational challenges with these mixins](https://grafana.com/blog/2021/01/14/how-prometheus-monitoring-mixins-can-make-effective-observability-strategies-accessible-to-all/#the-challenges-with-mixins). `helm` is certainly not best suited to take full advantage of them as not every option is bubbled up to the charts, and these values flow through so many layers it's [challenging](https://github.com/prometheus-operator/kube-prometheus/issues/1333) to find where they truly originate, e.g. [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/templates/prometheus/rules-1.14/prometheus.yaml) <- [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus/blob/main/manifests/prometheusOperator-prometheusRule.yaml) <- [prometheus-operator](https://github.com/prometheus-operator/prometheus-operator/blob/main/example/mixin/alerts.yaml).

This often caused me not wanting to bother with fixing it in the first place, which of course leads to the mixins not being as good as they could be. AFAIKT, your options are:

- **forking** the mixins you care about and **opting out** of automatic upstream fixes
- post-template modifications of minor details with hacky solutions like sed/jq
- managing mixins **out-of-band**, aligning implicit default values with the charts, and customizing with jsonnet
- going through the drudgery of propagating mixin fixes through several repos

While I advocate for trying to propagate fixes when motivation strikes, **forking mixins** at least makes your yaml **readable** in your gitops repo, so it's actually a decent option - particularly given how [awful](https://prometheus-operator.dev/docs/developing-prometheus-rules-and-grafana-dashboards/#adjustment) the other solutions are.

Regardless, it's another useful, but imperfect component that you are going to need.

### Metric Sources

We move on to the components that create most of your data in prometheus.

Using the mixins (or equivalent dashboards) effectively **requires** you having **standard kubernetes metric sources** configured (otherwise you will have missing values in all your mixin dashboards).

We will briefly run through these metric sources, focusing first on the ones that appear in the `kube-prometheus-stack`. In general, these are pretty-well behaved and low-maintenance, so there won't be too much to say about these.

#### node-exporter

The main external metric source. A [prometheus org maintained](https://github.com/prometheus/node_exporter) `DaemonSet` component that scrapes system level **unix metrics**. It mounts `/`, `/sys`, and `/proc` - with `hostPID` and `hostNetwork` enabled - to grab extensive information about each node.

It's a [sub-chart of kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-prometheus-stack/Chart.yaml#L41-L44), and it has a slew of [configurable exporters](https://github.com/prometheus/node_exporter#collectors), which can be [configured from the chart](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/prometheus-node-exporter/values.yaml#L150-L152), but the [defaults from kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-prometheus-stack/values.yaml#L1358-L1360) are likely good enough.

#### kube-state-metrics

The second stand-alone metric exporter for kubernetes. Maintained by kubernetes itself; [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) is a **smaller deployment** that generates metrics from what it sees the state of objects are from the apiserver. It has [client-go reflectors](https://github.com/kubernetes/kube-state-metrics/blob/master/docs/design/metrics-store-performance-optimization.md#proposal) and uses the results of their long watches to populate metrics.

It's a conceptually pretty simple piece; an **api -> metrics transformer**, but kubernetes has a lot of apis, so definitely not something you want to write yourself.

In example terms; this component provides the **base data** for what you need to **answer** the questions like whether your:

- "`Pod` has been in an unhealthy state for `>N` minutes"
- "`Deployment` has failed to complete its last rollout in `N` minutes"
- "`HorizontalPodAutoscaler` has been maxed out for `>N` minutes"

..stuff that you can figure out with `kubectl get -oyaml`.

KSM is deployed via an [in-tree subchart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) under [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-prometheus-stack/Chart.yaml#L37-L40).

You can configure what apis it provides metrics for [under collectors](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-state-metrics/values.yaml#L155-L183).

<details><summary style="cursor:pointer;color:#0af"><b>Addendum: Label configuration caveat</b></summary>

The only issue I've run into with KSM is that the metric labels are often insufficient for integration with existing standard alerting setups (problem being that the generic alerts from `kubernetes-mixin` will fire, but it's hard to tell by the name of the deployment alone who should get that alert). This can be rectified with the [`metricLabelsAllowlist`](https://github.com/prometheus-community/helm-charts/blob/9401be121c65e6e3332670a49c5ad6ba2aeae9c3/charts/kube-state-metrics/values.yaml#L135-L142) in the chart, e.g.:

```yaml
    metricLabelsAllowlist:
    - "deployments=[app.kubernetes.io/name,app]"
    - "jobs=[app.kubernetes.io/name,app]"
    - "horizontalpodautoscalers=[app.kubernetes.io/name,app]"
```

 to inject more labels (here `app`) from the root object onto metrics. Annoyingly, these only get injected into an informational `_labels` metric, so you'd have to extend `kubernetes-mixin` with big joins to get these values exposed in the alert:

```diff
diff --git development/rules-kubernetes-apps.yaml development/rules-kubernetes-apps.yaml
index e36496e..988d6a6 100644
--- development/rules-kubernetes-apps.yaml
+++ development/rules-kubernetes-apps.yaml
@@ -220,7 +220,9 @@ spec:
-      expr: kube_job_spec_completions{job="kube-state-metrics", namespace=~".*"} - kube_job_status_succeeded{job="kube-state-metrics", namespace=~".*"}  > 0
+      expr: |-
+        (kube_job_spec_completions{job="kube-state-metrics", namespace=~".*"} -
+        kube_job_status_succeeded{job="kube-state-metrics", namespace=~".*"}  > 0) *
+        on(job_name) group_left(label_app_kubernetes_io_name)
+        sum by (namespace, job_name) (kube_job_labels{job="kube-state-metrics", label_app_kubernetes_io_name=~".+"})
```
</details>

#### kubernetes internal sources

For poking at the internals of kubernetes, you can enable configurable scrapers for:

- kubelet
- kube-apiserver
- kube-controller-manager
- kube-scheduler
- kube-proxy
- coreDns or kubeDns
- etcd

There is some sparse documentation for these under [kubernetes/cluster-admin](https://kubernetes.io/docs/concepts/cluster-administration/system-metrics/).

These are a little more optional, but you need the [kubelet metrics](https://github.com/kubernetes/kubernetes/tree/ea0764452222146c47ec826977f49d7001b0ea8c/pkg/kubelet/metrics/collectors) (via [cadvisor](https://github.com/google/cadvisor)), for the main kubernetes mixins, so make sure those are enabled.

The more superfluous ones that come with the kube-apiserver (particularly the [burnrate stuff](https://monitoring.mixins.dev/kubernetes/#kube-apiserver-burnraterules)) are particularly heavy evaluation rules (saw a ~6 cores reduction after removing them from one busy prometheus pair). Imo, you probably only need some of these if you are a cloud provider.

#### Extra metrics exporters

Any additional metrics exporters are not part of the `kube-prometheus-stack` chart, but there are [tons of exporters availble](https://github.com/prometheus-community/helm-charts/tree/main/charts) supported by the same `prometheus-community`, so would expect them to be of high quality based on their commit history and repository CI, but have otherwise not enough experience here.

## Part 2: [Thanos](https://thanos.io/)

Before this step, you can have a pretty self-contained prometheus stack where grafana's default data source would point at the prometheus' `Service`, and metrics would fade out after prometheus' `retention` period.

Thanos essentially **takes all the components** that's found **inside prometheus**, and allows you to deploy and **scale them separately**, while providing a **prometheus compatible API** for **long term** storage of metrics.

It relies on data being sent from any prometheus set - via a sidecar on prometheus (configurable via the `kube-prometheus-stack` chart) - to some provisioned object storage (here S3).

The **write paths** to the S3 bucket is **highlighted** in <i style="color:red">red</i> on the diagram.

The various **read paths** are **highlighted** in <i style="color:green">green</i> on the diagram, and show how various types of reads propagate to various systems (grafana is the normal entrypoint, but the query-frontend is also a nice way to debug thanos specifics closer to the source).

The **thanos configuration** is __"almost"__ completely contained in the thanos **chart** (of your choice) and is marked with a dashed <i style="color:purple">purple</i> square.

> **"almost"**: S3 configuration is also needed in `kube-prometheus-stack` for writing

There are several charts that are trying to package the same thing for thanos:

- [bitnami/thanos](https://github.com/bitnami/charts/tree/master/bitnami/thanos/) - most active
- [banzai/thanos](https://github.com/banzaicloud/banzai-charts/tree/master/thanos) - pretty inactive
- [thanos-community/helm-charts](https://github.com/thanos-community/helm-charts) - ["official"](https://github.com/thanos-io/thanos/issues/1820), but clearly abandoned/out-of-date

They **all have problems**:

- `bitnami` ties itself to its own ecosystem, and is not based on the [official jsonnet](https://github.com/thanos-io/kube-thanos)
- `banzai` is clearly outdated
- `thanos-community` charts lacks developers ([and they see helm users as a minority](https://github.com/thanos-io/thanos/issues/1820#issuecomment-752609815))

So far, the `bitnami` chart is the most appropriate for `helm` users.

It's an evolving ecosystem with many components, but none of them are as complicated to operate as the `kube-prometheus-stack` components (and there seems to be a lot less footguns).

Thanos is an [incubating cncf project](https://www.cncf.io/projects/thanos/) that is just over [4 years old](https://github.com/thanos-io/thanos/commit/3a7b2996f8574048900cfc6259561ac412bcf251). It has a healthy set of [maintainers](https://github.com/thanos-io/thanos/blob/main/MAINTAINERS.md), it [moves fast](https://thanos.devstats.cncf.io/d/74/contributions-chart?orgId=1&var-period=d7&var-metric=contributions&var-repogroup_name=All&var-country_name=All&var-company_name=All&var-company=all), and makes some of the most [well-documented](https://thanos.io/tip/thanos/getting-started.md/), high-quality [releases](https://github.com/thanos-io/thanos/releases) out there.

While it's **not trivial** to maintain - the large cpu/memory usage and scaling profiles presents some challenges - it has generally **not** presented major problems.

A quick run-through of things worth knowing about the components follows:

### [Thanos Query Frontend](https://thanos.io/tip/components/query-frontend.md/)

The http UI users can use. Very light-weight. The `Service` for this `Deployment` generally becomes the default user substitute way to query anything (instead of going to a prometheus service's web interface - which after installing thanos is mostly useful for debugging scrape configs).

It also looks **almost exactly** like the prometheus web interface (sans ability to debug scrape targets).

This **proxies** all traffic to **thanos query** and never breaks.

### [Thanos Query](https://thanos.io/tip/components/query.md/)

The big **fan-out engine** that fetches query data from one or more metric sources (typically thanos store + prometheus services), and computes the result of your query on the retrieved data.

This component will suddenly spike in both CPU and memory when it's under heavy load (i.e. users doing big queries), so an HPA here on CPU works OK - albeit some stabilization values might be useful:

```yaml
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: prometheus-stack-thanos-query
  minReplicas: 2
  maxReplicas: 10
  # Slow down scaleDown behavior as thanos query has very sporadic usage
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 100
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      policies:
      - type: Percent
        value: 20
        periodSeconds: 15
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        averageUtilization: 70
        type: Utilization
```

The compute workload [kubernetes-mixin dashboard](https://monitoring.mixins.dev/kubernetes/#dashboards) will show roughly how this HPA reacts to changes (stacked view, colors represent pods):

[![thanos query cpu and memory usage](/imgs/prometheus/thanos-query-usage.png)](/imgs/prometheus/thanos-query-usage.png)

which lines up with the `thanos_query_concurrent_gate_queries_in_flight` metric reasonably well.

### [Thanos Store](https://thanos.io/tip/components/store.md/)

The read interface to long term storage. It's also prometheus api compatible (using the Store API), so from the querier's POV it is analogous to querying a prometheus.

This component also will **also** suddenly spike in both CPU and memory when users start doing big queries on historical data (i.e. further back in time than prometheus' `retention`), so a similar HPA to thanos query to scale on CPU works reasonably well:

[![thanos store cpu and memory usage](/imgs/prometheus/thanos-store-usage.png)](/imgs/prometheus/thanos-store-usage.png)

### [Thanos Ruler](https://thanos.io/tip/components/rule.md/)

An **optional** rule evaluation / alerting analogue.

This is a bit more **niche** than the rule evaluation in prometheus itself, because rule evalution on the prometheus side essentially gets stored as metrics in the long term storage. The only reason you need this is if you need to alert on / create evaluation rules on a federated level (e.g. to answer whether you have a high error rate across all production clusters / prometheus sets).

If you need the alerting part, then you have another component that talks to `alertmanager` 🙃.

Can run in a stateful mode - presenting a prometheus compatible store api that the querier can hit for rule results - or statelessly; persisting rule results to s3.

### [Thanos Compactor](https://thanos.io/tip/components/compact.md/)

The magic sauce that makes **querying long term** data **practical** - as raw data is too resource intensive to use when you want to view result over the past weeks or months.

The compactor will go through the S3 bucket, and create lower-res data (at `5m` averages and `1h` averages), and delete raw data (after a configurable time has passed).

One such configuration can be:

- Maintain `raw` resolution for `7d`
- Create `5m` resolution chunks that are kept for `30d`
- Create `1h` resolution chunks that are kept for `1y`

The `compactor` will **chug along** and do these in steps (creating `5m` res from raw, then creating `1h` res from `5m` res), as the chunks become available.

**Long-term**, the lower res data is **more practical** to both **query** and **store**, but you end up with multiple variants of the data in the first 7 to 30 days.

If this is hard to visualize, then fear not, you can browse to thanos [bucket web](https://thanos.io/tip/components/tools.md/#bucket-web) to visualise the state of your `S3` bucket. It's a small service (included in the chart) that presents the view, and what resolutions are availble from various dates.

Think of `compactor` as a cronjob (but with [good alerts](https://monitoring.mixins.dev/thanos/#thanos-compact)) that needs to do big data operations. If you give it enough space, cpu, and memory it is usually happy. It will use these resources a bit sporadically though - some cycles are clearly visible in memory use:

[![thanos compactor cpu and memory usage](/imgs/prometheus/compactor-cycles.png)](/imgs/prometheus/compactor-cycles.png)

## Part 3: Metrics API Integrations

The final components reside in the void outside the two big standard charts and contains the implementors of the various [metrics apis](https://github.com/kubernetes/metrics#apis):

- **resource metrics** api (cpu/memory for pods)
- **custom metrics** api (metrics related to a scalable object)
- **external metrics** api (metrics unrelated to a scalable object)

These are apis that allow Kubernetes to `scale` your workloads (with varying degrees of intelligence) through HPAs, but you need something to implement them.

I mention these different underlying apis explicitly because [currently](https://github.com/kubernetes-sigs/custom-metrics-apiserver/issues/70) you can **only** have **one implementor** of each api, and if you have more than one thing that provides custom metrics (like say cloudwatch metrics + prometheus adapter), then you are better served by using [KEDA](https://keda.sh/) than what is described herein.

### metrics-server

The first is a kubernetes standard component; the [metrics-server](https://github.com/kubernetes-sigs/metrics-server).

It only implements the **resource metrics** api, and thus **only** enables you scale on cpu and memory.

It extracts cpu/memory values values via `kubelet`, and as such allows `kubectl top` + HPAs to work out of the box - without prometheus or any of the other components visualised herein. It's even installed on `k3d` by default.

### prometheus-adapter

This adapter funnels metrics from `prometheus` into the HPA universe, so you can scale on **arbitrary** metrics.

It implements the resource metrics, custom metrics, and external metrics APIs. The underlying setup for this has [stable docs from k8s 1.23](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#scaling-on-custom-metrics), and in essence this allows you to scale on __custom metrics__ (related to the scaling object) or __external metrics__ (unrelated to the scaling object).

The [syntax needed for this component](https://github.com/kubernetes-sigs/prometheus-adapter/blob/c9e69613d3e1ccf4a5828aba25de613d84694779/docs/sample-config.yaml) definitely leaves a lot **to be desired**. The only way we have managed to get somewhere with this is with principal engineers and a lot of trial and error. Thankfully, there are [some helpful resources](https://github.com/kubernetes-sigs/prometheus-adapter/blob/master/docs/walkthrough.md), this is still not easy.

The repository for [prometheus-adapter](https://github.com/kubernetes-sigs/prometheus-adapter) is also not receiving a whole of attention: [almost half](https://github.com/kubernetes-sigs/prometheus-adapter/issues?q=is%3Aissue+is%3Aclosed+label%3Alifecycle%2Frotten) of their closed issues looks like they were closed by kubernetes org's auto-closer bot. You can say many sensible things about this closing practice - on the importance of funding and triagers for open source software - but it ultimately sends a message:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Unpopular opinion: I think solving issue triage by letting robots auto close issues that were never responded to is a *horrible* way to manage your project and tells users you don&#39;t give a crap about their effort filing bugs :(</p>&mdash; Benjamin Elder (@BenTheElder) <a href="https://twitter.com/BenTheElder/status/1407774856033181696?ref_src=twsrc%5Etfw">June 23, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

It does have its own [prometheus-community maintained chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-adapter), which is of high quality, but you will need to figure out the templated promql yourself.

Without having much experience with [KEDA](https://keda.sh/), I would recommend looking into using [KEDA's prometheus scaler directly instead](https://keda.sh/docs/2.5/scalers/prometheus/) of using the arcane template magic from `prometheus-adapter`.

## Happy new year

That's all I can bring myself to write about this archeticture for now. It took longer than I anticipated, so hopefully this was useful to someone. Regardless, best of luck maintaining prometheus in 2022.
