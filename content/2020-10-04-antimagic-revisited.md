+++
date = "2020-10-04"
description = "A lesson from weakly typed magic items"
title = "Antimagic and Force Cubes"

[extra]
toc = true

[taxonomies]
categories = ["roleplaying"]
tags = ["dnd", "homebrew"]
+++

In 2018, we introduced the explosive [Cube of Force](https://roll20.net/compendium/dnd5e/Cube%20of%20Force) into our home campaign. We really did not expect it to cause us/me that much grief at the time, but despite long canonicalisation meetings, our interpretation was not even internally consistent.

At the time we dealt with this by nerfing Cube down into the ground gradually rolling out alternatives, but it's time we dug into the concept of D&D `antimagic` properly.

<!--more-->

## Words of wording
Spell combinations are an inherently powerful thing in D&D, and so any spells that "cancels out magic" - potentially interacting with [Dispel Magic](https://5thsrd.org/spellcasting/spells/dispel_magic/) - must be carefully worded. And while [Wizards](https://company.wizards.com/) does a good job with this, there are still ambiguities that end up at [JeremyECrawford](https://twitter.com/JeremyECrawford)'s table:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Have a D&amp;D rules question? There&#39;s a good chance I&#39;ve answered it!<br><br>1. Search the Sage Advice Compendium: <a href="https://t.co/nlIvbEC7D7">https://t.co/nlIvbEC7D7</a>.<br>2. Search Twitter, typing my handle (<a href="https://twitter.com/JeremyECrawford?ref_src=twsrc%5Etfw">@JeremyECrawford</a>) and a relevant term, like &quot;Twinned Spell.&quot;<br>3. Search <a href="https://t.co/5oYKuatgLB">https://t.co/5oYKuatgLB</a>. <a href="https://twitter.com/hashtag/DnD?src=hash&amp;ref_src=twsrc%5Etfw">#DnD</a> <a href="https://t.co/JXtO9catjP">pic.twitter.com/JXtO9catjP</a></p>&mdash; Jeremy Crawford (@JeremyECrawford) <a href="https://twitter.com/JeremyECrawford/status/931742038474727424?ref_src=twsrc%5Etfw">November 18, 2017</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<!--shortcode fails on my hugo install..< tweet 931742038474727424 >-->

the referenced [Sage Advice Compendium](https://dnd.wizards.com/articles/sage-advice/sage-advice-compendium) contains 21 pages of Q/A as well as links to erratas for published books.

We'll focus on two spells that deal with antimagic, the philosophy and intent behind them, then we will tackle the Cube.

## ForceCage
[ForceCage](https://roll20.net/compendium/dnd5e/Forcecage) (or `FC` for short) first; is a `7th level` mechanism to trap players while also limiting __how__ spells can interact with trapped players:

> `FC`; "creating a solid barrier that prevents any matter from passing through it and blocking any Spells cast into or out of the area".

This wording only mentions __the casting__; i.e. the [line from the caster to the point of origin](https://www.dndbeyond.com/sources/basic-rules/spellcasting#Targets). `Fireball`'s blast would extend through, and any damaging concentration spell sitting in the middle before the cage comes down would also keep ticking __every round__ without proper recourse.

It is a deadly combination when used with spells like [Hunger of Hadar](https://www.dnd-spells.com/spell/hunger-of-hadar) (10 rounds), [Cloudkill](https://roll20.net/compendium/dnd5e/Cloudkill) (100 rounds), or [higher level clouds if available](https://5thsrd.org/spellcasting/spells/incendiary_cloud/). Oh, but we'll just dispel..

> `FC`: This spell can't be dispelled by Dispel Magic.

![hadar](/imgs/antimagic/hadar.jpg)

Scary prospect though it may be, you can wrangle yourself out of it with using; `[Plane Shift](https://roll20.net/compendium/dnd5e/Plane%20Shift#content) / [Teleport](https://roll20.net/compendium/dnd5e/Teleport#content) / [Misty Step](https://roll20.net/compendium/dnd5e/Misty%20Step#content) / [Dimension Door](https://roll20.net/compendium/dnd5e/Dimension%20Door#content) on a successful charisma check. All it takes is for one player to get outside and stop the mage from hurling spell effects through the boundary. It is also possible to [Disintegrate](https://roll20.net/compendium/dnd5e/Disintegrate) it.

Still it highlights a difference with other antimagic. The barrier is not perfect, and the "effect" of the spell _leeches through_ the barrier of the cage, which is perhaps somewhat confusing when you can sometimes interpret the spell effect as _matter_. This is irrelevant as we'll see later; while a spell caster is shaping the underlying magical fabric; the effect is a _magical energy_.

> Don't invoke special relativity or thermodynamics. Magic does not have to obey `E=mc^2`.

## Antimagic Field
[Antimagic Field](https://roll20.net/compendium/dnd5e/Antimagic%20Field) (or `AMF` for short), is an `8th level` sphere that disallows spells cast in/out __as well as__ magical effects leeching through! The reason for the great increase in cancellation power is justified by its higher level, careful wording, and its lack of entrapment (people can walk out of it unlike `FC`).

> `AMF`: Any active spell or other magical Effect on a creature or an object in the Sphere is suppressed while the creature or object is in it.

The blast of a fireball detonating outside an `AMF` simply disappears into nothing at the boundary of its sphere of influence.

But what happens if you throw a [Delayed Blast Fireball](https://roll20.net/compendium/dnd5e/Delayed%20Blast%20Fireball) inside an area, and put an `AMF` around the area, while powering up the fireball from the outside? This, really claws at the heart of the word __"suppressed"__; is the fireball bead still there? Will it keep working after the `AMF` disappears? Has it powered up in the mean time? Has the duration elapsed?

This is a harder corner-case, and requires some more guidance. And as far as corner-cases go, it's not alone, just think about:

- class abilities like paladin's smite, monk's ki points, druid shapeshifting
- monster abilities like dragon's breath, beholder rays
- summoned creatures

To answer whether these count as _magical_, we need some disambiguation.

## What is a magical effect?
The best source here come from the [interview with Crawford from 2017](https://dnd.wizards.com/articles/features/tad-williams-storytelling) about antimagic and what they mean by `suppressing` magic.

The short answer is that spells are **not dispelled**, they temporarily stop working, and the **duration of spells keeps ticking**.

He justifies it by describing magic in the D&D world as always existing in the background; a loose weave. Magical effects is __this fabric__ formed into a particular shape; __background magic woven into an effect - using a formula__. "AMF introduces a \[temporary\] bug in this formula." Whereas `Dispel Magic` disperses that woven magic from a spell into background magic.

Because the world is inherently magical - and creatures like dragons and beholders would not make sense without it - `AMF` could not possibly cancel this type of magic (as this would undo the very nature of the multiverse). Neither could it cancel non-magical effects that were created through the means of past magic. However:

> `AMF`: "You will not see any effects of magic while inside this field. The area is divorced from the magical energy that suffuses the multiverse".

This text establishes a need to distinguish those types of magic from the others. This is where we consult the __heuristic__ test from the [Sage Advice Compendium](https://media.wizards.com/2020/dnd/downloads/SA-Compendium.pdf) inlined below:

### Test for magical effects
Answer `YES` to any of these to be classified as magical (and thus have `AMF` suppress its effect):

- Is it a **magic item**?
- Is it a **spell**?
- Is it a **spell attack**?
- Is it creating the **effects of a spell mentioned in its description**?
- Is it **fueled by spell slots**
- Does the words `magic` or `magical` **appear in its description**?

### Examples
While this seems like a well-thought-out heuristic, the results they mention are interesting:

- Conjured creatures relying on concentration are magical
- Summoned creatures with instant cast duration are **NOT** magical

Because the summoning has already taken place in the latter case.

The corollary is that:

- Conjured creatures (concentration-based) disappear
- Conjured creatures reappear when the field disappear (unless concentration was lost)
- Summoned creatures not concentration-based can traverse the field (they are not persisting because of a spell anymore)
- [You still have to make concentration checks when hit](https://rpg.stackexchange.com/questions/93550/is-a-concentration-spell-suppressed-when-the-caster-is-in-antimagic-field)

Additionally, the following phenomenons (that at some point required magic to bring into existence) are __not considered magical__:

- Fire created by `Prestidigitation` (if it has a reason to keep burning)
- A `Dragon` and its breath weapon
- A `Beholder` and its `Antimagic Cone` (though it functions like `AMF`)

![beholder ray](/imgs/antimagic/beholder_ray.jpg)

### Artifacts
Finally, `Artifacts` - magic items either unavailable to mortals, or long forgotten - are also unaffected by `AMF` by a special flavour text (presumably to prevent you from destroying them):

> `AMF`: Spells and other magical Effects, **except those created by an artifact or a deity**, are suppressed in the Sphere and can't protrude into it.

Thus, they probably have their full abilities unmodified completely - even if it can cast spells, like `Blackrazor`'s `Haste` ability. The magic of deities cannot be modified by mortals.

### Interpretting the rest
Spellcasters with an active `Find Familiar` leave a bunch of open ended questions on how you can interact with them, even though the familiar clearly lingers. [Telepathy is magical](https://rpg.stackexchange.com/questions/133610/which-features-of-a-wizards-familiar-if-any-are-considered-magical), and if telepathy is magical, then so is sharing of senses between a familiar (at least that is my interpretation).

Additionally; a `warlock`'s `Pact Magic`, their `Eldritch Invocations`, blade pactweapons, and `Mystic Arcanum` are all magical by their wording.

Similarly, a `sorcerer` can't use sorcery points, as they "create \[..\] magical effects", nor can they use the clearly magical; `Metamagic`.

The `PHB` mentions that the `monk`'s `ki` energy draws on magical energy, but this is apparently only meant to mean the "background magic in the multiverse" `Crawford` says in the interview, and goes on to say:

> "we only consider individual monk ability to be magical if we've put the word magic/magical/magically in that particular monk ability"

A quick [search through reference text](http://dnd5e.wikidot.com/monk) seem to only mention:

- KI-Empowered strikes
- Fey Step
- Blessing of the Raven Queen
- Casting spells via `Way of the Four Elements`

so Flurry/Patient Defense or even [Stunning Strike is not magical](https://rpg.stackexchange.com/questions/76005/does-ki-count-as-magic-for-the-purpose-of-an-antimagic-field-or-is-it-only-fluf).

The `paladin` only has a few similar references:

- Channel Divinity is magical
- Sacred Weapon is magical (weapon no longer get the +1 if it got it)
- Divine Health is magical (no longer immune to disease)
- Divine Smite is not magical - but you can't use it to expend spell slots!

The `druid`'s `Wild Shape` is magical and would temporarily drop within an `AMF`.

The `ranger` is more straightforward. Only spells matter, and while `Hunter's Mark` will linger, it does so under concentration, and its effect will be suppressed if either of you are inside of an `AMF`.

## Delayed Blast Fireball
This brings us to the curious case of [Delayed Blast Fireball](https://roll20.net/compendium/dnd5e/Delayed%20Blast%20Fireball). Some [answers are provided by Crawford here](https://www.sageadvice.eu/2015/12/09/delayed-blast-fireball-inside-an-antimagic-field/), though they still leave some wiggle room.

It's clear that an active `DBF` should have its duration elapse inside an `AMF` from what `Crawford` says in the interview, but it is still a concentration spell that increases in damage every round because of concentration:

> `DBF`: When the spell ends, either because your concentration is broken or because you decide to end it, the bead blossoms with a low roar into an explosion of flame that spreads around corners.

> The spell's base damage is 12d6. If at the end of Your Turn the bead has not yet detonated, the damage increases by 1d6.

Your concentration is not broken by `AMF`, and there's nothing explicitly indicating that a magical transference of energy occurs while concentrating. To take the spell at face value; the bead just needs the concentration to exist (it's not explicitly doing anything magical each round), and it immediately detonates when the link is severed:

- If concentration is _broken_ while the bead is inside an `AMF`, then bad luck. Nothing happens.

- If there is a surpressed bead inside an expiring `AMF`, then hey, surprise; the bead can glow once more; and more intensely than before. Concentration paid off.

There's plenty of arguments to be made about how counterintuitive this is, but we don't really know anything about the nature of concentration. The [general consensus is that this works](https://rpg.stackexchange.com/questions/136280/what-happens-if-a-delayed-blast-fireball-detonates-inside-an-antimagic-field#:~:text=A%20Delayed%20Fireball%20in%20an%20Antimagic%20Field%20wouldn't%20detonate&text=While%20an%20effect%20is%20suppressed,is%20suppressed%2C%20meaning%20nothing%20happens.).

![fireball](/imgs/antimagic/fireball.jpg)

This is probably a good thing, because a similar case can be made against `DBF` inside [Time Stop](https://roll20.net/compendium/dnd5e/Time%20Stop#content); a [tradition](https://www.dndbeyond.com/forums/dungeons-dragons-discussion/rules-game-mechanics/10141-spells-time-stop-and-delayed-fireball-question) that is [too cool](https://www.reddit.com/r/dndnext/comments/f8jb53/how_would_time_stop_and_delayed_blast_fireball/) to [not work](https://thinkdm.org/2018/02/03/can-you-cast-multiple-delayed-blast-fireballs-during-time-stop/).

## Antimagic Field vs...
### 1. ForceCage
Let's look at how cancellation texts interact; `ForceCage` does not prevent magic being cast inside as long as the point of origin does not cross the boundary; so [AMF suppresses FC](https://www.giantitp.com/comics/oots0627.html).

The result being a 10ft sphere sphere partially protruding a 10x10ft `FC rectangle, allowing for some funny geometrical problems - if you are inclined to do some on-the-fly trig.

> AMF: If the Sphere overlaps an area of magic, the part of the area that is covered by the Sphere is suppressed.

Note that there's no __dynamic movement__ or __dynamic extensions__ for spell effects (movement typically happen as a discrete point at the start of a casters turn); `AMF` would leave the `ForceCage` active, just partially disabled where the the caster's sphere is covering it.

### 2. Self
A final note of its uncancellability; two `AMF`s do not cancel out each other. Their "sphere of influence" simply become their union.

> `AMF`: the spheres created by different antimagic field Spells don't nullify each other.

### 3. Anything
By the heuristic magic test, I can't think of anything short of a `Wish` that could aid in removing an active `AMF`, and that could still only work from the outside. Even spells like `Disintegrate` produce a magical effect.

### 4. Counterspell
You can however, target it at the casting time with [Counterspell](https://www.dndbeyond.com/spells/counterspell). It is clearly the lowest level spell that can work, though it has a hard DC, it requires you to have your reaction ready, and it requires the DM being very nice and letting you recognise what spell is being thrown at you ([not always the case](https://rpg.stackexchange.com/questions/46830/what-do-i-know-when-deciding-whether-to-cast-counterspell)).

> I generally allow identification of the spell as it's being cast (so players can decide whether to counterspell) on a successful `Arcana` check (DC set by how exposed they have been to the spell).

![counterspell](/imgs/antimagic/counterspell.png)

An sidenote; `Wild Shape` mentioned earlier, while magical (and `AMF`-cancellable), is not a spell. Therefore, you cannot target it with `Counterspell`. [Arch druids are fun](https://www.reddit.com/r/dndnext/comments/e3c47t/wait_are_archdruids_are_immune_to_counterspell/).

## Antimagic Field Concentration
Due to its hardline effect; `Crawford` notes that `AMF` is _intentionally a concentration spell that moves with you_, to give the players a chance to take out the mage. In conclusion; __don't put it on an item__.

Funny you should mention that. We were just about ready to venture into silly-territory:

## Cube of Force
[A cube with 36 fast-recharging charges](https://roll20.net/compendium/dnd5e/Cube%20of%20Force#content), and special effects for each face. Simplified flavour text:

> You can use an action to press one of the cube's faces. Each face has a different Effect. A barrier of Invisible force springs into existence, forming `a cube 15 feet on a side`. The barrier is `centered on you`, moves with you, and `lasts for 1 minute`, until you use an action to press the cube's sixth face, or the cube runs out of Charges.

> You can `change the barrier's Effect by pressing a different face` of the cube and expending the requisite number of Charges, `resetting the Duration`. If your Movement causes the barrier to come into contact with a solid object that can't pass through the cube, you can't move any closer to that object as long as the barrier remains.

![cube of force](/imgs/antimagic/cubeofforce.jpg)

### Face Effects:
- **1** Gases, wind, and fog can't pass through the barrier.
- **2** Nonliving matter can't pass through the barrier. Walls, floors, and ceilings can pass through at your discretion.
- **3** Living matter can't pass through the barrier. (`FC--`)
- **4** Spell Effects can't pass through the barrier. (`AMF--`)
- **5** Nothing can pass through the barrier. Walls, floors, and ceilings can pass through at your discretion. (`AMF--` + `FC--`)
- **6** The barrier deactivates.

<small>There's also a strange mechanic for number of chargers and a possibility of depleting it by hitting the barrier with certain high-levels spells, but this is not really relevant here.</small>

You'll note how much more loosely worded this is. It leaves a lot of room for interpretation, it does _not_ reference any spells it may mimic (unlike the Beholders Antimagic Cone), and thus these 8 word sentences are all we got. I noted what spells each face comes closest to in the list above, but a lot of questions ultimately arise:

### Questions
#### 1. Gas as in state of matter?
Meaning you could toss in a brick of liquid nitrogen and let it sublimate. How much of physics is valid in D&D?

No new breathable air goes in, incidentally. This shouldn't matter much other than if they spend more than an hour inside of the bubble; like spending an hour in a cramped, unventilated meeting room.

#### 1. Is cloudkill a gas?
The [Cloudkill](https://roll20.net/compendium/dnd5e/Cloudkill) gas is a magical effect that drops with _Concentration_, so it's not `matter` per se;

> `{living matter} ∪ {non-living matter} ≠ Multiverse`;
> Magical effects are neither.

Thus, this wording wouldn't be enough to stop the first example people think of.

#### 2. Non-living matter?
This is probably meant as an `Undead` shield, but be careful; a dead body still has living parts on it like cells and bacteria. You probably wouldn't want pass this barrier over the corpse of your friends if you want an easy resurrection.

#### 3. Living matter?
This sounds like `ForceCage`, but without the spell protection. You can protect yourself against arrows and charging enemies, but you cannot shoot out. You might just be trapped inside while enemies outside could target you with spells (or teleport inside).

#### 4. Spell effects passing through?
This one is hard. The wording of `passing through` is strange - as D&D spell movement is discrete - but presumably any spell effects that crosses the boundary would probably fail to have that effect on the inside, kind of like `AMF` - but this does not specify that it functions like `AMF`.

In fact it only says the effect itself, it does not limit spells being cast inside, or targetting from the outside. In this case it's actually the inverse of `FC`; spells can actually traverse the boundary, just effects can not. A caster could step 1ft out of the cube, cast fireball inside, remain undamaged while the inside would be a closed fire chamber.

This of course raises a lot more questions, but read on first.
#### 5. Nothing?
All matter, light, magical effects, spell effects, other forces. This is a real cage. You can't hear or see anything from the outside, and can relax in your (very visible) Sensory Deprivation. Incidentally, it is _omniphobic_; bad guys could just move it with `Telekinesis`. Bring this cube into a lava pool, then just wait for it to expire. It's not like anyone inside would know.

### This is dumb
This interpretation is clearly strange, but it's the most consistent with the remainder of antimagic AFAIKT. The item is just too ambiguous; the wording does not match anything else in the otherwise pretty consistent spell list.

The way we judged this in 2018 looks nothing like the above list, but our original interpretation also did not work out with respect to game balance.

`Crawford` noted in the interview that he was actually recommending the removal of `AMF` for 5th edition, as it just has too many corner cases. Clearly, it was too iconic to remove and `Wizards` have done a reasonable job of tackling the ambiguities that follow from it, but for the `Cube of Force`? [The silence speaks volumes](https://twitter.com/search?q=JeremyECrawford%20%22cube%20of%20force%22).

Just __don't use this item__. If you want this type of Legendary power, homebrew something using existing spells, but equally, __don't relieve a mage of antimagic concentration__. Here's an alternative - yet still very poweful - homebrew item:

![globe of invulnerability](/imgs/antimagic/globe_invuln.jpg)

### `Umberlee's Upheaval`
A legendary spell casters focus. You can cast the following spells once per day from the following list of spells. The sphere will maintain concentration on one spell at a time, until it has been made to drop it via a command word or if the item is dropped;

- [Hallow](https://5thsrd.org/spellcasting/spells/hallow/) (centered on the focus)
- [Blade Barrier](https://5thsrd.org/spellcasting/spells/blade_barrier/) (ringed wall around focus)
- [Freedom of Movement](https://www.dndbeyond.com/spells/freedom-of-movement) (20ft sphere around focus affecting everyone inside)

The focus is always the center of the spell. Attunement required by a `cleric`.

#### Is this good?
This is clearly very different; filled with largely protective/utility spells, modified to work in AOE around the focus. They all have well-defined use cases, and are all sufficiently different that they are all worth using. While it's still a bit half-baked on my end; compared to the `Cube of Force`? Easy substitute.

<!--
If you want a wizard/sorcerer/warlock based one, you could instead use the following spells:

- [Globe of Invulnerability](https://5thsrd.org/spellcasting/spells/globe_of_invulnerability/)
- [Resilient Sphere](https://5thsrd.org/spellcasting/spells/resilient_sphere/) (self only)

or a paladin based one:

- [Circle of Power](https://www.dndbeyond.com/spells/circle-of-power)
- [Aura of Purity](https://www.dndbeyond.com/spells/aura-of-purity)
- [Aura of Life](https://www.dndbeyond.com/spells/aura-of-life)
-->

### Ending thoughs
If you've followed me through this rabbit hole in fantasy rule research, congratulations. Hope this has been interesting. At the very least, I will feel a little more confident in running high level games that may or may not contain liches.
