#!/bin/bash
set -exuo pipefail

# migration script from sibling dir probes (hugo format)
# swaps the yaml header hugo uses for a toml header that zola likes
import() {
  local -r file="${1}"
  cp "../probes/content/post/${file}" content/
  echo "+++" > tmp.toml
  sed -n '/^---$/, /^---$/p' "content/${file}" | head -n -1 \
    | yq -t '.description = .subtitle | .taxonomies = { "tags": .tags, "categories": .categories } | .extra = { "toc": true } | del(.subtitle, .categories, .tags)' \
    >> tmp.toml
  echo "+++" >> tmp.toml
  sd "^---[\r\n\w\W]*---[\r\n]" "" "content/${file}"
  cat "content/${file}" >> tmp.toml
  mv tmp.toml "content/${file}"
}

# via: eza content/post -l | choose 6
# in hugo repo
files_to_migrate=(
  #2006-08-09-vault-of-therayne.md
  #2011-03-20-tournament-seeding-placement.md
  2013-03-20-colemak-switchover.md
  2018-12-15-shipcat-introduction.md
  2019-01-17-three-way-charm.md
  2019-03-31-impersonating-kube-accounts.md
  2019-04-29-rust-on-kubernetes.md
  2019-06-04-towards-a-generic-kube-client.md
  2019-07-28-lxde-experiment.md
  2020-09-27-second-brain.md
  2020-10-04-antimagic-revisited.md
  2021-02-28-kube-evolution.md
  2021-11-06-kubecon-la-log.md
  2021-12-05-campaign-concluded.md
  2022-01-11-prometheus-ecosystem.md
  2022-04-12-baldurs-roll.md
  2022-10-31-factober.md
  2022-12-07-running-year.md
)

for f in "${files_to_migrate[@]}"; do
  echo "$f"
  import "$f"
done

cp ../probes/static/imgs content/ -r

for folder in $(fd . content/imgs --type d); do
  echo "${folder}"
  echo -e "+++\nrender = false\n+++" > "${folder}/_index.md"
done
