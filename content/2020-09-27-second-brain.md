+++
date = "2020-09-27"
description = "Exploring second brain alternatives for campaign tracking"
title = "Foaming Campaign Brain"

[extra]
toc = true

[taxonomies]
categories = ["roleplaying"]
tags = ["zettelkasten", "foam"]
+++

After 2 years of running a D&D campaign almost every week, my note taking setup reached several breaking points. If you're using `OneNote` or another online managed system for tracking notes/cities/npcs/pcs/events, but know how to use programmers tools like `git` and `code`; boy are there a world of advantages available to you.

This is a story of my original note talking setup, a comparison between newer technologies, and how I am back to writing markdown in a folder.

<!--more-->

## The OneNote Setup
Early in 2018, we were starting to play weekly, and my various documents in google docs were not cutting it.

I watched a couple of videos detailing how to [Manage a D&D campaign with OneNote](https://www.youtube.com/watch?v=SqhePj9ratI). The double categorisation setup where Sections contain many Pages was nice, the promise of links was promising, but unfortunately, the [difficulty of creating them](https://youtu.be/SqhePj9ratI?t=1856) made them too slow to really be viable.

A year down the line, my OneNote looked like this:

![one note campaign](/imgs/foam/onenote-campaign.png)

Still, image integration straight from a google search and into your document was great. Well, not `Google`, but `Bing`, I guess. In practice, I wasn't always sure what I was going for, so I often ended up searching for images in my browser first via google, getting shunted to pinterest and find something promising there. Since `OneNote` returned completely different images, I generally had to __save and upload__ my findings anyway.

`OneNote` did let you place random text fields anywhere on your page (like some kind of janky e-scrap book), and this did actually help get around one problem I was having:

> **splitting the data is hard in a browser**

Why? You click on a link, the browser makes several HTTP requests, and after waiting 400ms you finally get to see the results (one drive is not super responsive), but this movement drops your place to the current page you needed to cross reference with. So now you either go back, and shift-click the reference so you now have two tabs that you can Shift-Tab between, or you prepare those tabs up in advance (typically before the session).

In practice I often ended up with a 30 tab browser window for every session, which generally, looked something like:

![session chrome window](/imgs/foam/session-chrome.png)

this type of tab/icon chaos generally included:

- 5 from OneNote (campaign brain)
- 2 from Kobold Fight Club (potential encounters)
- 6 from monsters / items
- 2 youtube ambient music tabs
- 2 for random generators
- 5 from lore/wikis related to the story or NPCs

and their multitude meant I needed to tab between them to find the right one, only to have to change them when players did something out of left field.

> **DMs**; does this happen to you?

So this system definitely had problems, but it was free, __generally__ responsive, and the 400ms link opening time wasn't too much of a drain on the improv. It was definitely noticable though, and it just took a slightly decreased `OneNote` **QoS**, or a few interrupted WIFI evenings, for it all to feel pointless.

..there was also a whole week where I was unable to save anything with no errors shown to me. I never get to the bottom of it, but it was the last straw.

## The Git Repository
After these problems, I realised that there's one thing I'm unwilling to compromise on:

> **My notes must be available offline**

If that means I have to do a full sync up front; **fine**. A folder of documents behind `git` solves this. This also solves the merge conflict resolution problem that `OneNote` was giving me due to the way it hid its synchronisation mechanism. Imagine arriving back at your desktop computer only to find that your laptop didn't sync, so you either have to boot your laptop back up, or solve a merge conflict (with yourself) the next time you open your laptop (on an interface somehow worse than git). Not great.

Now I just `git commit` and `git push`, and never get a merge conflict.

That means that no matter how slick the following solutions look:

- World Anvil
- Notion
- Roam

These solutions are off the table for me. Even if some of them might be a reasonable abstraction.

With an offline document repo, it was immediately easy to get back the basic functionality needed; categorised text in sections (folders) and pages (markdown files within folder), and an offline way to access them (cloned repo).

![git repo campaign](/imgs/foam/git-repo-campaign.png)

## The Markdown
Using [Markdown](https://guides.github.com/features/mastering-markdown/) as the documention format is a no-brainer to me as a software engineer. This defacto documentation standard [used](https://gohugo.io/content-management/formats/) [nearly](https://community.atlassian.com/t5/Jira-questions/Using-markdown-in-Jira/qaq-p/892041) [everywhere](https://github.github.com/gfm/), supported by [every](https://code.visualstudio.com/docs/languages/markdown) [major](https://github.com/plasticboy/vim-markdown) [code](https://github.com/SublimeText-Markdown/MarkdownEditing) editor.

Still, many of the same problems I had with `OneNote` still manifested themselves:

- linking markdown files requires lookup and hard-coding of filesystem paths
- tendency to store everything in one file because linking is annoying
- guessing what tabs are needed in your editor before the session
- embedding images is a bit of a pain

Now, none of these in theory were unsolvable. But was this something where homegrowing my own content management markdown system was really a smart way forward? After all, surely people writing books or research papers need some kind of system to keep track of everything, right?

## Zettelkasten
There are probably millions of ways to organise your stuff and still be successful, just take a look at some famous writers' desks:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Since it&#39;s a Monday, let&#39;s play which fantasy writer&#39;s desk would you want to write at:<br>1. Ursula K. Le Guin&#39;s<br>2. Neil Gaiman&#39;s<br>3. J.R.R. Tolkien&#39;s<br>4. Terry Pratchett&#39;s <a href="https://t.co/hsMRgI0JEh">pic.twitter.com/hsMRgI0JEh</a></p>&mdash; Into The Forest Dark (@ElliottBlackwe3) <a href="https://twitter.com/ElliottBlackwe3/status/1308030597688971265?ref_src=twsrc%5Etfw">September 21, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
<!--shortcode fails on my hugo install..< tweet 1308030597688971265 >-->

Individualism notwithstanding, some methods are more refined than others. For instance, this [article on sociologist Niklas Luhmann and his Zettelkasten system](
https://writingcooperative.com/zettelkasten-how-one-german-scholar-was-so-freakishly-productive-997e4e0ca125) talks about one refined system. __Do at least skim__ that article for why that solution is so powerful. It brings up some very important data modelling problem inherent to note taking:

- do we categorise notes by **folders**?
- do we categorise notes by **tags**?
- do we categorise notes by **links**?

All these methods on their own cause data to get lost, but using all of them at the same time gives you a stronger, self-reinforcing system. If `Luhmann` could achieve this with a simple [slip box system of index cards](https://en.wikipedia.org/wiki/Zettelkasten#/media/File:Zettelkasten_(514941699).jpg), then making __your__ editor do it should be childs play.

Though, why this system? Well, for one it's an organic extension of what you already are doing. You don't need to follow it entirely, but the benifits of links and connection notes are huge. From the principles listed in that article. Number 3 in particular:

> **Always link your notes**
> Whenever you add a note, make sure to link it to already existing notes. Avoid notes that are disconnected from other notes. As Luhmann himself put it, "each note is just an element that derives its quality from the network of links in the system. A note that is not connected to the network will be lost, will be forgotten by the Zettelkasten"

This feels like good D&D advice as well. An NPC already known by a player can be a lot easier and more sensible to re-instate, rather than fabricate a slightly different version of [one of your 10 existing characters](https://old.reddit.com/r/dndmemes/comments/iuajhd/im_basically_a_voice_actor/). Need a "dark city", but drawing a blank? Make a shadowfell version of of the same city and link them. Easier to remember for everybody. A campaign quickly accumulates a lot of information. No need to make this harder than it already is.

## Considered Choices

### 1. Sublime ZK
There is a [zettelkasten plugin for sublime](https://github.com/renerocksai/sublime_zk), but it looks pretty **abandoned** at the moment. It also does not seem to let you build a graph of your links (one of the main selling points of Obsidian).

### 2. Obsidian
The article by [joshwin](joshwin.imprint.to) on how he [uses obsidian to manage goals, tasks, notes, and more](https://joshwin.imprint.to/post/how-i-use-obsidian-to-manage-my-goals-tasks-notes-and-software-development-knowledge-base) is interesting. A pre-configured all-in-one application that is flexible and powerful enough to let you handle all these different categories. Well worth [looking into](https://obsidian.md/) **if** you don't have a good editor already. Their [feature list](https://obsidian.md/features) is decent.

Personally, though, there are **reasons why I'm not going for this**:

#### Custom Editor
While it looks like you __can__ customize this scope-limited editor close to what you fancy, it does mean that you will need to do go through all that yet another time. Having battled with Vim/Sublime/VSCode and various editors over the course of my life, there was a point where I have started feeling __satisfied__ with what [past-clux had already configured](https://github.com/clux/dotfiles).

#### Custom Install
The only provided [linux install](https://obsidian.md/) a single [snap package](https://snapcraft.io/). While snap **might become** a successful and perhaps the most prominent packaging distribution system on linux, it's nowhere near that tipping point yet; especially on [Arch](https://www.archlinux.org/). There's no need for me to introduce an [extra daemon](https://wiki.archlinux.org/index.php/Snap) to auto-upgrade packages when there's already [a solid system](https://wiki.archlinux.org/index.php/pacman) on Arch that lets me do this.

#### Custom Formats
As with any another system bundling some pinned [electron](https://www.electronjs.org/) version, you now have yet another piece of software that will have security patches neglected as if development suddenly stops.

Sure, you can keep your data because you can store it wherever, but if they control the system that defines the format then it would be super annoying to have to do a migration to something else.

#### Vendor locked plugins
One way out of this would be to have custom plugins, but their plugin API is not exposed (though on their [roadmap](https://trello.com/c/Z7qqKVXd/19-public-plugin-api-v10)).

Ultimately, even if this eventually did get solved, I'd still rather go with a plugin system in a code editor I already know how to use, and backup, than to get locked in to something forked off electron where the development may stop at any time.

### 3. Orgmode with Roam
Another all-emcompassing standard that hasn't really caught on as widely; [orgmode](https://orgmode.org/). Looks a bit like markdown, but has a lot more support for things I don't see an immediate need for. It seems kind of coupled with the [emacs](https://www.gnu.org/software/emacs/)/`lisp` ecosystem, so if that's your preference; check out [org-roam](https://github.com/org-roam/org-roam). For me, this is a bit **too off the beaten path**.

### 4. Foam
We close with [foam](https://foambubble.github.io/foam/), the system we ended up using. Inspired by Roam (a system I neglected to talk about because of sync/offline problems, and it's also not cheap).

While it does seem somewhat early stage, the selling point here is that `Foam` is really just a collection of [VS Code](https://github.com/microsoft/vscode) extensions around markdown, that you can [default-recommend](https://code.visualstudio.com/docs/editor/extension-gallery#_recommended-extensions) at the [repo level](https://github.com/foambubble/foam-template/blob/master/.vscode/extensions.json) and configure how you want.

The main ones here are:

- [foam.foam-vscode](https://marketplace.visualstudio.com/items?itemName=foam.foam-vscode) - foam's own extension
- [kortina.vscode-markdown-notes](https://marketplace.visualstudio.com/items?itemName=kortina.vscode-markdown-notes) - markdown `[[wiki-links]]` and backlinking
- [tchayen.markdown-links](https://marketplace.visualstudio.com/items?itemName=tchayen.markdown-links) - graphs markdown linked notes
- [yzhang.markdown-all-in-one](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) - markdown writing helpers
- [esbenp.prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) - an auto-formatter
- [eamodio.gitlens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) - online git history

All of which are very popular, standard extensions, with the sole exception of the `foam`; a [smaller looking](https://github.com/foambubble/foam/tree/master/packages/foam-vscode) extension that helps manage the wiki links. Frankly, it's somewhat strange to me that they list the off-putting [`tolerance for alpha software`](https://github.com/foambubble/foam/tree/master/packages/foam-vscode#requirements) as a requirement when most of their logic resides outside their codebase.

If you've dealt with a code editors plugin ecosystem before, this is a lot more welcoming than obsidian to me. Bug in the system? Well, probably one of the extensions. You've got options for dealing with it: report & wait, fork + fix, try other replacement extensions.

Oh, and I can we can swap out the [default provided dark theme](https://marketplace.visualstudio.com/items?itemName=philipbe.theme-gray-matter) for one you like, e.g. [Seti](https://marketplace.visualstudio.com/items?itemName=tnaseem.theme-seti):

![foam backlinks seti](/imgs/foam/foam-backlinks.png)

Finally, if you need extra functionality, you now have the whole [wealth of the VS Code ecosystem](https://marketplace.visualstudio.com/) at your fingertips.

So far, these have been useful addons for providing extra functionality:

- [mushan.vscode-paste-image](https://marketplace.visualstudio.com/items?itemName=mushan.vscode-paste-image) - paste image from clipboard functionality

## Result
So that was a lot of information about comparison of note taking technology. How does my system actually end up looking? Depends on whether I am editing or running a game. Here is a 3-way split between editing and showing the graph update live.

![foam 3-way split](/imgs/foam/3-split-irae.png)

The [graphs sometimes overlaps](https://github.com/tchayen/markdown-links/issues/58) and [rebalances awkwardly](https://github.com/tchayen/markdown-links/issues/64) ([help seems to be requested](https://github.com/foambubble/call-for-visualization)), but the naive implementation still help out a whole lot.

Here is a subset from our sea adventures aboard the `Artemis`:
![foam graph around artemis](/imgs/foam/graph-sea-campaign.png)

Most of the time I just straight up edit markdown in two groups. Sometimes with a preview or graph instead on the right or below, depending on what type of work needs focus. The __flexibility__ of this system is equivalent to that of a popular professional code editor by inheritance.

Even if some of these plugins don't evolve much, I see this as a pretty future proof setup (the [why foam issue](https://github.com/foambubble/foam/issues/88) is also refreshingly honest). The investment in new tech is small, and migration cost away from said tech ought to be minimal.

From a RPG perspective, being able to immediately jump to anything through a responsive fuzzy search helps trim down on those `"hang on one second"` moments, and when you are planning by yourself, you have a whole linked **compendium of knowledge**.

The hope with all this is that the amount of hard-to-navigate "running the game tabs" should be significantly reduced with this setup, and my world should feel more integrated thanks to the extensive Zettelkasten style linking. Well. Fingers crossed anyway.
