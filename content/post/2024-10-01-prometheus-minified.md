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

I would like to argue that these difficulties are largely self-imposed, and a result of poor cardinality control.

## Signals, Symptoms & Causes

Why do we originally install a metrics system at all? We want to have insights into a couple of key **signals**. At the very basic level you want to tell if your "service is down", because you want to be able to use it. That's the main, user-facing signal. Setup something that test if the service responds with a `2XX`, and alert on deviations. You [don't even need](https://www.checklyhq.com/product/api-monitoring/) prometheus for this.

However, while you can do basic sanity outside the cluster, you don't have a view of __utilisation and saturation__ (i.e. [USE Method](https://www.brendangregg.com/usemethod.html)), so you cannot predict upcoming failures via say:

- message queues full (rejected work)
- high cpu utilisation (degraded latency)
- memory utilisation high (oom kill imminent)
- disk space nearing full (failures imminent)

You can argue a little more idealistically about whether you should only be "aware of something going wrong", or be "aware that something is in a risky state" (e.g. [symptoms not causes](https://cloud.google.com/blog/topics/developers-practitioners/why-focus-symptoms-not-causes)), but you can't avoid utilisation/saturation as a predictor for degraded performance (in the same sense as; you don't wait for a certificate to expire before renewing it).

> Main point: You should be able to enumerate the signals that you want to consider (be able to visualise and be used in alerts).

## How Many Signals

Let's do some basic and simplified enumeration maths on how many signals you actually want to properly identify failures quickly.

### Compute Utilisation/Saturation
Consider the example of a cluster with 200 pods, and 5 nodes.

- Want {utilization,saturation} of cpu/memory :: 2 * 2 = 4
- Want to see them PER `Pod` :: 200 * 4 = 800
- Want to see them per `Node` :: 5 * 4 = 20

So, in theory, we should be able to visualise cluster, node, and pod level utilisation for cpu and memory with only 820 metrics.

> NB: Pods are only found on one node, so `Pod` cardinality does not multiply with `Node` cardinality.

## Basic Prometheus Setup
How to deploy a base prometheus:


[![prometheus architecture diagram](/imgs/prometheus/prometheus-simple.webp)](/imgs/prometheus/prometheus-simple.webp)

This is basically my [2022 company setup](/post/2022-01-11-prometheus-ecosystem/), but with thanos ripped out.

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
