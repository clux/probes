+++
date = "2021-02-28"
description = "Tower, Hyper, Websockets."
title = "Evolution of kube"
slug = "2021-02-28-kube-evolution"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["rust", "kubernetes"]
+++

After a quarter year of extensive improvements to [kube](https://github.com/clux/kube-rs), it's time to take a birds-eye view of what we got, and showcase some of the recent improvements. After all, it's been about [40 kube releases](https://github.com/clux/kube-rs/releases), one major version of [tokio](https://tokio.rs/), one [extremely prolific new contributor](https://github.com/clux/kube-rs/graphs/contributors), and one [kubecon talk](https://www.youtube.com/watch?v=JmwnRcc2m2A) since my (very outdated) [last blog post](/post/2019-06-04-towards-a-generic-kube-client).

<!--more-->

## Crates
As of `0.51.0`, With modules and crates now delineated better, there's now multiple crates in the repository:

- **kube**: `Api` types, and `Client` library with from a `Config`
- **kube-derive**: proc-macro to derive `CustomResource` necessities from a struct
- **kube-runtime**: stream based controller runtime

Today, we will focus on `kube`.

### kube::Api
Let's start with the basic feature you'd expect from a client library, the **[Api](https://docs.rs/kube/latest/kube/struct.Api.html)**.

Its goals:

- allow interaction with any kubernetes resource
- stay compatible with any struct from [k8s-openapi](https://arnavion.github.io/k8s-openapi/v0.11.x/k8s_openapi/api/index.html)
- defer IO handling to the injected `Client`
- map `Client` output through `serde`


We make this generic by making **two assumptions about kubernetes**:

- all objects have metadata from [apimachinery/meta/types](https://github.com/kubernetes/apimachinery/blob/master/pkg/apis/meta/v1/types.go)
- `client-go` api generation is generics in disguise ([generated api](https://github.com/kubernetes/client-go/tree/6a251876df7908e387143b57eb15bcbd0d6886e0/kubernetes/typed))

We won't cover this now, but you can watch the talk from [KubeCon2020: The Hidden Generics in Kubernetes' API](https://www.youtube.com/watch?v=JmwnRcc2m2A) (or [read the slides](https://clux.github.io/kubecon2020)).

Our `Api` has been remarkably stable over the past year, despite the internals being restructured heavily.

One improvement is to the ergonomics of patching, which now has a [typed Patch enum](https://docs.rs/kube/0.51.0/kube/api/enum.Patch.html) for selecting the patch type.

Despite full support, we always advocate for [server-side apply](https://kubernetes.io/blog/2020/04/01/kubernetes-1.18-feature-server-side-apply-beta-2/) everywhere as a lot of the awkward issues with local patching are generally [swept under the rug](https://github.com/kubernetes/kubernetes/issues/58414) with the clearly superior patch mode present in newer versions of kubernetes.

Here's how patching looks today:

```rust
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let client = Client::try_default().await?;
    let foos: Api<Foo> = Api::namespaced(client, "default");

    let ss_apply = PatchParams::apply("kube").force();
    let patch = serde_json::json!({
        "apiVersion": "clux.dev/v1",
        "kind": "Foo",
        "spec": {
            "name": "foo",
            "replicas": 2
        }
    });
    foos.patch("myfoo", &ss_apply, &Patch::Apply(patch)).await?;
    Ok(())
}
```

The biggest `Api` improvement recently was the inclusion of the most complicated [subresources](https://github.com/clux/kube-rs/blob/master/kube/src/api/subresource.rs): `Api::exec` and `Api::attach`, and these actually uses a different protocol; [websockets](https://github.com/clux/kube-rs/issues/229).

Despite the complexities, these details have ended up being generally invisible to the user; you can hit [Api::exec](https://docs.rs/kube/0.51.0/kube/struct.Api.html#method.exec) like any other method, and you'll get the expected streams you can pipe from and pipe to:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">kube master: optional websocket support for exec/attach with <a href="https://twitter.com/tokio_rs?ref_src=twsrc%5Etfw">@tokio_rs</a> 1.0. Pipe streams to/from k8s pods. <a href="https://t.co/WhSFlPmm60">pic.twitter.com/WhSFlPmm60</a></p>&mdash; eirik ᐸ&#39;aᐳ (@sszynrae) <a href="https://twitter.com/sszynrae/status/1346122892707319810?ref_src=twsrc%5Etfw">January 4, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

### kube::Config
Not to be confused with the file in your home directory, our [Config](https://docs.rs/kube/latest/kube/struct.Config.html) is actually just the relevant parameters we extract from the [kubeconfig file](https://docs.rs/kube/latest/kube/config/struct.Kubeconfig.html) (or [cluster evars](https://docs.rs/kube/latest/kube/struct.Config.html#method.from_cluster_env) when in-cluster), to help us create a `Client`.

You generally won't need to instantiate any of these though, nor do you need a `Config` (as shown above), because [Client::try_default](https://docs.rs/kube/0.51.0/kube/struct.Client.html#method.try_default) will infer the correct one.

Recent updates to stay compatible with the different config variants which `kubectl` supports, means we now support [stacked kubeconfigs](https://github.com/clux/kube-rs/issues/132), and [multi-document kubeconfigs](https://github.com/clux/kube-rs/issues/440).


### kube::Client
One of the most updated parts of `kube` this year, the [`Client`](https://docs.rs/kube/latest/kube/struct.Client.html) has undergone significant surgery.
It is now entirely concerned with the __protocol__, and handles the serialization plumbing between the `Api` and the apiserver.

Many improvements are only really appreciable internally;

- __watch__ buffering is now using a [tokio codec](https://docs.rs/tokio-util/0.6.3/tokio_util/codec/index.html) to give us a much more readable [streaming event parser](https://docs.rs/kube/0.51.0/src/kube/client/mod.rs.html#204-272), while still returning a `TryStream<Item = Result<WatchEvent<T>>>` for `Api::watch`

- [Client::connect](https://docs.rs/kube/0.51.0/kube/struct.Client.html#method.connect) added to give a way to [hyper::upgrade](https://docs.rs/hyper/0.14.4/hyper/upgrade/index.html) an existing `http` connection ([wtf is upgrading?](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade)) to grant a streaming websocket connection from the existing http library. This is the secret sauce behind `Api::exec`.

Websockets is using `tokio-tungstenite`, a dependency so light-weight it's [only pulling](https://github.com/snapview/tokio-tungstenite/blob/master/Cargo.toml) in `tungstenite` without its [default-features](https://github.com/snapview/tungstenite-rs/blob/master/Cargo.toml). Crucially, this lets us avoid having yet another way to specify tls stacks and cause a corresponding explosion of features ([weak-dep-features](https://github.com/rust-lang/cargo/issues/8832) plz).

Of course, supporting multiple protocols, tls stacks, and certs from kubeconfigs means that there's considerable tls handling in kube. Fortunately, we have mostly managed to confine it to [one cursed file](https://github.com/clux/kube-rs/blob/11f60c7c5e793a6badc6f8bf3792c0a4e80a500d/kube/src/service/tls.rs).

..And if websocket support was not enough:

> Every api call now goes through [Client::send](https://docs.rs/kube/0.51.0/src/kube/client/mod.rs.html#70-91)'s new Service, rather than `reqwest::send`, and we no longer depend on `reqwest`.

### kube::Service
The new [Service](https://docs.rs/kube/0.51.0/kube/struct.Service.html) - injected into the `Client`, and constructed from an [arbitrary](https://docs.rs/kube/0.51.0/src/kube/config/mod.rs.html#51-62) `Config` - is what actually deals with the processing of the request call to turn it into a response.

The `Service` creates a series of ordered [__layers__](https://docs.rs/kube/0.51.0/src/kube/service/mod.rs.html#71-125) to be executed for each request:

1. Authentication (extracting tokens, possibly talking to auth providers)
2. Url + header mapping from Config to http request
3. Dealing with optional compression
4. Send it to a `HyperClient` configured with a `Connector`

The connector for `hyper` deals with TLS stack selection + Timeouts + [proxying](https://github.com/clux/kube-rs/pull/438)

__Why this abstraction?__ Well, primarily, less entangling business logic with IO ([Sans-IO](https://sans-io.readthedocs.io/) goals), and **[tower](https://docs.rs/tower-service/0.3.1/tower_service/trait.Service.html)** provides a robust way to move in that direction.

There's also code-reuse of [common service layers](https://docs.rs/tower/0.4.6/tower/#modules) (effectively middleware), as well as the ability to [mock services out of the box](https://docs.rs/tower-test/0.4.0/tower_test/macro.assert_request_eq.html), something that will help create a [better mocking setup](https://github.com/clux/kube-rs/issues/429#issuecomment-782957601) down the line.

For now, however, the end result is a more light-weight http client: **[hyper](https://github.com/hyperium/hyper#hyper)** over `reqwest`, and without changing the core api boundaries (inserting `Service` between `Client` and `Config` will not affect the vast majority of users who use `Client::try_default` as the main start point).

### Credits
If you looked at the [contributors graph](https://github.com/clux/kube-rs/graphs/contributors), you'll see we have a new maintainer.

How did their contributions spike so quickly? Well, check out the prs for [tower + hyper rearchitecture](https://github.com/clux/kube-rs/pull/394), and [websocket support](https://github.com/clux/kube-rs/pull/360). Imagine landing those hugely ambitious beasts _so quickly_, and still managing to [merge 20+ more prs since january](https://github.com/clux/kube-rs/pulls?q=is%3Apr+is%3Aclosed+author%3Akazk) 🤯

_...So_, having mostly _project-managered_ the ship the past **two months**, it's important to give due [credit](https://github.com/clux/kube-rs/pull/411#issuecomment-777086158) while we appreciate how far we've come. Huge thanks to [kazk](https://github.com/kazk).

In fact, from the [client capabilities document](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/api-machinery/csi-new-client-library-procedure.md#client-capabilities), we are [almost](https://github.com/clux/kube-rs/issues?q=is%3Aissue+is%3Aopen+label%3Aclient-gold) at <img style="display:inline" alt="client gold" src="https://img.shields.io/badge/Kubernetes%20client-Gold-blue.svg?style=plastic&colorB=FFD700&colorA=306CE8"/>.

## End
TL;DR: A lot has happened. We have dissected parts of `kube`.

As a kind of __conclusion__, I would just like to note __how much easier__ these complex problems are to tackle in rust now thanks to **[tokio.rs](https://tokio.rs/#tk-lib-tokio)**. The ecosystem is fantastic now.

## Future Addendum
Some key kube related issues that I personally hope will be resolved in 2021:

- [ergonomics / utils](https://github.com/clux/kube-rs/issues/428)
- [testing / mocking](https://github.com/clux/kube-rs/issues/429)
- [tracing story](https://github.com/clux/kube-rs/discussions/423)
- dyn api [improvements](https://github.com/clux/kube-rs/pull/385)
- [less Options in generated types](https://github.com/Arnavion/k8s-openapi/issues/72)

Without being able to give any guarantees. Volunteer work, you know.

Speaking of; **[help](https://github.com/clux/kube-rs/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22) is instrumental** for moving things forward, and always appreciated. Even if you are just fixing [docs](https://docs.rs/kube/latest/kube/) / [examples](https://github.com/clux/kube-rs/tree/master/examples) or asking questions.

Check our [discussions](https://github.com/clux/kube-rs/discussions/422), the [tokio discord](https://discord.gg/tokio), or the [issues](https://github.com/clux/kube-rs/issues) if interested. Take care ✨🤗
