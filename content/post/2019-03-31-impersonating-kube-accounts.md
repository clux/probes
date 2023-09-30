+++
date = "2019-03-31"
description = "Bypassing complicated kubernetes identity providers"
title = "Impersonating kube service accounts"
slug = "2019-03-31-impersonating-kube-accounts"

[extra]
toc = true

[taxonomies]
categories = ["software"]
tags = ["bash", "kubernetes"]
+++

Authenticating with large kubernetes clusters often risks you dealing with complicated provider logic and sometimes policies outside your control.

While controllers and operators authenticate with service accounts directly, this is only true inside the cluster. That is, unless you can impersonate the service account from outside.

<!--more-->

**EDIT:** as of Kubernetes 1.24 the bypass method **no longer works**.

..but why would you need to do this?

### 1. Testing service account access
If you have a way to quickly impersonate a service account you can tell if your [rbac verbs, resources](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are correct and were slash separated in the way kube expects.

As an example, to allow shell access into pods, you must grant `create` on `pods/exec` in the empty api group (`""`)

```yaml
- apiGroups: [""]
  resources:
  - pods/exec
  verbs: ["create"]
```

It's safe to say that the groups and resource names are often less than intuitive, and it doesn't help that there is very lackluster errors when applying policies.

### 2. kubectl is better than your language-x client
Having your app deal with oidc providers is an unnecessary pain point / code path when your app is meant to live in the cluster and authenticate with a service account anyway.

Even if the language you're writing in is [one of the supposedly supported languages](https://kubernetes.io/docs/reference/using-api/client-libraries/), [your mileage may vary if it's not Go](https://github.com/kubernetes-client/python/issues/628). Even [post 1.11, it's still beta in go](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins).

### 3. service accounts can function as group auth
Not saying you shouldn't have single sign on hooked up to kube, but if you are lacking a good solution at the moment, a few targetted developer accounts with actual rbac policies attached to them is an actual, revokeable solution (as opposed to handing over admin tokens).

It does not provide as clean of an audit trail, but if you just want to give read only access to pods, logs, deployments, you might not care.

## Impersonation
There are currently two main ways of doing this. The new, limited-use-case way, and the old yaml wrangling method.

### Rbac controlled
These days, [kubectl supports user-impersonation](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation), so if you're just testing access you can use `kubectl <verb> <resource> --as=jenkins`, provided your user has the `impersonate` verb set where you need it to:

```yaml
- apiGroups: [""]
  resources: ["users", "groups", "serviceaccounts"]
  verbs: ["impersonate"]
```

However, this doesn't solve problem 2 or 3 listed above.

### Manual impersonation
This method extracts the credentials from a service account and adds them as extra entries in your `~/.kube/config`. This way most language clients should be able to handle them, and you can have an unobtrusive new context to test.

The following implementation requires `kubectl`, [`yq`](https://github.com/kislyuk/yq#installation), plus the existing rbac access to read service accounts and secrets in the namespace you want to impersonate.

```sh
#!/usr/bin/env bash
set -euo pipefail

impersonate() {
  local -r acc="$1"
  local -r ns="${2:-kube-system}"
  local -r sec=$(kubectl get sa "${acc}" -n "${ns}" -oyaml | yq ".secrets[0].name" -r)

  # extract required secrets from the service account
  kubectl get secret "${sec}" -n "${ns}" -oyaml > secret.yaml
  local -r token="$(yq ".data.token" -r < secret.yaml | base64 -d)"
  yq ".data[\"ca.crt\"]" -r < secret.yaml | base64 --decode > ca.crt

  # extract api server + namespace from existing kube config
  local -r context="$(kubectl config current-context)"
  local -r apiserver="$(kubectl config view | \
    yq -y ".clusters | map(select(.name == \"${context}\"))" | \
    yq ".[].cluster.server" -r)"
  local -r namespace="$(kubectl config view | \
    yq -y ".contexts | map(select(.name == \"${context}\"))" | \
    yq ".[].context.namespace" -r)"

  echo "Got ${context} via ${apiserver} on ${namespace}"

  # pass everything onto kubectl config to get it updated in ~/.kube/config
  kubectl config set-cluster \
    --certificate-authority="ca.crt" \
    --embed-certs=true \
    --server="${apiserver}" \
    "impersonate-cluster"

  kubectl config set-credentials "impersonator" \
    --token="${token}" \
    --client-key="ca.crt" \
    --embed-certs=true

  kubectl config set-context \
    --cluster="impersonate-cluster" \
    --user="impersonator" \
    --namespace="${namespace}" \
    "impersonate"

  kubectl config use-context "impersonate"
}

# usage: impersonate jenkins kube-system
# shellcheck disable=SC2068
impersonate $@
```

Make it an executable `impersonate.sh` file and run `./impersonate account namespace`. Note that this implementation requires that your context has a namespace.

For a budget solution to 3; take the `token` + `secret`, store it in a secured `vault` that you probably already use policies for correctly. People can now elevate themselves from `vault` to `kubectl` while you bang your head against the oidc providers.
