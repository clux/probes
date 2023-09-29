+++
date = "2018-12-15"
description = "Building a microservice YAML api for kubernetes in 2018"
title = "shipcat retrospective"
updated = "2023-09-28"

[extra]
toc = false

[taxonomies]
categories = ["software"]
tags = ["rust", "kubernetes"]
+++

The now defunct unicorn startup [babylon health](https://www.babylonhealth.com/) needed to micrate about 50 microservices to Kubernetes in early 2018. At Kubernetes 1.8, supporting tooling was weak, and deadlines were quick.

This is an historically updated post about [`shipcat`](https://github.com/clux/shipcat), a standardisation tool written to control the declarative format and lifecycle of every microservice, and get safety quickly.

<!--more-->

> NOTE: After babylon's demise in 2023 this post has been updated to serve as a kind of mini-retrospective. Mostly, it's just an edit of the original post that adds some historical clarification of why this weird tool was written.

First, a bit about the problem:

## Kubernetes API

Migrating to Kubernetes was a non-trivial task for a DevOps team, when the requirements where basically that __we would do it for the engineers__. We had to standardise, and we had to decide on what a __microservice__ ought to look like based on what was already there.

We didn't want engineers to have to learn everything about the following objects at once:

- `ConfigMap`
- `Secrets`
- `Deployment` / `ReplicaSet` / `Pod`
- `Service`
- `HorizontalPodAutoscaler`
- `ServiceAccount`
- `Role`
- `RoleBinding`
- `Ingress`

We needed validation. Admission control was new, didn't work well with gitops for fast client-side validation, and we just needed ci checks to prevent `master` from being broken.

## Helm
One of the main abstraction attempts kubernetes has seen in this space is `helm`. A client side templating system (ignoring the bad server side part) that lets you abstract away much of the above into `charts` (a collection of `yaml` go templates) ready to be filled in with `helm values`; the more concise `yaml` that developers write directly.

Simplistic usage of `helm` would involve having a `charts` folder:

```sh
charts
└── base
    ├── Chart.yaml
    ├── templates
    │   ├── configmap.yamls
    │   ├── deployment.yaml
    │   ├── hpa.yaml
    │   ├── rbac.yaml
    │   ├── secrets.yaml
    │   ├── serviceaccount.yaml
    │   └── service.yaml
    └── values.yaml
```

and calling it with your substitute `myvalues.yaml`:

```sh
helm template charts/base myapp -f myvalues.yaml | \
    kubectl apply -lapp=myapp --prune -f -
```

which will garbage collect older kube resources with the `myapp` label, and start any necessary rolling upgrades in kubernetes.

### Drawbacks
Even though you can avoid a lot of the common errors by re-using charts across apps, there were still very little sanity on what helm values could contain. Here are some values you could pass through a helm chart to kubernetes and still be accepted:

- misspelled optional values (silently ignored)
- resource requests exceeding largest node (cannot schedule nor vertically auto scale)
- resource requests > resource limits (illogical)
- out of date secrets (generally causing crashes)
- missing health checks / `readinessProbe` (broken services can rollout)
- images and versions that does not exist (fails to install/upgrade)

And that's once you've gotten over how frurstrating it can be to write helm templates in the first place.

## Limitations
While validation is a fixable annoyance, a bigger observation is that these helm values files become a really interesting, but entirely **accidental abstraction**. These files become the canonical representation of your services, but you have no useful logic around it. You have very little validation, almost no definition of what's allowed in there (`helm lint` is lackluster), you have no process of standardisation, it's hard to test sprawling automation scripts around the values files, and you do not have any sane way of evolving these charts.

## Enter shipcat
[![shipcat logo](https://github.com/clux/shipcat/raw/master/logo/shipcat_logo.png)](https://github.com/clux/shipcat)

What if if we could take the general idea that developers just write simplified _yaml manifests_ for their app, but we actually **define** that API instead? By actually defining the structs we can provide a bunch of security checking and validation on top of it, and we will have a well-defined boundary for automation / ci / dev tools.

By defining all our syntax in a library we can have cli tools for automation, and executables running as kubernetes operators using the same definitions. It effectively provides a way to versioning the platform.

This also allowed us to solve a _secrets_ problem. We extended the manifests with syntax that allows synchronsing secrets from [Vault](https://www.hashicorp.com/products/vault/) at both deploy and validation time. There are better solutions for this now, but we needed something quickly.

## Disclaimer
This style of tool was not a revolutionary (nor clean) idea. At KubeCon Eu 2018 pretty much everyone had their own wrappers around `yaml` to help with these problems. Some common examples: `kubecfg`, `ksonnet`, `flux`, `helmfile`, which all try to help out in this space, but they were all missing most of the sanity we required when we started experimenting.

Note that this was our first take on adding Kubernetes validation in a world where gitops was in its infancy.

The result is __babylon dependent__; it was heavily evolving and not general purpose.


## Manifests
The user interaface we settled on were service-level manifests:

```yaml
name: webapp
image: clux/webapp-rs
version: 0.2.0
env:
  DATABASE_URL: IN_VAULT
resources:
  requests:
    cpu: 100m
    memory: 100Mi
  limits:
    cpu: 300m
    memory: 300Mi
replicaCount: 2
health:
  uri: /health
httpPort: 8000
regions:
- minikube
metadata:
  contacts:
  - name: "Eirik"
    slack: "@clux"
  team: Doves
  repo: https://github.com/clux/webapp-rs
```

This encapsulates the most important kube apis that developers should configure themselves, who's responsible for it, what regions it's deployed in, what secrets are needed (notice the `IN_VAULT` marker), and how resource intensive it is.

## Strict Syntax
Because these manifests were going to be the entry point for CI pipelines and handle platform specific validation (for medical software), we wanted maximum strictness everywhere and that includes the ability to catch errors before manifests are committed to `master`.

We leant heavily on [serde's customisable codegeneration](https://serde.rs/attributes.html) to encapsulate awkward k8s apis, and to auto-generate the boilerplate validation around types and spelling errors.

The Kubernetes structs were __handrolled__ for the most part, but later incorporated parts of `k8s-openapi` structs - however these were too `Option`-heavy to catch most missed-out fields on their own.

Here are some structs we used to ensure `resources` and `limits` had the right format:

```rust
/// Kubernetes resource requests or limit
#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(deny_unknown_fields)]
pub struct Resources<T> {
    /// CPU request string
    pub cpu: T,
    /// Memory request string
    pub memory: T,
    // TODO: ephemeral-storage + extended-resources
}

/// Kubernetes resources
#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(deny_unknown_fields)]
pub struct ResourceRequirements<T> {
    /// Resource requests for k8s
    pub requests: Resources<T>,
    /// Resource limits for k8s
    pub limits: Resources<T>,
}
```

Here, `serde` enforces the "schema" validation. It catches spelling-errors as extraneous types/keys due to the `#[serde(deny_unknown_fields)]` instruction, and it enforces the correct types. But on the flip side, having this in code also required us updating the spec (to say, support ephemeral storage requirements).

Still, this provided cheap schema validation (before helm got it) and there was also a `verify` method that every struct could implement. This genenrally encapsulated common mistakes that were clearly errors and should be caught before they are sent out to the clusters:

```rust
impl ResourceRequirements<String> {
    // TODO: look at cluster config for limits?
    pub fn verify(&self) -> Result<()> {
        // (We can unwrap all the values as we assume implicit called!)
        let n = self.normalised()?;
        let req = &n.requests;
        let lim = &n.limits;

        // 1.1 limits >= requests
        if req.cpu > lim.cpu {
            bail!("Requested more CPU than what was limited");
        }
        if req.memory > lim.memory {
            bail!("Requested more memory than what was limited");
        }
        // 1.2 sanity numbers (based on c5.9xlarge)
        if req.cpu > 36.0 {
            bail!("Requested more than 36 cores");
        }
        if req.memory > 72.0 * 1024.0 * 1024.0 * 1024.0 {
            bail!("Requested more than 72 GB of memory");
        }
        if lim.cpu > 36.0 {
            bail!("CPU limit set to more than 36 cores");
        }
        if lim.memory > 72.0 * 1024.0 * 1024.0 * 1024.0 {
            bail!("Memory limit set to more than 72 GB of memory");
        }
        Ok(())
    }
}
```

Ultimately, the `Resources` struct above was attached straight onto to the core `Manifest` struct (representing the microservice defn above). Devs would write standard resources and be generally unaware of the constraints until they were violated:


```yaml
resources:
  requests:
    cpu: 100m
    memory: 100Mi
  limits:
    cpu: 300m
    memory: 300Mi
```


In this case, the syntax matches the Kubernetes API directly - and this was preferred - but had extra validation.

We did plan on moving validation to a more declarative format (like [OPAs](https://www.openpolicyagent.org/)) down the line, but there was no rush; this worked.

All of the syntax ended up in [shipcat/structs](https://github.com/clux/shipcat/tree/master/shipcat_definitions/src) - and required developer code-review to modify since it could affect the whole platform.

Once a new version of `shipcat` was released, we bumped a pin for it in a [configuration management monorepo with all the manifests](https://github.com/clux/shipcat/blob/master/examples), and the new syntax + feature become available for the whole company.

## CLI Usage
Developers could check that their manifests pass validation rules locally, or wait for pre-merge validation on CI:

```sh
shipcat validate myapp # lint
shipcat template myapp # generate template output
```

the last being roughly equivalent to:

```sh
shipcat values myapp | helm template charts/base
```

We did always lean on helm charts for templating yaml, but this was always an implementation detail that only a handful of engineers needed to touch as we followed the [one chart to rule them all approach](https://www.youtube.com/watch?v=HzJ9ycX1h0c). Templates were also linted heavily with [`kubeval`](https://github.com/garethr/kubeva) against all services in all regions during chart upgrades.

## Kubernetes Usage
We had wrappers around the normal `shipcat template myapp | kubectl X` pipeline

```sh
shipcat diff myapp # diff templated yaml against current cluster
shipcat apply myapp # kubectl apply the template - providing a diff and a progress bar
```

The upgrade was much nicer than any other CLI that existed at the time, it [tracked upgrades with deployment-replica progress bars](https://github.com/clux/shipcat/blob/669bbb8408ea5b3c93582774b021aebb12c2a970/shipcat_cli/src/track.rs#L415-L508), [bubbled up errors, captured error logs](https://github.com/clux/shipcat/blob/669bbb8408ea5b3c93582774b021aebb12c2a970/shipcat_cli/src/apply.rs#L312-L335), [provided inline diffs pre-upgrade](https://github.com/clux/shipcat/blob/669bbb8408ea5b3c93582774b021aebb12c2a970/shipcat_cli/src/apply.rs#L262-L291), gated on validation, sent [successful rollout notifications](https://github.com/clux/shipcat/blob/669bbb8408ea5b3c93582774b021aebb12c2a970/shipcat_cli/src/slack.rs#L138-L255) to maintainers on slack.

> This was imo its biggest selling point (and possibly prevented a revolt against a ops-led mandated tool). In my later jobs, achieving the same would take multiple microservices talking to flux.

CI actually reconciled the whole cluster in parallel using rayon (and later tokio):

```sh
shipcat cluster helm reconcile
```

this help avoid the numerous tiller bugs and actually let us define a sensible amount of time to wait for a deployment to complete (there's an [algorithm in there for it](https://github.com/clux/shipcat/blob/669bbb8408ea5b3c93582774b021aebb12c2a970/shipcat_definitions/src/math.rs#L79-L109)).

> at the time [helm 3 was planning to architect away tiller entirely](https://github.com/helm/community/blob/master/helm-v3/000-helm-v3.md).

In the end, we almost turned it into a CD controller, but in an awkward clash of new and old tech, we just ran the above reconcile command on jenkins every 5m lol.


## Conclusion

Looking back at this, it's a kind of wild everything-CLI. It accomplished the goal though. It moved fast, but did so safely. It was not universally well-received, but most of the people who complained about it early on later came to me later to say "i don't know how else we could have done this".

It also let us build a quick and simple service-registry on top of the service spec (there's a controller called [raftcat](https://github.com/clux/shipcat/tree/master/raftcat) that cross-linked to all the tools we used for each service).

Not unsurprisingly, how tied-in it was to the babylon platform effectively became its demise.
While [shipcat was open source](https://github.com/babylonhealth/shipcat), it was silently un-opensourced in 2022 without much ceremony, and now only my [safety fork](https://github.com/clux/shipcat) remains. We can say similar things about the [company](https://techcrunch.com/2023/08/31/the-fall-of-babylon-failed-tele-health-startup-once-valued-at-nearly-2b-goes-bankrupt-and-sold-for-parts/) and the value of my shares.

There's also our original talk: [Babylon Health - Leveraging Kubernetes for global scale](https://www.youtube.com/watch?v=FvKQP7Qnfuc) from DoxLon2018 that provides some context. Don't make me watch it again though.
