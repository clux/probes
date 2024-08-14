+++
date = "2024-09-13"
description = "misadventures with prometheus agent mode with thanos receive"
title = "You Will (Not) Scale Prometheus"
slug = "2024-09-13-thanos-misadventures-with-scaling"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["kubernetes", "observability", "prometheus", "thanos"]
+++

To aid a memory obese `prometheus`, I recently helped in attempting to slowly shift a cluster over to [prometheus agent mode](https://prometheus.io/blog/2021/11/16/agent/) sending data to [thanos receive](https://thanos.io/tip/components/receive.md/) over the last couple of months. I have now personally given up on this goal due to a variety of reasons, and this post explores why.

## Background Setup
The original setup we started out with is basically this (via [2022 ecosystem post](/post/2022-01-11-prometheus-ecosystem/)):
[![prometheus architecture diagram](/imgs/prometheus/ecosystem-miro.webp)](/imgs/prometheus/ecosystem-miro.webp)

and we were planning to move to this:

[![prometheus architecture diagram agent mode](/imgs/prometheus/agentmode.webp)](/imgs/prometheus/agentmode.webp)

The key changes here:

1. enable [prometheus agent feature](https://prometheus.io/docs/prometheus/latest/feature_flags/#prometheus-agent) limiting it to scraping and remote writes to receive
2. deploy [thanos receive](https://thanos.io/tip/components/receive.md/) for short term metric storage + S3 uploader (no more sidecar)
3. deploy [thanos rule](https://thanos.io/tip/components/rule.md/) as new evaluator, posting to alertmanager

With the 3 components replacing prometheus (agent, receive, ruler) in-theory having better scaling characteristics by themselves, with a cleaner, and more delineated area of responsibility.

## Complexity & Pickup

Splitting one component into 3 sounds simple in theory, but while people might like the idea of splitting a monolith, few people actually end up enjoying operating a distributed monolith. The new complexity is in many ways also compounded by these components not being as battle tested as the more traditional prometheus/thanos setup.

The original setup can hardly be considered trivial either.

### 3 Single Points of Failure
You need basically 3x the alert coverage now since the single point of failure is split into 3 parts:

- [ruler query failures](https://thanos.io/tip/components/rule.md/#risk) means no alerts get evaluated even though metrics exists in the system.
- agent mode downtime means evaluation works, but metrics likely absent
- receive write failures / downtime means rule evaluation will fail

This means careful alert management. The [mixins](https://monitoring.mixins.dev/thanos/#thanos-receive) are good, but needed manual wrangling in the chart to work well.

The whole setup also suffers from the "who alerts about alerting failures" problem. A single __deadman's switch__ is necessary, but not sufficient; as `ruler` can successfully send the [WatchDog alert](https://github.com/prometheus-community/helm-charts/blob/d2566648d72d0ed136a38254985ccd25d6f894b8/charts/kube-prometheus-stack/templates/prometheus/rules-1.14/general.rules.yaml#L55-L88) to your external ping service, despite the agent being down.

### Configuration Splits
Since `thanos-ruler` is the new query evaluator, and we use `PrometheusRule` crds, these crds must be provisioned into `thanos-ruler` via `prometheus-operator`. On the helm side, this only works with `kube-prometheus-stack` creating the `ThanosRuler` crd (which `prometheus-operator` will use to generate `thanos-ruler`), in the same way it originally created the `Prometheus` / `PrometheusAgent` crd (to create the `prometheus` or `prometheus-agent` pair).

Specifically, we have to NOT enable `ruler` from the [bitnami/thanos](https://github.com/bitnami/charts/blob/main/bitnami/thanos/README.md) chart, and have a thanos component live inside `kube-prometheus-stack` instead. Not a major stumbling block, but goes to show some of the many sources of confusion.

### New Features, Slow Iteration
Agent mode, with a writing ruler also feels fairly new (in prometheus time), and support for all the features generally takes a long time to fully propagate from prometheus, to thanos, to the operator.

As an example see; `keep_firing_for`:

- Nov 2022 :: [Raised in prometheus](https://github.com/prometheus/prometheus/issues/11570) (lazy me)
- Feb 2023 :: [Implemented in prometheus](https://github.com/prometheus/prometheus/releases/tag/v2.42.0)
- June 2023 :: [Support in prometheus-operator for PrometheusRule](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.66.0)
- Jan 2024 :: [Support in thanos](https://github.com/thanos-io/thanos/releases/tag/v0.34.0)
- March 2024 :: [Support in prometheus-operator for ThanosRuler](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.72.0)

So as you can see, a long chain where `ruler` sits at the very end, and __to me__ this it is indicative of the amount of use `ruler` realistically gets.
We also had to upstream [support for ruler remote write configuration in kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/pull/4092).

There are also many __desired features__ we want from agent mode that are not yet there, but we'll cover that later.

## Performance Problems

This is the main problem of the article.

Unfortunately, the best performance we managed to get out of this setup (after weeks of tuning) was still **2x-3x worse** than the original HA prometheus pair setup (again from the [2022 post](/post/2022-01-11-prometheus-ecosystem/) / 1st diagram above). We also saw these new **subcomponents perform worse than the original prometheus**, and have **worse scaling characteristics**. Rule evaluation performance also seriously deteriorated.

In many ways, the increased cost was not totally unexpected - removing memory colocation of the TSDB was always destined to introduce overhead - but the amount was definitely surprising.

We could pay our way out of __some__ of these problems (with e.g. ~one extra node per cluster), but the worse scalability baseline of components such as `receive` is a non-starter.

### Overall Cluster Measurements

> Benchmarks are comparing using prometheus [v2.53.1](https://github.com/prometheus/prometheus/releases/tag/v2.53.1) and thanos [0.36.0](https://github.com/thanos-io/thanos/releases/tag/v0.36.0) and consider `mean` utilisation measurments from cadvisor metrics on a cluster with a modest `~2M` time series per prometheus replica. We only consider the biggest statefulsets (receive, prometheus/agent, ruler, storegw). In either setup `receive` or `prometheus` were running on a `3d` local retention.

Over full workdays we saw `~13 cores` constantly churning, and `~80 GB` of memory used by the 3 statefulsets (10 cores and 50GB alone from `receive`):

[![measurements for agent mode](/imgs/prometheus/sts-load-agentmode.webp)](/imgs/prometheus/sts-load-agentmode.webp)

Compare to the same setup using a normal HA prometheus (no ruler, no receive, local eval) and we have `~4 cores` and maybe `~30GB` memory:

[![measurements for normal prometheus mode](/imgs/prometheus/sts-load-regular.webp)](/imgs/prometheus/sts-load-regular.webp)

So cluster wise, we end up with a between 2x-3x drop by switching back to non-agented, monolithic prometheus.

### Receive Performance

From the same graphs we see that the portion of prometheus that got factored out into thanos receive, is **using roughly 2x the CPU and memory of a standalone prometheus**, despite not doing any evaluation, or any scraping. This is despite running it as minamally as possible with `3d` retention, and 1 replication factor.

<details><summary style="cursor:pointer;color:#0af"><b>Addendum: Attempted modifying flags</b></summary>

Tried various flags here over many iterations to see if anything had any practical effects.

- [new ketama hashing algorithm](https://thanos.io/tip/components/receive.md/#ketama-recommended)
- `--enable-auto-gomemlimit` - barely helps
- `--tsdb.wal-compression` - disk benefit only afaikt
- `--receive.forward.async-workers=1000`  - irrelevant, receive does not forward requests in our setup

</details>

The performance of `receive` was the biggest problem here, as we wanted to move away from a monolithic `prometheus` precicely because prometheus has finite scalability in this setup (eventually you run out of super-sized cloud nodes to run them - we had to provision a 300G memory one for a cardinality explosion incident once).

We did not pursue the [split receiver proposal](https://github.com/thanos-io/thanos/blob/release-0.22/docs/proposals-accepted/202012-receive-split.md), because it seemed even more complex and did not know how to implement it until recently. [This comment is promising for the future](https://github.com/thanos-io/thanos/issues/7054#issuecomment-1933270766) if you are attempting `receive` in a similar veins.

### Agent Performance

The agents (which now should only do scraping and remote write into receivers) are surprisingly not free either. From graph above, the memory utilisation is close to a full prometheus!

There is at least [one open related bug for this](https://github.com/prometheus/prometheus/issues/10431).

### Ruler Performance

Ruler evaluation performance when having to go through queriers is also impacted, and it surprisingly scales non-linearly with number of ruler replicas.

![ruler evaluation time per pod over 1h](/imgs/prometheus/ruler-time-by-pod.webp)

This panel evaluates `sum(avg_over_time(prometheus_rule_group_last_duration_seconds[1h])) by (pod)` per pod over three modes:

1. up until 08/06 12ish :: 2 replicas of thanos ruler
2. middle on 08/07 :: 1 replica of thanos ruler
3. end on 08/08 :: 2 replicas of prometheus (non-agent mode)

As you can see the query time increases within each pod when increasing replicas. Possibly this is load accumulating in the new distributed monolith, but a near 50% spike per ruler?In either case, the actual comparison of `3s avg` vs `50s avg` is kind of outrageous. Maybe this is misreading it, but the system definitely felt more sluggish in general.

No rules generally missed evaluations, but it got close to it, and that was not a good sign given it was in our low-load testing cluster.

Beyond this, this component is nice, seemingly not bad in terms of utilisation, and nice to debug. [Ruler metrics docs](https://thanos.io/tip/components/rule.md/#must-have-essential-ruler-alerts) and `sum(increase(prometheus_rule_evaluation_failures_total{}[1h])) by (pod)` in particular were very helpful.

## Speculation on Causes
I don't have clear root causes here unfortunately, so feel free to leave comments on the post (TODO), or raise issues and i'll add clarifications.

In the mean time, take the next subsections with a grain of salt.

### User Error

First things first; it’s entirely possible that I have missed something here. The system worked, it took a lot of wrangling but it did what it set out to do, just inefficiently.

There are discouragingly many open bugs with minimal communication around this. Possibly certain configuration options exist to make things easier for us, possibly some are badly tuned still. I did spend like 2 months on this myself though.

No matter how you slice it; agent mode with thanos is a complex beast involving ~10 main services (agent, operator, receive, query, store, compactor, ruler, adapters, alertmanager, grafana), and it shouldn’t have to be this hard. My gut feeling is that this needs more time, and clarity on direction.

### Colocation Removal

Having a big block of memory directly available for 3 components (scrape → eval / local storage) without having to to through 3 network hops / buffer points (ruler → query → receive) to do the same thing is potentially a bigger deal than originally envisioned.

### Evaluation Side Search Space

There is a chance that a good portion of the `ruler` time has come from going through `thanos-query`. This was a deliberate choice so that people could write alerts referencing more than `3d` (local retention) worth of data to do more advanced rules for anomaly detection. This __should not__ have impacted most of our queries since most do not do this type of long range computations. We also did not see significant CPU congestion or memory use on `ruler` to warrant considering this deeply.

We tried moving the `ruler` query endpoint directly to `receive` but this did not work from `ruler` using the same syntax as query/storegw.

### Wrong Tool for Scaling

Agent mode on the prometheus side seems perhaps more geared to network gapped / edge / multi-cluster setups than what we were looking for (e.g. [grafana original announce](https://prometheus.io/blog/2021/11/16/agent/) + [thanos receive docs](https://thanos.io/tip/components/receive.md/#receiver)). It’s certainly not as battle tested as I would have wanted, and we might even be the first for certain components. E.g. see my sad [chart upstream functionality](https://github.com/prometheus-community/helm-charts/pull/4092), and ghost-town [metric issues in thanos](https://github.com/thanos-io/thanos/issues/created_by/clux).

It’s possible that other solutions perform better, e.g. grafana mimir. I really cannot say.

It’s also possible that we could instead go harder on metric limits (histogram limitations / native histograms / dropping pod/node enrichment for overused histograms) than to follow over-complicated, inefficient, and costly (to run) solutions to a problem that can be perhaps more easily managed by better dilligence on our own field.

## Confusing Agent Promise

Perhaps the most confusing thing to me is that **agent mode does not act like an agent**.

You cannot run it as a `DaemonSet`, you merely split the monolith out into a distributed monolith. This is a present-day limitation. Despite people willing to help out, the [issue](https://github.com/prometheus-operator/prometheus-operator/issues/5495) remains unmoving. I had hoped google would upstream its actual statefulset agent design (mentioned in the issue), but so far that has not materialised. Who knows if [agent mode will even become stable](https://github.com/prometheus/prometheus/discussions/10979).

On the grafana cloud side, the [grafana agent](https://grafana.com/docs/agent/latest/static/operation-guide/) did [support running as a daemonset](https://github.com/grafana/agent/blob/c281c76df02b7b1ce4d3c0192915628343f4c897/operations/helm/charts/grafana-agent/templates/controllers/daemonset.yaml), but [it is now EOL](https://grafana.com/blog/2024/04/09/grafana-agent-to-grafana-alloy-opentelemetry-collector-faq/) anyway.

In either case, the biggest problem isn't the scraping, it's the local storage (receive/prom) for fast evaluation of rules / alerts. There is [prometheus operator's sharding suggestion](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/shards-and-replicas.md) that can help partition this, but it does __seem to__ require your own label management, and uneven shard request (cpu/mem) balancing (due to some shards scraping more metrics and thus having more load). A bit too manual for my taste.

It’s been *only* 3 years since [agent mode was announced](https://prometheus.io/blog/2021/11/16/agent/). Now, 2 years later the whole [remote write protocol is being updated](https://github.com/prometheus/prometheus/issues/13105) and [just landed in prometheus](https://github.com/prometheus/prometheus/releases/tag/v2.54.0).

So who knows what the future brings here. It might be another couple of years before new remote write gets propagated through the thanos ecosysystem.

Perhaps it's better to just lean on the classic thanos split and keep reducing local prometheus `retention` time down to a single day or lower (if you dare risk sidecar failures being irrecoverable).

## Future

No grand conclusion unfortunately, just another data point in the __sea of gut feels__ for you to fish for your next tech stack.

Maybe there is a way to make this work, but I am more than happy to throw in the towel here **if only for complexity reasons**. If the stack becomes so complex that the entire thing cannot be maintained if one key person leaves, then I would kind of consider that a failure. This was hard enough to explain before `receive` and agent mode.

My 2c here is that by pursuing this complexity non-critically we inevitably end up feeding the giant providers, resulting in slow iteration cycles, expensive B2B deals, when perfectly simple alternatives exist provided we are willing to moderate ourselves.

If I have to wrangle with cardinality limits org-wide by advocating for `action: drop` on histograms, or disabling prometheus operator enriched pod labels (which interact multiplicatively with histogram buckets), then this seems like a simpler and more maintainable solution for one person.

I'll post later on specifically how to minimally run a prometheus in a homelab setting without any of this faff, but I need a break from this first.
