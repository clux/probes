+++
date = "2023-12-22"
description = "Notes from a week of browsing CNCF youtube"
title = "Talk log from KubeCon Chicago"
slug = "2023-12-22-kubecon-chicago-log"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["kubernetes"]
+++

As time goes by, I find myself increasingly disinterested in actually travelling out to a convention, when my preferred method of consuming conference talks is overwhelmingly VOD form with 2x/FF potential.

This is doubly so when the convention is increasingly corporate (like KubeCon), and the [CNCF youtube channel](https://www.youtube.com/c/cloudnativefdn/videos) is in general high quality. Get it before you ad-blockers break.

This post contains a quick export from my personal notes on some significant talks at **KubeConNA'23** (make of them what you will).

<!--more-->

My interest areas this kubecon fall broadly into these categories (and will group talks by these):

- **observability related** :: maintain a lot of metrics related tooling
- **continuous deployment** :: maintain a lot of ad-hoc cd tooling
- **security** :: maintain a bunch of controllers and ad-hoc validations
- **kubernetes** :: cool to see where the platform i build on top of end up going
- **maintainership** :: am trying to scale kube-rs beyond myself

## Observability

### [How Prometheus Halved It's Memory Storage](https://www.youtube.com/watch?v=29yKJ1312AM)
nice journey into prometheus space optimization and how the layout of their labels matter a lot. great work.

### [Evaluating Observability Agent Performance](https://www.youtube.com/watch?v=BIaftvtFPHg)
good overview of where the utilization overhead comes from and how to think in terms of backpressure.

### [OpenTelemetry: What's Next](https://www.youtube.com/watch?v=OEGgmTNfYsU)
they're graduated now and deal with metrics (but still experimental w.r.t. rust).
imo it feels really strange to be shoehorning everything here into one agent, but we'll see what benefits it can bring later (they keep talking about consistent metadata between them).

### [Exploring the Power of Metrics Collection with OpenTelemetry](https://www.youtube.com/watch?v=hsI7mCJ0JSE)
after the 45m+ workshop, they get into the horrific setup they've made inlining scrapeConfigs inside collector crds to support metrics.
kind of look at this, and all i can think is "why tho?".


### [KEDA Graduation Announcements](https://www.youtube.com/watch?v=wYQ2cvSj6os)
looks increasingly nice. (i need to kill the prometheus-adapter garbage template format i currently deal with.)

keda_ metrics, scaling modifiers, pausing, job scaling, prom caching, all seem like very nice features.

### [All You Need to Know About Prometheus in 2023](https://www.youtube.com/watch?v=xoaQ9RIDqfs)
very interesting talk if you are invested in this ecosystem.

they mention `keep_firing_for` landing which feels great (because it was [my suggestion](https://github.com/prometheus/prometheus/issues/11570)).
q/a session reveal they think the otel collector is an anti-pattern for metrics (ruins active monitoring) and collector's unconventional label use fucks with perf/predictability. worth keeping in mind if you consider using otel agent for metrics.

### [How and Why You Should Adopt and Expose OSS Interfaces Like Otel and Prometheus](https://www.youtube.com/watch?v=D71fK2MFreI)
This one was funny (to me, not actually funny). Google Monarch (their internal monitoring tool) exposing a promql interface so they can translate it to monarch.

lots of work for something people complain about so often (promql). goes to show that the thing people complain about is the thing people actually use.

## Continuous Delivery

### [Flux 2.0 and Beyond; OCI + Cosign](https://www.youtube.com/watch?v=pO2-Kgbkziw)
OCI feels like a better distribution method for Kubernetes yaml than with helm, and flux's `source-controller` pulling oci packaged tarballs has a nice flow to it. OCI + Kustomization sounds workeable.
their selling points:
- colocation of artifacts + images + signatures
- passwordless auth + keyless integrity verification
- increased cd/flux controller efficiency

personally, i just want to distance myself from helm __upgrade/releases__ as much possible and this is a nice + efficient way of doing that.

### [Wolfi: Intro to the Linux Undistro](https://www.youtube.com/watch?v=bXkXu_IKVdI)
wolfi idea remains the same, and they got a lot of momentum behind it and chainguard.
decent build system, but lots of yaml.

### [Keeping Helm Reliable, Stable, and Usable](https://www.youtube.com/watch?v=QhzfJrLo0Vw)
kind of a boring talk, but kept it in here to highlight one point; helm is slowing down because it's the defacto standard.

so do not expect any new major features, WYSIWYG (including gotpl, toYaml | nindent, manual schemas)...

## Security

### [Security Showdown: The Overconfident Operator Vs the Nefarious...](https://www.youtube.com/watch?v=Y1rJY_UlLmM)
entertaining and great talk about problems with wide access on laptops.

### [When Is a Secure Connection Not Encrypted? and Other Stories](https://www.youtube.com/watch?v=5U9h4E0H5RA)
talk about the main working principles behind `cilium` and its mutual encryption.
very interesting wireguard + spiffee setup.
they had a lot of momentum behind them. let's see if that continues after Cisco buys them (i know how that works).

### [Demystifying Cilium: Learn How to Build an eBPF CNI Plugin from Scratch](https://www.youtube.com/watch?v=3cqCmtg-TOo)
while we are on the cilium train. great workshop about how a CNI can be built.

### [Arbitrary Code & File Execution in R/O FS – Am I Write?](https://www.youtube.com/watch?v=jwdz-aYV5xE)
nice exploit demo of `readOnlyRootFileSystem` and ways to bypass the ways it can be enabled.
some truly horrendous and ugly reverse shell setups and `/dev/termination-log` abuse..

### [The Cluster Killer Bug: Learning API Priority and Fairness the Hard Way](https://www.youtube.com/watch?v=4mYUyAeyr-U)
nice intro to flowschemas, apipriority and fairness through a motivating bug example.

An accompanying talk would be [Kubernetes DoS Protection at Google Scale](https://www.youtube.com/watch?v=9TRzfJrU35M).

### [RBACdoors: How Cryptominers Are Exploiting RBAC Misconfigs](https://www.youtube.com/watch?v=PbZbojx4kVM)
hiding techniques for cryptominers if you ever had cluster admin access, and removed it later. decent talk.

## Kubernetes

### [Gateway API: The Most Collaborative API in Kubernetes History Is GA](https://www.youtube.com/watch?v=V3Vu_FWb4l4)
this is a big deal. it's needed to get canaries everywhere with `HTTPRoute`, and it's cool to hear them talk about a mature rollout strategy for experimental crd fields.

tbh, it was more fun to hear this framed as a way to improve `Service`["the worst api in kubernetes"](https://www.youtube.com/watch?v=Oslwx3hj2Eg)

#### [UX Matters: Switching to GAMMA Without Ruining Your Reputation](https://www.youtube.com/watch?v=vMSmLVaVRT0)
- linkerd on working with the __gateway api__ and issues and lessons with policy controller
- presents rust in a way that's "because it's cool" but a bit manual atm. (..i'll take it)
- mentioned their leader election impl and kubert. candid and moderately intersting.

### [Istio Past Present and Future](https://www.youtube.com/watch?v=vu18vpTxX0g)
fun dig at the rust evangelists:
> "rewrite it in rust? [..] no we want to be a lot better"

then talk about their single ambient mesh thing that still ends up with 39% cpu overhead 22% memory overhead.

maybe _they should_ rewrite it in rust.

jkjk. this does seem like a nice improvement for them. ran istio a while back and found the overhead insane.

### [Building Better Controllers](https://www.youtube.com/watch?v=GKPBQDJ2Hjk)
with my kube-rs hat on, there are some cool ideas coming out of istio here (would be nice if they published it).

the ideas here __could__ be partially implement yourself in your code, but it's interesting to see them commit to an interface like this at the controller level.

### [Node Size Matters - Running K8s as Cheaply as Possible](https://www.youtube.com/watch?v=6vNI_O6sdvY)
opencost and their metrics. does a nice investigation into their metrics and proving that __small cloud provider instances are the most expensive instances__ you can use if you can fill your nodes.

### [Cutting Climate Costs with Kubernetes and CAPI](https://www.youtube.com/watch?v=VQbP4XX2O_M)
climate aware scheduler idea using watttime data, priorityclasses and `KubeSchedulerConfiguration` to allow only running workloads during "low emission times".

a later (much fluffier talk) shows [how to integrate this with KEDA](https://www.youtube.com/watch?v=oAvYfIoIgcc)

### [What's up with Kubernetes Long Term Support?](https://www.youtube.com/watch?v=0fngdOlwZtQ)
mentions the numerous recent KEPs to improve stability:
- KEP-1333 - 1.19+ ensures all APIs required to run clusters are GA
- KEP-1693 - New APIs are not allowed to be reqired until they graduate to GA
- 1.19+ has metrics for deprecated resource use
- KEP-1194 - KEPs require better reviews w.r.t. production readiness
- [Deprecation policy](https://kubernetes.io/docs/reference/using-api/deprecation-policy/) updated to make stable api versions permanent
- KEP-3136 - New unstable APIs are OFF by default
- KEP-3744 - Kubernetes 1.23+ use supported go versions (easier to bump security fixes going forward)
- KEP-3935 - Kubernetes 1.28+ control plane nodes support n-3 version skew (annual upgrade now ok)
otherwise talks about difficulties of widening support window too much (upgrade complexity, ecosystem dependencies, bugfix porting)

they want a longer cycle (`WG-LTS`) - because __currently >2/3rds of people have clusters out-of-support__

this feels like a companion talk to [Swimming with the current make it easy to stay up to date](https://www.youtube.com/watch?v=OtigVP3lRh4) which also highlights how much regressions are a problem in Kubernetes (and mostly on patch releases..).

#### [What's New with Kubectl and Kustomize](https://www.youtube.com/watch?v=RggqaCSdOGA)

- `kubectl diff --prune` had a selector bug still...
- `kubectl auth whoami` new

can't help lol when they say you shouldn't use most of the imperative subcommands; {create, run, expose, autoscale, replace, rollout undo, edit, set, patch, scale, ..}

### [Nix Kubernetes and the Pursuit of Reproducibility](https://www.youtube.com/watch?v=U-mSWU4see0)
building a **nix hypervisor** around `libvirt` with qcow2. pretty cool idea.
nice sweetspot for nix in hypervisor space, because talos/flatcar/bottlerocket is probably better for VMs, and wolfi is better for docker images.
### [Pods and Circumstance: CRI-O Graduation Celebration](https://www.youtube.com/watch?v=7MK_Mt7cbrY)
CRI-O metric setups with kubelet/cAdvisor and how they plan to optimize it.

they use [conmon-rs](https://github.com/containers/conmon-rs) - a rust lib for container runtime monitoring!

### [Grifts Ahoy! Bracing for the AI Tide](https://www.youtube.com/watch?v=-Z7TTABw3M0)

advocates for soft-AI as a tool to help generate useful context for small niche areas.

mentions we are likely on the top of the S curve (before the trough of disillusionment) and there's tons of hype and not much focus on risks, tons of exaggerations, whether it's better than non-AI, or whether it even uses AI at all - and it needs some laws.

Mentions a bunch of boring AI risks to consider (not the more crazy AI singularity transhumanist hype):
- hard to control risks when you don't know what the model is actually doing
- research has shown it's very cheap to poison a model (60$ for data control of 0.1% - buying expired domains)
- can be used against us; malware creations (easy to bypass protections by lieing to it)
- deepfakes (passed a liveness test and scammed shanghai tax system)
- ai often hallucinates package names (can typosquat those)

great talk.

### [Declarative Everything](https://www.youtube.com/watch?v=rFaWmd7Y7i0)
My favourite talk about my favourite new feature in Kubernetes. Admission Validation and admission policies.

talked more about it on [mastodon](https://hachyderm.io/@clux/111537982514643915) and ended up writing [kube.rs/admission](https://kube.rs/controllers/admission/) as a result

### [Safeguarding Clusters: Exploring the Benefits and Navigating the dangers of admission controllers](https://www.youtube.com/watch?v=6kK9otYAYac)

goes into details about footguns (`failurePolicy`, latency buildup, default timeout, scope), and some more exotic crazy failures if you accidentally block leases or flowschemas.

notes how it was hard to target negative selections until CEL; matchConditions can be CEL inside webhook configuration resource now!

### [15,000 Minecraft Players Vs One K8s Cluster. Who Wins?](https://www.youtube.com/watch?v=4YNp2vb9NTA)
very good talk about how a cloud minecraft provider moved from GCP to bare metal with "65% cost reduction".

nice to see the stuff they take advantage off (still off-load some stuff to cloud providers), and heavy use of the cluster api.
MinIO and TopoLVM for storage is also very cool.

if nothing else, this talk is worth it for how they deal with lifecycle management of long lived games (how do you terminate the pods?).
short answer; some automatic upgrades with cluster api, some planned maintenances with warnings and then very long `terminationGracePeriodSeconds` on `SIGTERM` with some advanced termination handlers.

### Maintainer Track

### [Tools for Resolving Difficult Conflicts in Open Source Communities and Projects](https://www.youtube.com/watch?v=SNrVqfLotDI)
imo the most useful thing herein is the highlighting of [non-violent communication](https://en.wikipedia.org/wiki/Nonviolent_Communication) as a methodology for __compassionate communication__, proven to have good results (but best if practiced consistently).

### [The Eight Fallacies of Distributed Cloud Native Communities](https://www.youtube.com/watch?v=n2ZHy90PrUQ)
similar maitainer points:
- maintainer bw is (not) infinite :: lack of control + lack of empathy towards you = recipe for burnout
- compromise is (not) a rarity and (not) the norm :: everyone has their own agenda
- cost of contributor onboarding is (not) zero :: maintainer bw is not infinite, ownership also hindered by undocumented context => episodic maintainers leave. need to put concious effort into uplifting and growing existing contributors to avoid gridlock.
- staffing across areas is (not) homogeneous :: some hard areas have very few people who knows what is going on

### [Kubeburned Out? How to get things done efficiently](https://www.youtube.com/watch?v=h-WiiU-iKLQ)

good tips for contributing by making routines for contributions if employed (e.g. 1h before work, maybe every tuesday + thursday, 1-2h during weekend).

make your work public:
- always communicate pr status
- ask for help if stuck
- unasign if you cannot work on it, maybe add snippets that may help others

recognise people for their work;
- blog posts are good
- celebrate small achievements

say no - keep yourself healthy;
- take breaks, short or long

good advice, but then it's more about how to take on more responsibility within kubernetes, writing KEPs, and TAG work.

timing improves success;
- propose things at the right point in time
- raise questions at the right point in time (so you're likely to get the right answer)
- establish an async schedule more likely to get people working together with you

find habits that feel right for you.
if it's not high priority for you or who pays you, don't work on it.
