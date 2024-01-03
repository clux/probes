+++
date = "2023-12-31"
description = "Journal of good things from the year"
title = "Gratitude for 2023"
slug = "2023-12-31-annual-gratitude"

[extra]
toc = true

[taxonomies]
categories = ["life"]
tags = ["health"]
+++

The year is coming to a close, and as a small amount of self-reflection of my relatively fortunate and stable situation, here's a list of things in life that made me happy.

<!--more-->

## Video

In general, I like well presented video exposés, impressive video game footage, and watch competitions from everything from piano competitions to SC2 esports tournaments. Some frequented returns:

- [yt/BobbyBroccoli](https://www.youtube.com/@BobbyBroccoli) :: for great long form science controvery deep dives
- [yt/Tantacrul](https://www.youtube.com/@Tantacrul) :: for a yearly hinge expose on music
- [yt/hbomberguy](https://www.youtube.com/@hbomberguy) :: for his yearly expose on who knows what
- [yt/thejuicemedia](https://www.youtube.com/@thejuicemedia) :: for their snappy government parody ads
- [yt/MonarchsFactory](https://www.youtube.com/@MonarchsFactory) :: TTRPG concepts and mythology
- [yt/mcolville](https://www.youtube.com/@mcolville) :: TTRPG game mechanics and game design
- [yt/chopininstitute](https://www.youtube.com/@chopininstitute) :: classical piano recitals and the [chopin competition](https://en.wikipedia.org/wiki/International_Chopin_Piano_Competition) ([last winner](https://www.youtube.com/playlist?list=PLTmn2qD3aSQveuDKarRUibMEjFqJd1t1U))
- [yt/HarstemCasts](https://www.youtube.com/@HarstemCasts) :: intelligent starcraft 2 casts from top level player when you need a break
- [yt/ESLArchives](https://www.youtube.com/@ESLArchives) :: SC2/Dota2 tournament vods from [ESL](https://liquipedia.net/starcraft2/Electronic_Sports_League)
- [yt/AfreecaTV](https://www.youtube.com/@afreecatvesports432/videos) :: more starcraft: [GSL](https://liquipedia.net/starcraft2/Global_StarCraft_II_League) + [ASL](https://liquipedia.net/starcraft/AfreecaTV_StarCraft_League_Remastered)
- [yt/DoshDoshington](https://www.youtube.com/@DoshDoshington) :: for well-narrated Factorio Mod runthroughs
- [yt/KimuraTails](https://www.youtube.com/@KimuraTails) :: insane Trackmania (united) TASes
- [yt/cncf](https://www.youtube.com/@cncf) :: boring conference talks on cloud tech, but they [allowed me to avoid some flying](/post/2023-12-22-kubecon-chicago-log)
- [yt/HealthyGamerGG](https://www.youtube.com/@HealthyGamerGG) :: Dr K. with a pragmatic stoicism + meditation focused philosophy takes

> Would I still watch as much youtube without `2X` on all speech or with ads? Probably not. Long form media is a lesser toll on my continually stretched focus though.

As for actual full-runtime content, most my streaming services were cancelled last year, and the only one left is crunchyroll, which I guess makes me a full time weeb now. I would fight that, but [Love is War](https://en.wikipedia.org/wiki/Kaguya-sama:_Love_Is_War_(TV_series)) and [Spy x Family](https://myanimelist.net/anime/50265/Spy_x_Family) were also the funniest shit this year to me.

## Hardware

2023 was an upgrade year, a first since 2017, so have once again delved into the increasingly confusing realm of hardware for my [#linux](/tags/linux) desktop workstation. [Wendell from Level1Tech](https://www.youtube.com/@Level1Techs) + [GamersNexus](https://www.youtube.com/@GamersNexus) were the most helpful for guiding me in good linux-compatible setups. Ended up going full `AMD` to make my time with `Wayland` less [painful](https://wiki.hyprland.org/Nvidia/), and with less [funny flags](https://github.com/swaywm/sway/pull/6615).

The new rig is great. It has ~4x faster compile-iteration cycles, and it uses less power than my old one!

## Games

On the steam front, my timesinks were heavier games for a change. One even from this year:

- `Baldur's Gate 3` obviously. I have spent [days just theorycrafting](/post/2022-04-12-baldurs-roll/) its predecessors, and it's GOTY for a reason. Great storytelling, lots of great game mechanic ideas for making `5e` better. RIP September.
- `Borderlands 3`. BL2 still holds a special place in my heart for its chill coop, item hunting / diablo vibes, so __this year__, when `r/bl3` started being positive again - after years of annoying users by breaking the game, nerfing builds, changing the endgame - and my PC got upgraded, it was time. The weapon farming system is fun, the builds are cool, and the Cthulhu themed expansion really stands out as exceptionally beautiful. RIP July.
- [Manifold Garden](https://store.steampowered.com/app/473950/Manifold_Garden/) was the surprise hit. Its infinitely repeating take on first-person puzzle solving, ventures into a deeply psychadelic fractal space, and one that is captivatingly beautiful.

The amount of theorycrafting videos consumed during the RPG periods also shows that the desire to min-max is still very much alive.

## Coffee

To stay _woke_, I rabbit-holed into home-espresso making (like many of my tech friends), and am now able make a great cup with pretty cheap components (basic delonghi dedica + non-pressurized portafilter + a grinder), given good beans as a result. While the famous [hoffmann](https://www.youtube.com/@jameshoffmann) (or [joffman](https://www.youtube.com/@hamesjoffmann)) was helpful for his insights into coffee science, I did not need to min-max this. That said, fun side-project.

I occasionally try to replicate the perfect asian dirty coffee, or a thai style es-yen, but most of the time I just pull a shot, ice it, and pour over some oatly for a great lazy iced latte.

## Open Source

The [kube-rs](https://github.com/kube-rs) ecosystem continues with [13 new kube releases](https://github.com/kube-rs/kube/releases) this year. Lots of features landed; [socks5 proxying](https://github.com/kube-rs/kube/pull/1311), [rustls default](https://github.com/kube-rs/kube/pull/1261), new configs for [watcher](https://docs.rs/kube/latest/kube/runtime/watcher/struct.Config.html) + [Controller](https://docs.rs/kube/latest/kube/runtime/controller/struct.Config.html), [streaming lists](https://github.com/kube-rs/kube/pull/1255), [controller streams interface](https://kube.rs/controllers/streams/), [oidc refresh](https://github.com/kube-rs/kube/pull/1229), [metadata api](https://github.com/kube-rs/kube/pull/1137) + [metadata_watcher](https://github.com/kube-rs/kube/pull/1145), [store readiness](https://github.com/kube-rs/kube/pull/1243).

Thankfully, I can largely PM the ship, and leave most larger features to others. [Stream sharing](https://github.com/kube-rs/kube/issues/1080) is close, [k8s-pb](https://github.com/kube-rs/k8s-pb) integration can be started, [client-v2](https://github.com/kube-rs/kube/issues/1032) is restarted, and am enjoying expanding [docs on kube.rs](https://kube.rs/) (particularly the [controller guide](https://github.com/kube-rs/website/issues/5)) to simplify future Q/A + upskill adopters.

Stepping outside kube, [python-yq](https://kislyuk.github.io/yq/) has been [rewritten in rust](https://github.com/clux/whyq). This is both a fun and [necessary](https://hachyderm.io/@clux/111031702227829219) project for me (not solved by the [go rewrite](https://github.com/mikefarah/yq/issues/193)). This is a small project, because we are just [deferring](https://github.com/clux/whyq/blob/c6631590ebd170c5e09885a43cff476d6787e574/yq.rs#L218-L219) to [jq](https://github.com/jqlang/jq), but it is very satisfying [how simple](https://github.com/clux/whyq/blob/c6631590ebd170c5e09885a43cff476d6787e574/yq.rs#L1-L302) things can be when you are not trying to re-invent the [wheels](https://github.com/mikefarah/yq/tree/master/pkg/yqlib).

## Helix

The [helix editor](https://helix-editor.com/) (replacing VS Code) is the first modal editor I've managed to stick to, and a big reason for this is [how compassionate the UX is](https://hachyderm.io/@clux/111302311059887332); menus give me forgotten shortcuts, commands are searchable, and the speculative LSP integrations are amazing.

Am actually using helix as my new [#pkm](/tags/pkm) rather than `foam` because the [markman lsp](https://github.com/artempyanykh/marksman) actually lets me do most of what I expect from a second-brain anyway! Symbol search for H1s or H2s, and `Goto definition` for wikilinks are both unexpected LSP features.

## Positivity

In a world full of systemic problems, mute + block has never felt more valuable. I have aggressively hit `Dont recommend channel` on captive news channels, and `Indefinite mute` on excessively drama-peddling / self-rightous profiles mastodon even when I largely agree with their general points.

With global problems, the cost of exposure is a draining negative energy; powerlessness, constant exposure to virtue signalling / schadenfreude, and increasingly polarised and unhealthily dichotomous thinking, __E.g. climate change discourse__, frequently followed by either:

1. denial - thanks to the existence of unrealistic and equally problematic solutions
2. anger - e.g. via activists that advocate for engaging in large scale industrial sabotage

> Yes, i believe we are pretty fucked, but the fucking will continue whether I worry about it or not.

Twitter was terrible in always exposing you to the angriest threads about this. Thankfully, in its demise, Mastodon is an improvement for what I was using twitter for; cross-link to/from blog-posts, follow posts from experts, and moderately engage while bored on a train. The `Mute` option actually works, and the defederation of negative echo chambers makes it feel more stable (you are not in the hands of one indebted company).

You could make [several good arguments for leaving twitter](https://throwawayopinions.io/the-paradox-of-intolerance.html), but that was not the job of this post. I have found [a new place](https://hachyderm.io/@clux), and it's a happier one.

> If you want more positivity, you must opt-out of some negativity. Pick your battles.

## Mountains

This year changed my approach to exercise, changing my goals from setting PBs in running events [like 2022](/post/2022-12-07-running-year/), to focus on fun, and exploring nearby mountains when they are available.

The biggest treks were the `5h` trail runs up [Doi Pui](https://www.strava.com/activities/10459620853) + [Croix du Nivolet](https://www.strava.com/activities/9186995095), and the `3d` long [Kumano Kodo](https://www.strava.com/activities/10282413401) pilgrimage trail with my partner. I also found incredible beauty and focus on hills requiring much less effort such as [Doi Suthep](https://www.strava.com/activities/10422346036), [Fløya](https://www.strava.com/activities/9664374916), & [Tindstinden](https://www.strava.com/activities/9653652377).

There is a concrete beauty to trail running and hiking that I did not get while optimizing for performance. You are always present in the mountains. No podcasts, no "get-it-done" mentality; the journey is its own reward. The experience lasts, unlike a `VO2max` bump.

Bigger hikes are less realistic outside of travel for me, so it's still mostly flats. Air-travel is becoming a harder-to-defend privilege, but I have to recognise that it's not really fair for a society to [offload climate guilt](https://news.climate.columbia.edu/2023/02/15/you-are-not-the-problem-climate-guilt-is-a-marketing-strategy/) on consumers despite a complete lack of systemic regulation.

> Like, I am car free and child free, but it's fucked that I feel the need to use that as an excuse.

## Routine

Beyond the above, my life is still largely routine:

> Walk to the park. Grind the coffee beans. Blitz some fruit. Triage issues. Play music. Appreciate beauty. Try to embrace being content, and try to be compassionate. Enjoy time with my partner.

Hoping that can continue in 2024. Here's to another year!
