+++
date = "2021-11-06"
description = "Notes from a week of pandemic browsing CNCF youtube"
title = "Talk log from KubeCon LA"
slug = "2021-11-06-kubecon-la-log"

[extra]

[taxonomies]
categories = ["software"]
tags = ["rust", "kubernetes"]
+++

First KubeCon in a while I haven't done anything for (didn't even buy an ticket). This post is largely for myself, but thought I'd put some thoughts here public. All talks referenced were recently published on the [CNCF youtube channel](https://www.youtube.com/c/cloudnativefdn/videos), and the posts here are really just my notes (make of them what you will).

My interest areas this kubecon fall broadly into these categories;

- **observability related** :: maintain a lot of metrics related tooling + do a lot of dev advocacy
- **community related** :: am trying to [donate kube-rs to cncf](https://github.com/kube-rs/kube-rs/issues/584) and grow that community
- **misc tech** :: engineer likes shiny things

sorted in order of interest (grouped by category):

## Observability

### [Using SLOs for Continuous Performance Optimizations](https://www.youtube.com/watch?v=V4ByBVARjkc)
[keptn](https://keptn.sh/) and its evented automation system does seem really good.
treats SLOs as first class things. higher level abstraction than other CD systems. no need to write automation systems..
pretty new (cncf sandbox). [I should try it](https://keptn.sh/docs/0.9.x/operate/advanced_install_options/).

**[Keptn Office Hours](https://www.youtube.com/watch?v=WVRdF0ZvApw)** also goes into a lot of details here for this.

### [Evolving Prometheus for More Use Cases](https://www.youtube.com/watch?v=5R6Fy21MXVE)
[Bartek](https://twitter.com/bwplotka) on latest news:
- New config: `sample_limit` (body limit) + `label_limit` (num labels) + `label_name_length_limit` (label len) + `target_limit` (per-scrape config limit).
- Configure scraping by labels e.g. `prometheus.io/scrape`.
- Exemplars with OpenMetrics format. Supported in java/golang/python. (NB: I closed [my rust pr](https://github.com/tikv/rust-prometheus/pull/395) due to time constraints / lack of support)

Thanos remote-read to help federated setups. Via [G-Research](https://github.com/G-Research/thanos-remote-read).
But `remote_write` more popular. Can set prometheus to only `remote_write` recording rule results!

- Prometheus Agent based on Grafana Agent ([contributed by them](https://github.com/prometheus/prometheus/pull/8785)) (better disk usage, DS mode presumably).
- Grafana Operator; dashboards as CRDs (can split configmap monorepo that normally uses sidecars)
- [prom-label-proxy](https://github.com/prometheus-community/prom-label-proxy): isolation. each team only sees their own metrics + resources.

Upcoming: ingestion scaling automation; HPA scaling scraping via dynamically assign scrape targets. High density histograms.

### [What You Need to Know About OpenMetrics](https://www.youtube.com/watch?v=MMfmNpoYAec)
prometheus + its exposition format is a global standard. Now big collaboration on new standard.

largely the same; but some cleanups and new features.
- counters require `_total` suffix, timestamp unit is in seconds (used to be ms)
- added metadata (units in scrapes), exemplar support
- (minor breaking changes, opt in with header)
- push/pull considerations (cannot emulate all of pull with push though)
- text format mandatory / optional protobuf
- python client is the reference impl (also go/java)

prometheus conformance program (vendors need to do things to get "Prometheus Compliant" logo) [separate talk](https://www.youtube.com/watch?v=N_OkWRC-xQU):
- to use the mark (for a period of time) have to sign LF paperwork
- includes: good faith testing clauses, submit tests to prom team
- monetary incentives - because they plan on iterating on test suite quickly

### [EBF Superpowers](https://www.youtube.com/watch?v=KY5qujcujfI)
- [cilium hubble](https://github.com/cilium/hubble) works as a CNI and can help visualise traffic
- falco can detect syscalls
- [pixie](https://pixielabs.ai/) can show flamegraphs within containers

> "observability / networking sidecars needs yaml, but ebpf is kernel level."

linkerd people go into limitation of ebpf as a "mesh" in this thread:
<!--< tweet user="wm" id="1453492551579836417" >-->
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Was a little bummed to see this article earlier this week from some people I respect, which promotes things that I I believe are *not* the future of cloud native security. <a href="https://t.co/U1kdID4NIA">https://t.co/U1kdID4NIA</a></p>&mdash; William Morgan (@wm) <a href="https://twitter.com/wm/status/1453492551579836417?ref_src=twsrc%5Etfw">October 27, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


similar overview to rakyll's [eBPF in Microservices Observability](https://www.youtube.com/watch?v=SKLA6n3TKL0), which additionally notes the distribution problem with ebpf at the end.

### [Understanding Service Mesh Metric Merging](https://www.youtube.com/watch?v=1KG3wFb6mU0)
How scraping works with istio (to ensure you get app + proxy) from meshday. Awkward, but ok.


### [Effortless Profiling on Kubernetes](https://www.youtube.com/watch?v=VPN-q2rjhxc)
`kubectl flame` - creating a container on the same node as target container with profiler binaries (sharing process ids + ns and fs).
=> can use capturing tools like `py-spy`/`async-profiler` to capture flamegraphs without touching running containers
it then runs kubectl cp's the thing out to disk and cleans up thing (no rust support though)

might be obsolete / rewritten with `ephemeralContainers` (no need find node and grab ps/ns/fs stuff)
[prodfiler](https://prodfiler.com/) does something similar as a service


## Misc Tech

### [Leveraging WebAssembly to Write Kubernetes Admission Policies](https://www.youtube.com/watch?v=oNJxPbvPzLk)
[Kubewarden](https://www.kubewarden.io/)! Rust dynamic admission controller using `kube-rs` with WASM.
No DLS. OCI registry to publish policies. Runs all of them through the policy server.
- Tracing support into policy wasms!
- CRD now for policies: `module` (oci path) + rbac + constraints.
- `opa build -t wasm` wasmify via `opa`
- testing: `kwctl run -e gatekeeper ---settings-json '{...}' --request-path some.json gatekeeper/policy.wasa`

Should test this out properly. Looks like less of a hassle than OPA/gatekeeper.

### [Edge Computing using K3s on Raspberry Pi](https://www.youtube.com/watch?v=BgzQYlxYOmE)
nice up to date tutorial to look into in case of apocalypse.

### [Allocation Optimizer for Minimizing Power Consumption](https://www.youtube.com/watch?v=TXa1lj7FIZA)
using science on cpu power usage based on cpu utilization %.

### [Shifting Spotify from Spreadsheets to Backstage](https://www.youtube.com/watch?v=lCgDiusuixM)
great service catalog. tons of plugins. costs. trigger incidents.
probably better than opslevel? but backstage needs to be in-cluster.
also wants to do things that `keptn` wants to do.

### [Building Catalogs of Operators for OLM the Declarative Way](https://www.youtube.com/watch?v=3_MnWTuuMN8)
OLM craziness on top of controllers. `opm` serves a registry of controllers in a catalog...

### [Faster Container Image Distribution](https://www.youtube.com/watch?v=K2VlZE7lDjI)
tared image distribution problematic coz you have to download all of it. so two new systems:

- `eStargz`: extension to OCI (backwards compat) - subproject of containerd
- looks like 20-40% of pull speeds of original
- can enable with `k3s server --snapshotter=stargz` (but need lazy pull enabled images)
- can buildkit build using `buildx build -o type=registry,name=org/repo:tag,oci-mediatypes=true,compression=estargz`
- also ways to convert images nerdctl ord ctr-remote
- [opencontainers/image-spec#815](https://github.com/opencontainers/image-spec/issues/815)

and

- `nydus` - future looking (incubator dragonfly sub-project)
- next OCI image spec propoasal
- improved lazy pulling, better ecosystem integration
- benchmarks looks better than estargz?
- harbor with auto-conversion

### [What We Learned from Reading 100+ Kubernetes Post-Mortems](https://www.youtube.com/watch?v=Bxnu3llBN20)
nice quick failure stories
- cronjob `concurrencyPolicy: Forbid` otherwise crashing causing pod duplication "fork bombs"
- incorrect yaml placements discards bad yaml on bad CI
- ingress: no `*` in `rules[].host`
- pods: no limits on 3rd party image -> took down cluster when it memory leaked

TL;DR: use good validation and good CD.

## Community Related

### [From Storming to Performing: Growing Your Project's Contributor Experience](https://www.youtube.com/watch?v=yhlDYCdwg7I)
matt butcher. 4 stages on how they apply to OS:

- **FORM**: deal with prs positively / identity / website / branding / communications / twitter (think early) / maintainer guide docs
- **STORM**: conflicts (dispute resolution / CoC / Governance / coding standards / contributors != employees (ask + thank)
- **NORM**: sharing responsibilities (issue mgmt / triage / delegate (find volunteers) / standardising communication channels)
- **PERFORM**: optimising for long haul (retaining maintainers / burnout / turnover / acquire new maintainers)

at all stages; people are still volunteers, be kind, thank them, give them something (responsibility / status) if possible
sometimes people need to step down. steps are not hard-delineated

- **adjourning** could be the last step (nothing more to really do?)

triage maintainer could be a good idea.

### [Kubernetes SIG CLI: Intro and Updates](https://www.youtube.com/watch?v=2o7WDLiXrW4)
**scope:** standardisation of cli framework / posix compliance / conventions - owns kubectl kui, cli-runtime cli-experimental cli-utils, krew kustomize
- they are conceding that `apply --prune` is awful and has drawbacks. (alpha and probably won't ever graduate). cli-utils has experiments for improvements.
- all stuff use cobra (want to remove that) - want to pull apply into something people can use (so can use their stuff as library)
- `kubectl` has many imperative things (like kubectl create - hard to maintain)
- `kubectl` is bad on performance - too much serialization (json -> yaml -> json -> go structs ...) go is strictly typed without generics. memory usage balloons.
- "kubectl is a very difficult codebase to work on" -_-


### [Measuring the Health of Your CNCF Project](https://www.youtube.com/watch?v=iO14TVtIemk)
Via [CNCF project-health](https://contribute.cncf.io/maintainers/community/project-health/) and [devstats cncf dashboards](https://all.devstats.cncf.io/d/8/dashboards?orgId=1&refresh=15m). Project health metrics:

- **Responsiveness** (more likely to retain contributors)
  * First Response time on PRs (1 hour good, 3 days bad)
  * Resolution (time to close - dislike this - autoclose bot)
- **Contributor Activity** (community toxic? clear contribution policies makes it easier for new/episodic contribs)
  * Contributor activity
  * Contributors new and episodic (shows growth of contributors)
- **Contributor Risk** (low risk; many contributors, org diversity)
- **Project Velocity** (decrease => maturity or health issues)
- **Release Activity** (regular cadence improves trust, quick security response)
- **Inclusivity** (inclusive / welcoming porjects attract + retain diverse contributors)
  * mentoring programs?
Timeframe? Can run sensibly if you have a regular release cadence, otherwise have to pick a time frame.
They have dashboards.

### [Turn Contributors Into Maintainers with TAG Contributor Strategy](https://www.youtube.com/watch?v=dI8Ti3ruvuo)
produces [templates](https://github.com/cncf/project-template), guide for governance (already used it!)
- descriptive helps. goals need to align.
- clarify what to do when making a PR - minimize manual steps
- thank people, recognition programs (in releases), create a warming community
- get people on the contribution ladder. linkerd has a linkerd hero. define the ladder (gamifies the task).
- maintainers value code and are biased towards that. need people that have other skills. need someone to help with docs?
- they have a [contributor ladder](https://github.com/cncf/project-template/blob/main/CONTRIBUTOR_LADDER.md)
- governance == membership. people want to belong to something. proves to them that they are treated equally, and htey have ownership.
- corporate contributors are shown they won't be railroaded. investment ~~ influence.

### [Design Up Front: Socializing Ideas with Enhancement Proposals](https://www.youtube.com/watch?v=XfRmvW48PHw)
On enhancement proposals / RFCs. key takeaways were good:
- taking time to communicate your ideas clearly and getting feedback / responding to that feedback makes your ideas better and makes you grow as an engineer.
- helps improve stability, but can be intimidating.
- need to invest in it, and follow up on reviewers and contributors.
- the system dies if you don't.

### [CNCF Technical Oversight at Scale](https://www.youtube.com/watch?v=T_ebn2qK95E)
creates TAGS (technical advisory groups). help cncf projects incubate/graduate.

- we might be in the runtime tag; https://github.com/cncf/tag-runtime

- cncf project updates talk: crossplane/keda/cilium/flux/opentelemetry incubating
- flux uses ss apply, drift detection, stable apis (although their [GA Roadmap talk](https://www.youtube.com/watch?v=8RFxYooMc5A) had just docs/test/standardisation stuff)
- prometheus high res histograms
- [keda](https://keda.sh/): **e**vent **d**riven **a**utoscaler: listens to eventing systems -> translates to metrics -> turns it into cpu/memory metrics "tricking the system"

### [Technical Oversight Committee](https://www.youtube.com/watch?v=6H6QIxAjVvU)
a public meeting. interesting just to get an overview of its goals. good links and reasonable goals (discussion was ok):
- https://github.com/cncf/toc/blob/main/PRINCIPLES.md
- https://github.com/cncf/toc/blob/main/process/sandbox.md
- https://github.com/cncf/tag-runtime (our target TAG)


### [CNCF Tag-Runtime](https://www.youtube.com/watch?v=Fjytrt5M7jg)
Useful because it's the TAG that seems likely for kube-rs donation. dims is a liaison!
- Scope areas limited so far, but "open to expanding".
- Contains: `krustlet` + `Akri`

### [Kubernetes SIG Docs](https://www.youtube.com/watch?v=GDfcBF5et3Q)
....is apprently mostly hugo + netlify. they have a contributor role of a PR wrangler (and rotate that).

## Miscellaneous Notes

- [PSPs are going away](https://kubernetes.io/blog/2021/04/06/podsecuritypolicy-deprecation-past-present-and-future/)
- "webassembly; neither web nor assembly"
- `kustomize` still a thing.. now with generators + transformer pipelines via crds..
- [sieve-project](https://github.com/sieve-project/sieve) (from talk on [kubernetes controller testing]((https://www.youtube.com/watch?v=6JnhjgOaZVk))) is interesting, but kind of insane sounding - hope we can make this nicer in kube..
- [people using linkerd](https://www.youtube.com/watch?v=PKhQXjb6cB4) to solve the grpc load balancing problem
