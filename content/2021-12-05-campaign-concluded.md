+++
date = "2021-12-05"
description = "..and more reasons (not) to pay for Notion"
title = "Campaign Conclusion & Brain Dump"

[extra]
toc = true

[taxonomies]
categories = ["roleplaying"]
tags = ["foam"]
+++

After almost 4 years of running D&D almost every week, my big campaign concluded recently. This week marked our retrospective, and the release of several relics of the campaign. One in particular was the campaign repo - previously described as my [foaming campaign brain](/post/2020-09-27-second-brain). This is a brief post about the setup, and discovered pros/cons associated with it.

<!--more-->

## Campaign

Campaign first. We held `126` sessions about the campaign over `3.5 years` (i.e. **36 per 12 months**) as a remarkably consistent group (even after the pandemic hit and we moved remote).

Tooling also moved on; discord + [Avreae](https://avrae.io/) (dndbeyond character + dice integration), [rhythm](https://rythm.fm/) for music (got DMCA'd and replaced by [jmusicbot](https://github.com/jagrosh/MusicBot)), [owlbear.rodeo](https://www.owlbear.rodeo/) for interactive maps, [5e.tools](https://5e.tools/) for quick spell/item/monster searches and more. A lot easier to run with your main computer in front of you.

We could also record with [OBS](https://obsproject.com/). So in fact, from the pandemic on, I started gathering episodes in an unlisted youtube playlist. Mainly as a reference, but also a memento later, for when it was over.

Inlining an external embed here to the wrap-up episode below.

{{ youtube(id="9HRCumVEHQU") }}
[part 2 here](https://www.youtube.com/watch?v=_toA4XCp--U).

This could be interesting if you want to cross reference with navigation in the brain / want to see how the tools fit together (map top left, discord dice bot bottom left), or you were a previous player (I don't assume it would be super interesting to anyone else).

It's also the only episode where the DM is relieved throughout the entire episode (because we managed to finish the campaign and they didn't all wipe 16 levels in).

Anyway. Onto the notes.

## The Brain

I had started to use [foam](https://foambubble.github.io/foam/) as a note taking tool in 2020. Mostly because of my familiarity with [Markdown](https://guides.github.com/features/mastering-markdown/), but also the avoidance of vendor lock-in. Go read [foaming campaign brain](/post/2020-09-27-second-brain) for more reasons behind this and how it works.

It's very similar to [obsidian](https://obsidian.md/), and most of the [general advice for it](https://www.youtube.com/channel/UC85D7ERwhke7wVqskV_DZUA) applies.

The structure is just one enormous docs folder with markdown documents that is haphazardly grouped into folders:

```
├── coast
├── deities
├── east
├── factions
├── north
├── npcs
├── pcs
├── planar
├── recaps
├── rules
├── seaofbones
├── spine
├── underdark
└── whiteplume
```

These refer to either collections of notes that were close in time/space across the campaign, or special sets of notes like pcs, npcs, factions, and dm notes and rules.

The documents in these folders cross-link with various markdown plugins in [VS Code](https://code.visualstudio.com/) (using wiki syntax). Users **could** clone and open the [campaign repo](https://github.com/clux/campaign) with VS Code, install plugins, and you would get my experience, but this is a bit awkward.

I couldn't just give people a link to things in the docs (e.g. [goatweaver](https://github.com/clux/campaign/blob/main/docs/pcs/goatweaver.md)) because you'll notice none of the wikilinks work. So we needed a webpage conversion.

## Release Solution

Thanks to this [template repo](https://github.com/Jackiexiao/foam-mkdocs-template), it was reasonable easy to glue together
[mkdocs](https://www.mkdocs.org/) with the [mkdocs-material](https://squidfunk.github.io/mkdocs-material/) theme. The result is this:

[![foam mkdocs campaign website](/imgs/foam/foam-material.png)](https://clux.github.io/campaign/)

Folders become tabs, files becomes entries on the left side, and TOC is generated from headers on the right. Images are rendered from disk (as in markdown preview), cross-links work, and it would have ended up looking super professional had it not been for the myriad of TODOs buried in every document.

You can view the [resulting static website](https://clux.github.io/campaign/) at your leisure, but again, this is not going to be very interesting for anyone except the players and other DMs.

## What Worked Well

### Running The Game

It was very nice process to DM with `code` in front of me. Definitely much better than the original `OneNote` setup that was periodically down or slow to respond. Knowing how to search, and cycle through tabs, and search within docs (or use `rg` in the docs folder) made it very easy to find anything quickly (no matter how deeply buried it ended up).

Your mileage may vary on this point, but if you know how to use a code editor, you'll always end up with a more powerful way to navigate than whatever features that eventually make it into notion et al.

### Website Release

It took me about one day to reorganise the repo in a way that it worked with `mkdocs`. The process was basically:

- move content into a `docs/` subfolder
- import [template repo](https://github.com/Jackiexiao/foam-mkdocs-template) as a base
- re-remember [how to install shit with python](https://github.com/clux/dotfiles/blob/e7f07400b3b8ac2ef19b7c35a5e5eff009c6a018/.functions#L483-L493)
- fix broken links that `mkdocs serve` found
- tweak `mkdocs.yml` to
  * make the theme look good and add dark mode
  * choose the most sensible navigation setups ([mkdocs-material has many](https://squidfunk.github.io/mkdocs-material/setup/setting-up-navigation/))
  * make edit links work (takes you to a github edit view that eventually leads to a branch commit or a fork pr)

The [mkdocs-material docs](https://squidfunk.github.io/mkdocs-material/setup/changing-the-colors/) in general were fantastic. Live preview of the features from their dogfooding setup. While I am confident [an approximation exists with hugo](https://themes.gohugo.io/), the features and quality here went far beyond anything I have seen in this space:

> [Search](https://squidfunk.github.io/mkdocs-material/setup/setting-up-site-search/) / [ajax fetching](https://squidfunk.github.io/mkdocs-material/setup/setting-up-navigation/#instant-loading) / [edit links on page](https://squidfunk.github.io/mkdocs-material/setup/adding-a-git-repository/?h=edit#edit-button) / multiple [TOC generation](https://squidfunk.github.io/mkdocs-material/setup/setting-up-navigation/#integrated-table-of-contents) methods

It made the outcome very attractive looking. In fact, it's so nice that it might even replace the [rust mdbook tool](https://github.com/rust-lang/mdBook) as a default simple static markdown web page for me.

<small>(.. well. Maybe anyway. The python ecosystem still leaves a lot to be desired.)</small>

### Recap Writing

Basically, a quick `Ctrl-Shift-P` in `code`, ask foam to create my [preferred note](https://github.com/clux/campaign/blob/main/.foam/templates/recap-template.md) (by [hijacking the daily note setup](https://github.com/clux/facemaulers/blob/main/.foam/templates/recap-template.md) for this), and it fills in the basics.

This file would serve as the "last we left off" at the start of each session, plus notes and TODOs for myself.

### Image Pasting

The [paste-image plugin](https://marketplace.visualstudio.com/items?itemName=mushan.vscode-paste-image) was pretty easy for capturing images and associating it quickly with the document. I would have preferred a drag and drop (when it could have worked), but ultimately bound a **button** in my desktop environment to do **quickly draw a rectangle** on my screen and shunt its contents to my **clipboard** (which then could be pasted from the plugin without going through a temporary file).

### Foam Improvements

Throughout half their [release history](https://github.com/foambubble/foam/releases), nothing major broke on my end as plugins upgraded.

The most notable upgrade I noticed was the complete revamp of the graph view with new selection features:

![foam new graph view](/imgs/foam/foam-newgraph.png)

However, one minor snag in one upgrade was [hiding the recaps from the graph view](https://github.com/foambubble/foam/issues/835). **EDIT 2023** [workaround found](https://github.com/foambubble/foam/issues/835#issuecomment-1399437329).

## What Sucked

### Renames

Foam ~~still~~ struggled with [doing file renames](https://github.com/foambubble/foam/issues/809) (because backlinks were not updated). This was worked around to some extent thanks to `mkdocs` telling me about the broken links (but this was after adding the web page element).

~~You are really dissuaded from renaming files either way (because of the work it leads to), and it basically precludes doing bigger refactors at the moment.~~

~~It's probably™ implementable on their side _"without too much work"©_ (because you can probably work around this with a script + `sed` if you are masochistic enough), but ultimately, **someone** has to actually do it - and who knows what complexity lurks within vs code plugins.~~

**EDIT**: Have commented out this part in 2023 because this issue was resolved in foam.

### Sort Inconsistencies

My [recaps folder](https://github.com/clux/campaign/tree/main/docs/recaps) has two digits prefixes on every note. This was fine in my file viewer + vs code, but not in `mkdocs-material` which sorted the entries lexicographically. Renaming would have to be done with `sed` or some other bulk search/replace tool.

This meant we basically had to take the folder contents and [manually arrange them](https://github.com/clux/campaign/blob/main/mkdocs.yml#L221-L347). This wasn't too annoying, as we could just copy the output from [`fd .md .`](https://github.com/sharkdp/fd) in the docs folder, and it was nice to be able to customize sorting anyway.

### World Secrets

If you want to release a DM brain (with all your plans and secrets) from your campaing, you are more or less saying that this world over. This was ok for us, it's been almost 4 years, and it's not particularly original (forgotten realms, and stolen content everywhere). If you wanted to do a [Mercer style](https://www.youtube.com/watch?v=i-p9lWIhcLQ&list=PL1tiwbzkOjQz7D0l_eLJGAISVtcL7oRu_) campaign procession where each season is set in the same world different area, then this process becomes difficult.

If you have a team of software people familiar with an editor you could have a **player brain** type thing that you could reference from the **DM brain** potentially. But if you have their level of viewers or players dedicated enough to basically write a [wiki for your campaign](https://criticalrole.fandom.com/wiki/Critical_Role_Wiki), maybe you have bigger problems.

### Graph View Not Exported

There maybe some way of exporting the graph into a json blob and importing it in a separate page for users to browse (like a sitemap). But given how much [graph has changed and is going to change](https://github.com/foambubble/foam/issues/530), plus my impatience for real web development made this a non-starter.

## Conclusion

Foam worked really well for this type of scoped project. I actually think that this type of brain would also **work well for the players** (if you have an engineer or two to manage it as notes) because they benefit much more from the website searchability, and you don't run into the last problem about world secrets.

Lacking that, I **will probably carry on** with this setup for **any similar ttrpg** setup. Most of the negatives listed above are a bit nitpicky (**EDIT**: and resolved now), and are _generally not that problematic_. Plus, I now have a better idea of what structures work (pcs, npcs, factions, deities, recaps were perfect fits for their own folders), what information ought to go where, and how deep to go.

~~However, this comes with a heavy caveat. This is currently best for small scale projects with a **sense of finality**. If this was my life brain, I would be a bit worried about the **renaming problem** ("would I never be able to refactor this?"). On the other hand, they [have an issue for it](https://github.com/foambubble/foam/issues/809) and have been doing promising development.~~ **EDIT 2023:** The rename problem is resolved, and I am using this for my main brain as well now.

Considering the standard open source software tradeoff is often between:

> free + a bit janky <------------> costly + vendor-locked

[Foam](https://foambubble.github.io/) does not deviate too far from this. It's **good**, and it **can become great**.

<small>_..and you have VS Code on your side to help tilt the tradeoff_</small>
