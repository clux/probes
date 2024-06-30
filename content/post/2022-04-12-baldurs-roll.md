+++
date = "2022-04-12"
description = "Auto-rolling and getting nerd sniped before venturing forth"
title = "Baldur's Gate: Multinomial Edition"
slug = "2022-04-12-baldurs-roll"

[extra]
toc = true
math = true

[taxonomies]
categories = ["gaming"]
tags = ["math", "linux"]
+++

In a ~~brief~~ bout of escapism from the world and responsibilities, I booted up [Baldur's Gate 2](https://store.steampowered.com/app/257350/Baldurs_Gate_II_Enhanced_Edition/) with my brother. It's an amazing game, once you have figured out how to **[roll](https://old.reddit.com/r/baldursgate/search?q=roll&restrict_sr=on)** your character.

For today's installment; rather than telling you about the game, let's talk about the **maths** behind rolling a `2e` character for `BG2`, and then running simulations with weird `X`-based linux tools.

<!--more-->
<script src="https://cdn.plot.ly/plotly-2.26.0.min.js"></script>

## Rolling a character

The `BG2` character generation mechanics is almost entirely based on the rules from `AD&D 2e`. You get `6` ability scores, and each ability score is rolled as the sum of `3d6`.

> Probablistically; this **should** give you a character with an expected `63` total ability points (as a result of rolling `18d6`).

Mechanically, you are in this screen:

![bg2 stat rolling screen](/imgs/bg/rolling.png)

...and they have given you a `reroll` button.

It's a strange design idea to port the rolling mechanics from `d&d` into this game. In a normal campaign you'd usually get one chance rolling, but here, there's no downside to keeping going; encouraging excessive time investment (the irony in writing a blog post on this is not lost on me). <small>The character creation in BG2 would probably have been less perfection focused if they'd gone for something like [5e point buy](https://chicken-dinner.com/5e/5e-point-buy.html).</small>

Anyway, **suppose** you want learn how to automate this, or you just want to think about combinatorics, multinomials, and weird `X` tools for a while, then this is the right place. You will also figure out **how long it's expected to take** to roll high.

> HINT: ..it's less time than it took to write this blogpost

## Disclaimer

Using the script used herein to achieve higher rolls than you have patience for, is on some level; cheating. That said, it's a fairly pointless effort:

- this is an [old](https://en.wikipedia.org/wiki/Baldur%27s_Gate_II:_Shadows_of_Amn), unranked rpg with difficulty settings
- having [dump stats](https://tvtropes.org/pmwiki/pmwiki.php/Main/DumpStat) is not heavily penalized in the game
- early items nullify effects of common dump stats ([19 STR girdle](https://baldursgate.fandom.com/wiki/Girdle_of_Hill_Giant_Strength) or [18 CHA ring](https://baldursgate.fandom.com/wiki/Ring_of_Human_Influence))
- you can get [max stats in 20 minutes](https://www.youtube.com/watch?v=5dDmh98lmkA) with by abusing inventory+stat [underflow](https://baldursgate.fandom.com/wiki/Exploits#Potion_Swap_Glitch)
- some [NPCS](https://baldursgate.fandom.com/wiki/Edwin_Odesseiron) come with [gear](https://baldursgate.fandom.com/wiki/Edwin%27s_Amulet) that blows __marginally better stats__ out of the water

So assuming you have a reason to be here despite this; let's dive in to some maths.

## Multinomials and probabilities

> How likely are you to get a 90/95/100?

The sum of rolling 18 six-sided dice follows an easier variant of the [multinomial distribution](https://en.wikipedia.org/wiki/Multinomial_distribution) where we have equal event probabilities. We are going to follow the _simpler_ multinomial expansion from [mathworld/Dice](https://mathworld.wolfram.com/Dice.html) for `s=6` and `n=18` and find $P(x, 18, 6)$ which we will denote as $P(X = x)$; the chance of rolling a sum equal to $x$:

$$P(X = x) = \frac{1}{6^{18}} \sum_{k=0}^{\lfloor(x-18)/6\rfloor} (-1)^k \binom{18}{k} \binom{x-6k-1}{17}$$
$$ = \sum_{k=0}^{\lfloor(x-18)/6\rfloor} (-1)^k \frac{18}{k!(18-k)!} \frac{(x-6k-1)!}{(x-6k-18)!}$$

If we were to expand this expression, we would get 15 different expressions depending on how big of an $x$ you want to determine. So rather than trying to reduce this to a polynomial expression over $p$, we will [paste values into wolfram alpha](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C18%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%2918%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2991-6k-1%5C%2844%29+17%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2991-18%5C%2841%29%2C6%5D%5C%2841%29%7D%5D) and tabulate for $[18, \ldots, 108]$.

You can see the <a href="#appendix">appendix</a> for the numbers. Here we will just plot the values:

<div id="probhist" style="width:600px;height:450px;"></div>

<script>
// keys [18, 108]
var ALL_X = [...Array(109).keys()].slice(18);

// probabilities for p=18 up to p=108 (sums to 0.9999999999999999 \o/)
var MAIN_PROBS = [1/101559956668416, 1/5642219814912, 19/11284439629824, 95/8463329722368, 665/11284439629824, 1463/5642219814912, 33643/33853318889472, 9605/2821109907456, 119833/11284439629824, 1552015/50779978334208, 308465/3761479876608, 97223/470184984576, 2782169/5642219814912, 1051229/940369969152, 4550747/1880739938304, 786505/156728328192, 37624655/3761479876608, 36131483/1880739938304, 1206294965/33853318889472, 20045551/313456656384, 139474379/1253826625536, 1059736685/5642219814912, 128825225/417942208512, 17143871/34828517376, 8640663457/11284439629824, 728073331/626913312768, 2155134523/1253826625536, 3942228889/1586874322944, 4949217565/1410554953728, 3417441745/705277476864, 27703245169/4231664861184, 3052981465/352638738432, 126513483013/11284439629824, 240741263447/16926659444736, 199524184055/11284439629824, 60788736553/2821109907456, 2615090074301/101559956668416, 56759069113/1880739938304, 130521904423/3761479876608, 110438453753/2821109907456, 163027882055/3761479876608, 88576807769/1880739938304, 566880747559/11284439629824, 24732579319/470184984576, 101698030955/1880739938304, 461867856157/8463329722368, 101698030955/1880739938304, 24732579319/470184984576, 566880747559/11284439629824, 88576807769/1880739938304, 163027882055/3761479876608, 110438453753/2821109907456, 130521904423/3761479876608, 56759069113/1880739938304, 2615090074301/101559956668416, 60788736553/2821109907456, 199524184055/11284439629824, 240741263447/16926659444736, 126513483013/11284439629824, 3052981465/352638738432, 27703245169/4231664861184, 3417441745/705277476864, 4949217565/1410554953728, 3942228889/1586874322944, 2155134523/1253826625536, 728073331/626913312768, 8640663457/11284439629824, 17143871/34828517376, 128825225/417942208512, 1059736685/5642219814912, 139474379/1253826625536, 20045551/313456656384, 1206294965/33853318889472, 36131483/1880739938304, 37624655/3761479876608, 786505/156728328192, 4550747/1880739938304, 1051229/940369969152, 2782169/5642219814912, 97223/470184984576, 308465/3761479876608, 1552015/50779978334208, 119833/11284439629824, 9605/2821109907456, 33643/33853318889472, 1463/5642219814912, 665/11284439629824, 95/8463329722368, 19/11284439629824, 1/5642219814912, 1/101559956668416];

var MAIN_LEGEND = MAIN_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls")

var trace = {
  x: ALL_X,
  y: MAIN_PROBS,
  name: 'probability',
  text: MAIN_LEGEND,
  opacity: 0.8,
  type: "scatter",
};
var plotlycfg = {responsive: true};


var data = [trace];
var layout = {
  title: "Distribution for the sum of 18d6 dice rolls",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist'), data, layout, plotlycfg);

// extra: precise expectation and variance
var expectation_orig = MAIN_PROBS.map((x,i) => (i+18)*x).reduce((acc, e) => acc+e, 0);
var variance_orig = MAIN_PROBS.map((x,i) => Math.pow(i+18 - expectation_orig, 2)*x).reduce((acc, e) => acc+e, 0);
console.log("Precise Expectation and variance for 18d6", expectation_orig, variance_orig);
</script>

and with the precise distribution we can also calculation expectation and variance:

- $E(X) = 63$
- $Var(X) = 52.5 \thickapprox 7.24^2$

This is how things **should** look on paper. From the chart you can extract:

- `108` would be a once in `101 trillion` ($6^{18}$) event
- `107` would be a once in `5 trillion` event (`6^18/18`)
- `106` would be a once in `600 billion` event (5s in two places, or 4 in one place)
- `105` would be a once in `90 billion` event (3x5s, or 1x4 and 1x5, or 1x3)
- `104` would be a once in `16 billion` event (4x5s, 2x5s and 1x4, 2x4s, 1x5 and 1x3, 1x2)
- `103` would be a once in `4 billion` event (...)
- `102` would be a once in `1 billion` event
- `101` would be a once in `290 million` event
- `100` would be a once in `94 million` event
- `99` would be a once in `32 million` event
- $\ldots$
- `95` would be a once in `900k` event (first number with prob < 1 in a million)

**But is this really right for BG?** A [lot](https://old.reddit.com/r/baldursgate/comments/svnyy5/this_is_why_i_let_my_gf_roll_my_stats_lol/hxhde5k/) of [people](https://old.reddit.com/r/baldursgate/comments/tak2m7/say_hello_to_my_archer_roll/) have [all](https://old.reddit.com/r/baldursgate/comments/rjnw22/less_than_a_minute_of_rolling_this_is_my_alltime/) rolled nineties in just a few hundred rolls, and many even getting [100](https://old.reddit.com/r/baldursgate/comments/phr68a/my_new_highest_roll_10049_elf_mclovin_fightermage/) or [more](https://old.reddit.com/r/baldursgate/comments/sq54wo/how_high_can_you_roll/)..was that extreme luck, or are higher numbers more likely than what this distribution says?

Well, let's start with the obvious:

> **The distribution is [censored](https://en.wikipedia.org/wiki/Censoring_(statistics)). We don't see the rolls below $75$.**

<div id="probhist2" style="width:600px;height:450px;"></div>

<script>
var data = [{
  x: ALL_X,
  y: MAIN_PROBS,
  name: 'probability',
  text: MAIN_LEGEND,
  opacity: 0.8,
  type: "scatter",
}];
var layout = {
  annotations: [
   {
     y: 1/70,
     x: 75,
     xref: 'x',
     yref: 'y',
     text: 'cutoff',
     showarrow: true,
     arrowhead: 7,
     arrowcolor: "blue",
     ax: 0,
     ay: -40
   },
  ],
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist2'), data, layout, plotlycfg);
</script>

What's **left of this cutoff** actually accounts for around `94%` of the distribution. **If** the game **did not do this**, you'd be as likely getting `36` as a `90`. We are effectively throwing away "19 bad rolls" on every roll.

> `AD&D 2e` had its [own ways to tilt the distribution](https://advanced-dungeons-dragons-2nd-edition.fandom.com/wiki/Rolling_Ability_Scores) in a way that resulted in more powerful characters.

How such a truncation or censoring is performed is at the mercy of the BG engine. We will [rectify](https://en.wikipedia.org/wiki/Rectified_Gaussian_distribution) the distribution by **scaling up** the truncated version of our distribution, and show that this is correct later.

<div id="probhist3" style="width:600px;height:450px;"></div>

<script>
var prob_over_74 = MAIN_PROBS.slice(75-18).reduce((acc, e) => acc + e, 0);
var SCALED_PROBS = MAIN_PROBS.slice(75-18).map(x => x / prob_over_74); // scale up by whats left

var scaled_legend = SCALED_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls");

//console.log("probability of rolling gte 75", prob_over_74);
//console.log(SCALED_PROBS.reduce((acc, e) => acc + e, 0)); // 1!
var trace = {
  x: ALL_X.slice(75-18),
  y: SCALED_PROBS,
  name: 'probability',
  text: scaled_legend,
  opacity: 0.8,
  type: "scatter",
};

var data = [trace];
var layout = {
  title: "Scaled Distribution",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist3'), data, layout, plotlycfg);

// extra: precise expectation and variance
var expectation_trunc = SCALED_PROBS.map((x,i) => (i+75)*x).reduce((acc, e) => acc+e, 0);
var variance_trunc = SCALED_PROBS.map((x,i) => Math.pow(i+75 - expectation_trunc, 2)*x).reduce((acc, e) => acc+e, 0);
console.log("Precise Truncated Expectation and variance for 18d6", expectation_trunc, variance_trunc);

</script>

Here we have divided by the sum of the probabilities of the right hand side of the graph $P(X \ge 75)$ to get the new probability sum to `1`.

Using this scaled data, we can get precise, truncated distribution parameters:

- $E(X_T) = 77.525$
- $Var(X_T) = 2.61^2$

This _censored 18d6 multinomial distribution_ is actually very close for certain cases, and we will **demonstrate** this.

But first, we are going to need to press the `reroll` button a lot...

## Automating Rolling

The simulation script / hacks we made is [found here](https://github.com/Thhethssmuz/bg2ee-stat-roll).

### Tools

We are playing on **Linux** with `X` and some obscure associated tooling:

- `scrot` - X screenshot utility
- `xdotool` - X CLI automation tool
- `xwininfo` - X window information utility

Basic strategy;

- find out where buttons are with `xwininfo`
- press the `reroll` button with `xdotool`
- take screenshot of the `total` number with `scrot`
- compare screenshot to previous rolls
- press `store` when a new maximum is found

The script also does some extra stuff to determine the strength roll, but that's not relevant here.

### Initialization

To standardise what we are taking screenshots of, we need a consistent frame of reference.

`xwininfo` will give us the `x,y` coordinates of the top left corner of the game window, and then hard-code the offsets from that because the game has a consistent layout. There is [some complexity](https://github.com/Thhethssmuz/bg2ee-stat-roll/blob/5a023de83c468224aa999b5b3c60f224aae76b97/roll.sh#L20-L84) in doing this, but it has so far worked well.

> **Caveat**: You need to have **scaled the window** to size >= 1024x768 to avoid UI downscaling.

The standardised approach also helps with dealing with rolls, and it let us populate a roll-table quickly.

### Roll Tables

Taking screenshots is pretty easy. Use `scrot` at an `x,y` coordinate followed by lenghts; `,width,height` as remaining arguments defining the square to screenshot:

```sh
scrot -a "${STR_TOP_LEFT_X},${STR_TOP_LEFT_Y},49,17" -
```

the output of this can be piped to a `.webp`webpd passed to `compare` (part of `imagemagick` package), to compare values based on thresholds. However, this idea is actually overkill..

The menu background is **static** and the resulting screenshots are actually **completely deterministic per value**, so we can instead just compare them by their hashes in one big `switch` (i.e. after piping to `md5`) and use that as our [roll table](https://github.com/Thhethssmuz/bg2ee-stat-roll/blob/5a023de83c468224aa999b5b3c60f224aae76b97/roll.sh#L130-L159), Excerpt:

```sh
    d74939b47327e4f2c1b781d64e2ab28d*) CURRENT_ROLL=90 ;;
    ca49ce8b4c9c0f814dab24668f7313fe*) CURRENT_ROLL=91 ;;
    3e6f8127ac0634bb1fc20acf40c95c48*) CURRENT_ROLL=92 ;;
    7f849edd84a4be895f5c58b4f5b20d4e*) CURRENT_ROLL=93 ;;
    b8f90179e2a0e975fc2647bc7439d9c6*) CURRENT_ROLL=94 ;;
    b1d3b73de16d750b265f5c63000ccd54*) CURRENT_ROLL=95 ;;
    87413f7310bd06b0b66fb4d2e61c5c7a*) CURRENT_ROLL=96 ;;
    b489ad2a17456f8eebe843e4b7e3e685*) CURRENT_ROLL=97 ;;
    25112e67464791f24f9e2e99d38ef9d7*) CURRENT_ROLL=98 ;;
    9c3720b9d3ab1d7f0d11dfb9771a1aef*) CURRENT_ROLL=99 ;;
    3ef9bf6cd4d9946d89765870e5b21566*) CURRENT_ROLL=100 ;;
```

### Clicking

Automating a click is simply:

```sh
xdotool mousemove "$REROLL_BTN_X" "$REROLL_BTN_Y" click --delay=0 1
```

where the `--delay=0` overrides a builtin delay between clicks.

The only complication here is that BG performs **internal buffering** of clicks, so this allows us to blast through numbers faster than the screen can display them. This means we have to compensate with a `sleep 0.001` after clicking to ensure we can grab the `scrot` of the roll before another click is registered.

### Showcase

Running the script (with a terminal showing the script output overlayed) looks like this:

{{  youtube(id="849xInj3GmI") }}

On my machine, we get just over **15 rolls per second**.

## Sampling

We rolled a human `fighter`, `paladin`, and a `ranger` overnight with roughly half a million rolls each (see <a href="#appendix">appendix</a>), and we got these values:

<div id="rollhist" style="width:600px;height:450px;"></div>

<script>
// keys [75, 108]
var x = [...Array(109).keys()].slice(75);

// number of samples per class
var samples = {
  //  fighter (75 -> 98)
  "fighter": [137379, 109198, 85620, 65004, 48256, 35041, 24987, 17545, 11981, 7883, 5007, 3139, 1946, 1138, 670, 368, 199, 103, 49, 26, 12, 6, 2, 1],
  // paladin (75 -> 102)
  "paladin": [50888, 54911, 57338, 57442, 55589, 52357, 47503, 41339, 34458, 28599, 21997, 16722, 12322, 8697, 5997, 3774, 2371, 1489, 822, 465, 251, 129, 56, 24, 12, 4, 1, 1],

  // ranger (75 -> 100)
  "ranger": [32296, 37790, 43118, 46609, 48108, 47589, 45774, 41963, 36876, 30973, 25272, 19904, 14730, 10430, 7285, 4667, 2991, 1696, 986, 529, 254, 121, 56, 26, 10, 1],
};

var trace_observations = function(klss) {
  var sample_klss = samples[klss];
  let num_samples = sample_klss.reduce((acc, e) => acc+e, 0);
  var observed_probs = sample_klss.map(x => x / num_samples);

  // TODO: estimate expecation and variance here?
  return {
    x: x,
    y: observed_probs,
    name: 'observed ' + klss,
    text: observed_probs.map(x => "occurred once in " + Math.floor(1/x) + " rolls"),
    opacity: 0.8,
    type: "scatter",
  };
};

var trace_obs_fighter = trace_observations('fighter');
var trace_obs_paladin = trace_observations('paladin');
var trace_obs_ranger = trace_observations('ranger');

var data = [trace_obs_fighter, trace_obs_paladin, trace_obs_ranger];
var layout = {
  title: "Roll Results",
  xaxis: {title: "Roll"},
  yaxis: {title: "Observed probability"},
};
Plotly.newPlot(document.getElementById('rollhist'), data, layout, plotlycfg);
</script>

Let's start with the **fighter**. If we compare the fighter graph with our precise, censored multinomial distribution, they are **very close**:

<div id="probhist4" style="width:600px;height:450px;"></div>

<script>
var prob_over_74 = MAIN_PROBS.slice(75-18).reduce((acc, e) => acc + e, 0);
var SCALED_PROBS = MAIN_PROBS.slice(75-18).map(x => x / prob_over_74); // scale up by whats left

var scaled_legend = SCALED_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls");

let trace_single_trunc = {
  x: ALL_X.slice(75-18),
  y: SCALED_PROBS,
  name: 'fighter multinomial 18d6',
  text: scaled_legend,
  opacity: 0.8,
  type: "scatter",
};

var data = [trace_single_trunc, trace_obs_fighter];
var layout = {
  title: "Distribution vs. Observed Fighter",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist4'), data, layout, plotlycfg);
</script>

So for **fighters**, we can be pretty happy with the calculations we have done, and can use the precise probabilities as a guide.

> How long would it take you to achieve >95 for a fighter using the script?

- `108` is a once in `5 trillion` event (10,000 years)
- `107` is a once in `300 billion` event (600 years)
- `106` is a once in `33 billion` event (69 years)
- `105` is a once in `5 billion` event (10 years)
- `104` is a once in `900 million` event (2 years)
- `103` is a once in `200 million` event (5 months)
- `102` is a once in `50 million` event (5 weeks)
- `101` is a once in `16 million` event (2 weeks)
- `100` is a once in `5 million` event (4 days)
- `99` is a once in `2 million` event (1.5 day)
- `98` is a once in `700k` event (12h)
- `97` is a once in `270k` event (5h)
- `96` is a once in `110k` event (2h)
- `95` is a once in `50k` event (55m)

So if we only look at human fighters or mages, we can stop here:

> We are actually quite a lot more likely to get a good roll early than what just the pure dice math would indicate thanks to censoring (50k rolls => likely `95` rather than estimated `90` without censoring).

However, what's up with the paladins and rangers? Time for a more painful math detour.

![sweat mile cat math](/imgs/bg/amicat1-math.webp)

## Class Variance

The reason for the discrepancy is simple: [stat floors based on races/class](https://rpg.stackexchange.com/questions/165377/how-do-baldurs-gate-and-baldurs-gate-2s-rolling-for-stats-actually-get-gene).

These stat floors are insignificant in some cases, but highly significant in others. Some highly floored classes actually push the uncensored mean above the `75` cutoff even though it's a whole 12 points above the mean of the original underlying distribution.

The floors for a some of the classes:

- **fighter** mins: `STR=9`, rest `3`
- **mage** mins: `INT=9`, rest `3`
- **paladin** mins: `CHA=17`, `WIS=13`, `STR=12`, `CON=9`, rest `3`
- **ranger** mins: `CON=14`, `WIS=14`, `STR=13`, `DEX=13`, rest `3`
- **[other classes](https://old.reddit.com/r/baldursgate/comments/reevp6/everyone_enjoys_a_good_high_ability_score_role_so/)** mins: generally light floors

_In other words_: paladins and rangers have significantly higher rolls on average.

> Sidenote: in `2e` you actually rolled stats first, and **only if** you met the **requirements** could you become a Paladin / Ranger. It's an interesting choice..

Is it possible to incorporate these floors into our modelling?

## Ability Distributions

If floors are involved at earlier stages, we have to take a step back and look at the distributions that make up the sum. We __can__ compute distributions for **individual ability scores** (even if floored) if we use the distribution for $P(x, 3, 6)$ from [mathworld/Dice](https://mathworld.wolfram.com/Dice.html) where `s=6` and `n=3` and censor it at a cutoff point similar to how we censor the total distribution.

Computing the value without a floor follows the same setup as when we did 18 dice; use [wolfram alpha](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C3%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%293%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2910-6k-1%5C%2844%29+2%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2910-3%5C%2841%29%2C6%5D%5C%2841%29%7D%5D) and tabulate for $[3, \ldots, 18]$:

<div id="probhist3roll" style="width:600px;height:450px;"></div>

<script>
var THREEROLL_X = [3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18];
// probabilities for p=3 up to p=18 (also sums to 0.9999999999999999)
var THREEROLL_PROBS = [1/216, 1/72, 1/36, 5/108, 5/72, 7/72, 25/216, 1/8, 1/8, 25/216, 7/72, 5/72, 5/108, 1/36, 1/72, 1/216];
console.log("probability sum for 3d6 =", THREEROLL_PROBS.reduce((acc, e) => acc+e, 0));

var expectation_unt = THREEROLL_PROBS.map((x,i) => (i+3)*x).reduce((acc, e) => acc+e, 0);
var variance_unt = THREEROLL_PROBS.map((x,i) => Math.pow(i+3 - expectation_unt, 2)*x).reduce((acc, e) => acc+e, 0);
console.log("Expectation, variance for untruncated 3d6", expectation_unt, variance_unt);

var trace = {
  x: THREEROLL_X,
  y: THREEROLL_PROBS,
  name: 'probability',
  text: THREEROLL_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls"),
  opacity: 0.8,
  type: "scatter",
};
var data = [trace];
var layout = {
  title: "Distribution for the sum of 3d6 dice rolls",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist3roll'), data, layout, plotlycfg);
</script>

then we truncate + scale this at the observed floor points `9`, `12`, `13`, `14`, and `17`:


<div id="probhist3rolltruncs" style="width:600px;height:450px;"></div>

<script>
var TRUNCATED_DISTS = {};
TRUNCATED_DISTS[0] = THREEROLL_PROBS.slice();
TRUNCATED_DISTS[3] = THREEROLL_PROBS.slice(); // no truncation == truncation at 3
var truncated_trace = function (t) {
  // calculate probability up to cutoff point:
  var TRUNC_T_SUM = THREEROLL_PROBS.slice(t-3).reduce((acc, e) => acc+e, 0);
  // truncate and scale (rectify) the right side of the distribution:
  var THREE_TRUNC_T = THREEROLL_PROBS.slice(t-3).map(x => x / TRUNC_T_SUM);
  // sanity sum (all 1)
  //console.log("Sum of 3d6 truncated at ", t, ":", THREE_TRUNC_T.reduce((acc, e)=>acc+e, 0));
  var expectation = THREE_TRUNC_T.map((x,i) => (i+t)*x).reduce((acc, e) => acc+e, 0);
  var variance = THREE_TRUNC_T.map((x,i) => Math.pow(i+t - expectation, 2)*x).reduce((acc, e) => acc+e, 0);
  console.log("Expectation, variance for truncated 3d6 at", t, expectation, variance);
  TRUNCATED_DISTS[t] = THREE_TRUNC_T;
  var trace = {
    x: THREEROLL_X.slice(t-3),
    y: THREE_TRUNC_T,
    name: 'floor ' + t,
    text: THREE_TRUNC_T.map(x => "expected once in " + Intl.NumberFormat('en-IN', {maximumSignificantDigits: 2}).format(1/x) + " rolls"),
    opacity: 0.8,
    type: "scatter",
  };
  return trace;
};

let trace_9 = truncated_trace(9);
let trace_12 = truncated_trace(12);
let trace_13 = truncated_trace(13);
let trace_14 = truncated_trace(14);
let trace_17 = truncated_trace(17);

var data = [trace_9, trace_12, trace_13, trace_14, trace_17];
var layout = {
  title: "Rectified Distribution for the sum of 3d6 dice rolls",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist3rolltruncs'), data, layout, plotlycfg);
</script>

To avoid having to write out conditionals $P(X = x| X\ge k)$ everywhere we will denote $X^{\lfloor k \rfloor}$ as one of these graphed multinomial distributions for the sum of `3d6` floored at $k$:

$$X^{\lfloor k \rfloor} \sim \mathcal{M}^{\lfloor k \rfloor}(3d6)$$

Note also that an unfloored ability score $X$ is equal to $X^{\lfloor3\rfloor}$.

We can then compute precise conditional expectations by floor:

- $\mathbb{E}(X^{\lfloor3\rfloor}) = \mathbb{E}(X) = 3\sum_{k=1}^{6}\frac{k}{6} = 3*3.5 = 10.5$
- $\mathbb{E}(X^{\lfloor9\rfloor}) = 11.8125$
- $\mathbb{E}(X^{\lfloor12\rfloor}) = 13.5555$
- $\mathbb{E}(X^{\lfloor13\rfloor}) = 14.2500$
- $\mathbb{E}(X^{\lfloor14\rfloor}) = 15.0000$
- $\mathbb{E}(X^{\lfloor17\rfloor}) = 17.2500$

Similarly, we can compute precise variances:

- $Var(X^{\lfloor3\rfloor}) = Var(X) = 3\sum_{k=1}^6\frac{(x_i - 3.5)^2}{6} = 3*2.92 = 8.75$
- $Var(X^{\lfloor9\rfloor}) = 4.5773$
- $Var(X^{\lfloor12\rfloor}) = 2.2469$
- $Var(X^{\lfloor13\rfloor}) = 1.6875$
- $Var(X^{\lfloor14\rfloor}) = 1.2000$
- $Var(X^{\lfloor17\rfloor}) = 0.1875$

### Sum of Ability Distributions

To get a distribution for the total score, we need to create a sum distribution of the distributions for their six base stats at their given class floors.

Define $Z_{paladin}$, $Z_{ranger}$ and $Z_{fighter}$ as:

$$Z_{paladin} = X_1^{\lfloor17\rfloor} + X_2^{\lfloor13\rfloor} + X_3^{\lfloor12\rfloor} + X_4^{\lfloor9\rfloor} + X_5^{\lfloor3\rfloor} + X_6^{\lfloor3\rfloor}$$
$$Z_{ranger} = X_1^{\lfloor14\rfloor} + X_2^{\lfloor14\rfloor} + X_3^{\lfloor13\rfloor} + X_4^{\lfloor13\rfloor} + X_5^{\lfloor3\rfloor} + X_6^{\lfloor3\rfloor}$$
$$Z_{fighter} = X_1^{\lfloor9\rfloor} + X_2^{\lfloor3\rfloor} + X_3^{\lfloor3\rfloor} + X_4^{\lfloor3\rfloor} + X_5^{\lfloor3\rfloor} + X_6^{\lfloor3\rfloor}$$

for floored 3d6 based random variables $X_i^{\lfloor N \rfloor}  \sim \mathcal{M}^{\lfloor N \rfloor}(3d6)$.

Using the computed expectations above to sum across the 6 main stats:

- $\mathbb{E}(Fighter) = \mathbb{E}(X^{\lfloor9\rfloor}) + 5\mathbb{E}(X) = 64.31$
- $\mathbb{E}(Ranger) = 2\mathbb{E}(X^{\lfloor14\rfloor}) + 2\mathbb{E}(X^{\lfloor13\rfloor}) + 2\mathbb{E}(X) = 79.5$
- $\mathbb{E}(Paladin) = \mathbb{E}(X^{\lfloor17\rfloor}) + \mathbb{E}(X^{\lfloor13\rfloor}) + \mathbb{E}(X^{\lfloor12\rfloor}) + \mathbb{E}(X^{\lfloor9\rfloor})+ 2\mathbb{E}(X) = 77.86$


and similarly for variance:

- $Var(Fighter) = Var(X^{\lfloor9\rfloor}) + 5Var(X) \thickapprox 6.95^2$
- $Var(Ranger) = 2Var(X^{\lfloor14\rfloor}) + 2Var(X^{\lfloor13\rfloor}) + 2Var(X) \thickapprox 4.82^2$
- $Var(Paladin) = Var(X^{\lfloor17\rfloor}) + Var(X^{\lfloor13\rfloor}) + Var(X^{\lfloor12\rfloor}) + Var(X^{\lfloor3\rfloor})+ 2Var(X) \thickapprox 5.12^2$

noting that variables are independent under the observed two stage censoring.

> Why can we rely on two stage censoring and their independence? If any of these internal mechanisms used some kind of `if` condition or `min` function, it would be immediately obvious from the distribution. The paladin distribution of charisma is clearly a `~1/4` for an `18`, and `~3/4` for a `17`; it would have been much rarer to see an 18 otherwise.

Thus, the distributions of our classes are based on multinomal-based distributions with the following first moments:

- $Uncensored\ Fighter \sim \mathcal{M}(\mu = 64.31, \sigma^2 = 6.95^2)$
- $Uncensored\ Ranger \sim \mathcal{M}(\mu = 79.5, \sigma^2 = 4.82^2)$
- $Uncensored\ Paladin \sim \mathcal{M}(\mu = 77.86, \sigma^2 = 5.12^2)$

This is nice as a quick overview of what's best in the higher ranges, but it's not very precise. Without the **[PMF](https://en.wikipedia.org/wiki/Probability_mass_function)** for the **sum of our ability scores**, it's hard to give good values for what the truncated version will look like (we are censoring in two stages). In particular, these heavily floored random variables end up giving us quite asymmetrical distributions in the tails.

### Class Distributions

Thankfully, it is possible to inductively compute the pmf of $Z_{class}$ via [convolution](https://en.wikipedia.org/wiki/Convolution#Discrete_convolution).

Some internet digging notwithstanding; most answers found online for this required **either** [mathematica functions](https://stats.stackexchange.com/questions/3614/how-to-easily-determine-the-results-distribution-for-multiple-dice/3684#3684) (that we do not have here in our inlined source), **or** a slightly more laborious manual convolution. We will follow the [inductive convolution approach](https://stats.libretexts.org/Bookshelves/Probability_Theory/Book%3A_Introductory_Probability_(Grinstead_and_Snell)/07%3A_Sums_of_Random_Variables/7.01%3A_Sums_of_Discrete_Random_Variables) which we can solve with recursion. Paladin case:

Let $X_{12} = X_1^{\lfloor17\rfloor} + X_2^{\lfloor13\rfloor}$. We can generate values for the pmf $p_{X_{12}}$ for $X_{12}$ via the pmfs $p_{X_i}$ for $X_1^{\lfloor17\rfloor}$ and $X_2^{\lfloor13\rfloor}$ via the convolution formula:

$$P(X_{12} = n) = \\ (p_{X_1} * p_{X_2})(n) = \sum_{m=-\infty}^{\infty}P(X_1=m)P(X_2 = n-m)$$

This step is particularly easy for the paladin, because $X_1^{\lfloor17\rfloor}$ only takes two values (i.e. $m=17$ ahd $m=18$ are the only non-zero parts in the sum).

The rest is more laborious to do by hand, as the sums get increasingly large while we iterate towards $Z=P_{123456}$ by repeatedly applying convolution to the remaining $X_i$:

$$P(X_{123} = n) = \\ (p_{X_{12}} * p_{X_3})(n) \sum_{m=-\infty}^{\infty}P(X_{12}=m)P(X_3 = n-m)$$

$$P(X_{1234} = n) = \\ (p_{X_{123}} * p_{X_4})(n) \sum_{m=-\infty}^{\infty}P(X_{123}=m)P(X_4 = n-m)$$

$$P(X_{12345} = n) = \\ (p_{X_{1234}} * p_{X_5})(n) \sum_{m=-\infty}^{\infty}P(X_{1234}=m)P(X_5 = n-m)$$

$$P(X_{123456} = n) = \\ (p_{X_{12345}} * p_{X_5})(n) \sum_{m=-\infty}^{\infty}P(X_{12345}=m)P(X_6 = n-m)$$

The hard work is correctly matching indexes in our probability arrays that serve as our mass functions to the sum, and defaulting to zero when accessing out of bounds:

```js
// given pXi = [0.75, 0.25], pXj = [0.375, 0.2678, 0.1786, 0.1071, 0.05357, 0.01786]
// (approximations of the first two truncated paladin probability arrays for CHA + WIS)
var convolve = function (pXi, pXj) {
  // pre-allocate a zero-indexed array where our probabilities will go
  var pXij = [...Array(pXi.length + pXj.length - 1).keys()];
  // loop to generate P(Xij = n) for all n
  for (let n = 0; n < pXi.length + pXj.length - 1; n += 1) {
    pXij[n] = 0; // init to zero
    // loop to do sum over m, first variable determines length of this sum
    for (let m = 0; m < pXi.length; m += 1) {
      // we do defaulting outside range with `|| 0`
      pXij[n] += (pXi[m] || 0) * (pXj[n-m] || 0);
    }
  }
  return pXij;
};
// returns [0.28125, 0.29464, 0.2009, 0.125, 0.06696, 0.02678, 0.004464]
```

Using this, we can compute the PMF for $Z_{class} = X_{123456}$:

$$P(Z_{class} = z) = \\ (((((p_{X_1} * p_{X_2}) * p_{X_3}) * p_{X_4}) * p_{X_5}) * p_{X_6}) (z)$$

and we graph them for various classes:

<div id="probhist3convolved" style="width:600px;height:450px;"></div>

<script>
// The first one is easy, P_1 only has 2 values => m={0,1}
//let pX1 = TRUNCATED_DISTS[17]; // 2 values, for 17,18
//let pX2 = TRUNCATED_DISTS[13]; // 6 values, for 13,...,18
//console.log("convolving", pX1, pX2)
// new dist starts at 17+13 and goes to 18x2
//let pX12 = [];
//pX12[0] = pX1[0] * pX2[0]; // 17+13 || 18+12 (zero)
//pX12[1] = pX1[0] * pX2[1] + pX1[1]*pX2[0]; // 17+14 || 18+13
//pX12[2] = pX1[0] * pX2[2] + pX1[1]*pX2[1]; // 17+15 || 18+14
//pX12[3] = pX1[0] * pX2[3] + pX1[1]*pX2[2]; // 17+16 || 18+15
//pX12[4] = pX1[0] * pX2[4] + pX1[1]*pX2[3]; // 17+17 || 18+16
//pX12[5] = pX1[0] * pX2[5] + pX1[1]*pX2[4]; // 17+18 || 18+17
//pX12[6] =                 + pX1[1]*pX2[5]; // 17+19 (zero) || 18+18
//console.log(pX12, pX12.reduce((acc,e)=>acc+e,0)); // perfect

// then do P_{12} + P_3
//pX12 has 7 values, for 30, 31, 32, 33, 34, 35, 36
//let pX3 = TRUNCATED_DISTS[12]; // has 7 values, for 12,13,14,15,16,17,18
// new dist starts at 30+12 and goes to 18x3 i.e. length (13)
//let pX123 = [];
//pX123[0] = pX12[0]*pX3[0]; // 42 : 30+12
//pX123[1] = pX12[0]*pX3[1] + pX12[1]*pX3[0]; // 43: 30+13 || 31+12
//pX123[2] = pX12[0]*pX3[2] + pX12[1]*pX3[1] + pX12[2]*pX3[0]; // 44: 30+14 || 31+13 || 32+12
//pX123[3] = pX12[0]*pX3[3] + pX12[1]*pX3[2] + pX12[2]*pX3[1] + pX12[3] +pX3[0]; // 45: 30+15 || 31+14 || 32+13 || 33+12
// ok... clearly not a hand written thing, but matches convolve result

// what am i doing with my life
var convolve = function (pXi, pXj) {
  // pre-allocate a zero-indexed array where our probabilities will go
  var pXij = [...Array(pXi.length + pXj.length - 1).keys()];
  // loop to generate P(Xij = n) for all n
  for (let n = 0; n < pXi.length + pXj.length - 1; n += 1) {
    pXij[n] = 0; // init to zero
    // loop to do sum over m, first variable determines length of this sum
    for (let m = 0; m < pXi.length; m += 1) {
      // we do defaulting outside range with `|| 0`
      pXij[n] += (pXi[m] || 0) * (pXj[n-m] || 0);
    }
  }
  return pXij;
}

// doing paladin from function above:
//let pX1 = TRUNCATED_DISTS[17]; // 2 values; 17,18
//let pX2 = TRUNCATED_DISTS[13]; // 6 values; 13,...,18
//let pX3 = TRUNCATED_DISTS[12]; // 7 values; 12,13,14,15,16,17,18
//let pX4 = TRUNCATED_DISTS[9]; // 10 values; 9,...,18
//let pX5 = TRUNCATED_DISTS[3]; // 16 values; 3,...,18
//let pX6 = TRUNCATED_DISTS[3]; // ditto
//let gen12 = convolve(pX1, pX2); // dist from 30 -> 36
//let gen123 = convolve(gen12, pX3); // dist from 42 -> 54
//let gen1234 = convolve(gen123, pX4); // dist from 51 -> 72
//let gen12345 = convolve(gen1234, pX5); // dist from 54 -> 90
//let gen123456 = convolve(gen12345, pX6); // dist from 57 -> 108
//console.log(gen123456, gen123456.length)

// automating class convolution
CONVOLVED_DISTS = {};
var gen_convolved_trace_for_class_dist = function(dists, klss) {
  var pX1 = TRUNCATED_DISTS[dists[0]];
  var pX2 = TRUNCATED_DISTS[dists[1]];
  var pX3 = TRUNCATED_DISTS[dists[2]];
  var pX4 = TRUNCATED_DISTS[dists[3]];
  var pX5 = TRUNCATED_DISTS[dists[4]];
  var pX6 = TRUNCATED_DISTS[dists[5]];
  var start = dists.reduce((acc, e) => acc+e, 0); // start at sum of floors

  let gen12 = convolve(pX1, pX2);
  let gen123 = convolve(gen12, pX3);
  let gen1234 = convolve(gen123, pX4);
  let gen12345 = convolve(gen1234, pX5);
  let gen123456 = convolve(gen12345, pX6);
  CONVOLVED_DISTS[klss] = gen123456;

  return {
    x: gen123456.slice().map((x,i)=> i + start),
    y: gen123456,
    name: klss,
    text: gen123456.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls"),
    opacity: 0.8,
    type: "scatter",
  };
}
var trace_paladin = gen_convolved_trace_for_class_dist([17,13,12,9,3,3], 'paladin');
var trace_ranger = gen_convolved_trace_for_class_dist([14,14,13,13,3,3], 'ranger');
var trace_fighter = gen_convolved_trace_for_class_dist([9,3,3,3,3,3], 'fighter');
trace_fighter.visible = 'legendonly'; // default off since we've kind of covered it
var data = [trace_paladin, trace_ranger, trace_fighter];
var layout = {
  title: "Convolved Ability Distributions for Classes",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist3convolved'), data, layout, plotlycfg);
</script>

> Notice the heavily tilted ranger/paladin distributions whose lean is distinctively more to the right.

The last thing that's left now is to rectify $Z_c$ at `75` to get our **true, final distributions**:

<div id="probhist3convolvedtrunc" style="width:600px;height:450px;"></div>
<script>
var truncated_klass = function (klss) {
  let CONVOLVED = CONVOLVED_DISTS[klss];
  // calculate probability up to cutoff point:
  let TRUNC_SUM = CONVOLVED.slice(-(108-75+1)).reduce((acc, e) => acc+e, 0);
  // truncate and scale (rectify) the right side of the distribution:
  let TRUNC_CONV = CONVOLVED.slice(-(108-75+1)).map(x => x / TRUNC_SUM);
  // sanity sum (all 1)
  console.log("Sum of convolved truncated", klss, TRUNC_CONV.reduce((acc, e)=>acc+e, 0));
  //let expectation = TRUNC_CONV.map((x,i) => (i+t)*x).reduce((acc, e) => acc+e, 0);
  //let variance = TRUNC_CONV.map((x,i) => Math.pow(i+t - expectation, 2)*x).reduce((acc, e) => acc+e, 0);
  //console.log("Expectation, variance for conv truncated", klss, expectation, variance);
  return {
    x: TRUNC_CONV.map((x,i) => i +75),
    y: TRUNC_CONV,
    name: 'true ' + klss,
    text: TRUNC_CONV.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls"),
    opacity: 0.8,
    type: "scatter",
  };
};
let trace_trunconv_paladin = truncated_klass('paladin');
let trace_trunconv_fighter = truncated_klass('fighter');
let trace_trunconv_ranger = truncated_klass('ranger');
trace_trunconv_fighter.visible = 'legendonly';
var data = [trace_trunconv_paladin, trace_trunconv_fighter, trace_trunconv_ranger];
var layout = {
  title: "True Roll Distributions for Classes",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist3convolvedtrunc'), data, layout, plotlycfg);
</script>

These match the sampled data almost perfectly as can be seen in more detailed comparisons in the <a href="#appendix">appendix</a>.

As can be seen; `ranger` is faster at getting high numbers, particularly in the 90 -> 97 range, but if you want rolls >= 100, **`paladin` rolls the highest** at the fastest rate.

We end with the expected time to roll above a certain threshold where we use the most efficient class based on the number:

- `108` paladin rolls once in `100 billion` ⇒ 210y
- `107` paladin rolls once in `5 billion` ⇒ 10y
- `106` paladin rolls once in `600 million` ⇒ 1y
- `105` paladin rolls once in `100 million` ⇒ 11w
- `104` paladin rolls once in `19 million` ⇒ 2w
- `103` paladin rolls once in `5 million` ⇒ 4d
- `102` paladin rolls once in `1.4 million` ⇒ 1d
- `101` paladin rolls once in `400k` ⇒ 7h
- `100` paladin/ranger rolls once in `150k` ⇒ 3h
- `99` ranger rolls once in `57k` ⇒ 1h
- `98` ranger rolls once in `23k` ⇒ 25m
- `97` ranger rolls once in `10k` ⇒ 11m
- `96` ranger rolls once in `5k` ⇒ 5m
- `95` ranger rolls once in `2k` ⇒ 2m

Hope you have enjoyed this random brain dump on probability. Don't think I have ever been nerd sniped this hard before.. I just wanted to play a game and take a break.

<small>/me closes 20 tabs</small>

## Appendix
<details><summary style="cursor:pointer"><b>1. Raw simulation data</b></summary>
<p>

10 hour paladin roll (`555558` rolls in `601m`)

```yaml
75: 50888
76: 54911
77: 57338
78: 57442
79: 55589
80: 52357
81: 47503
82: 41339
83: 34458
84: 28599
85: 21997
86: 16722
87: 12322
88: 8697
89: 5997
90: 3774
91: 2371
92: 1489
93: 822
94: 465
95: 251
96: 129
97: 56
98: 24
99: 12
100: 4
101: 1
102: 1
```

10 hour fighter roll (`555560` rolls in `608m`)

```yaml
75: 137379
76: 109198
77: 85620
78: 65004
79: 48256
80: 35041
81: 24987
82: 17545
83: 11981
84: 7883
85: 5007
86: 3139
87: 1946
88: 1138
89: 670
90: 368
91: 199
92: 103
93: 49
94: 26
95: 12
96: 6
97: 2
98: 1
```

9 hour ranger roll (`500054` rolls in `548m`)

```yaml
75: 32296
76: 37790
77: 43118
78: 46609
79: 48108
80: 47589
81: 45774
82: 41963
83: 36876
84: 30973
85: 25272
86: 19904
87: 14730
88: 10430
89: 7285
90: 4667
91: 2991
92: 1696
93: 986
94: 529
95: 254
96: 121
97: 56
98: 26
99: 10
100: 1
```

</p>
</details>

<details><summary style="cursor:pointer"><b>2. Tabulated values for 18 dice multinomial probability distribution</b></summary>
<p>

[Wolfram Alpha Query](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C18%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%2918%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2991-6k-1%5C%2844%29+17%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2991-18%5C%2841%29%2C6%5D%5C%2841%29%7D%5D)

```yaml
18  : 1/101559956668416
19  : 1/5642219814912
20  : 19/11284439629824
21  : 95/8463329722368
22  : 665/11284439629824
23  : 1463/5642219814912
24  : 33643/33853318889472
25  : 9605/2821109907456
26  : 119833/11284439629824
27  : 1552015/50779978334208
28  : 308465/3761479876608
29  : 97223/470184984576
30  : 2782169/5642219814912
31  : 1051229/940369969152
32  : 4550747/1880739938304
33  : 786505/156728328192
34  : 37624655/3761479876608
35  : 36131483/1880739938304
36  : 1206294965/33853318889472
37  : 20045551/313456656384
38  : 139474379/1253826625536
39  : 1059736685/5642219814912
40  : 128825225/417942208512
41  : 17143871/34828517376
42  : 8640663457/11284439629824
43  : 728073331/626913312768
44  : 2155134523/1253826625536
45  : 3942228889/1586874322944
46  : 4949217565/1410554953728
47  : 3417441745/705277476864
48  : 27703245169/4231664861184
49  : 3052981465/352638738432
50  : 126513483013/11284439629824
51  : 240741263447/16926659444736
52  : 199524184055/11284439629824
53  : 60788736553/2821109907456
54  : 2615090074301/101559956668416
55  : 56759069113/1880739938304
56  : 130521904423/3761479876608
57  : 110438453753/2821109907456
58  : 163027882055/3761479876608
59  : 88576807769/1880739938304
60  : 566880747559/11284439629824
61  : 24732579319/470184984576
62  : 101698030955/1880739938304
63  : 461867856157/8463329722368
64  : 101698030955/1880739938304
65  : 24732579319/470184984576
66  : 566880747559/11284439629824
67  : 88576807769/1880739938304
68  : 163027882055/3761479876608
69  : 110438453753/2821109907456
70  : 130521904423/3761479876608
71  : 56759069113/1880739938304
72  : 2615090074301/101559956668416
73  : 60788736553/2821109907456
74  : 199524184055/11284439629824
75  : 240741263447/16926659444736
76  : 126513483013/11284439629824
77  : 3052981465/352638738432
78  : 27703245169/4231664861184
79  : 3417441745/705277476864
80  : 4949217565/1410554953728
81  : 3942228889/1586874322944
82  : 2155134523/1253826625536
83  : 728073331/626913312768
84  : 8640663457/11284439629824
85  : 17143871/34828517376
86  : 128825225/417942208512
87  : 1059736685/5642219814912
88  : 139474379/1253826625536
89  : 20045551/313456656384
90  : 1206294965/33853318889472
91  : 36131483/1880739938304
92  : 37624655/3761479876608
93  : 786505/156728328192
94  : 4550747/1880739938304
95  : 1051229/940369969152
96  : 2782169/5642219814912
97  : 97223/470184984576
98  : 308465/3761479876608
99  : 1552015/50779978334208
100 : 119833/11284439629824
101 : 9605/2821109907456
102 : 33643/33853318889472
103 : 1463/5642219814912
104 : 665/11284439629824
105 : 95/8463329722368
106 : 19/11284439629824
107 : 1/5642219814912
108 : 1/101559956668416
```
</p>
</details>

<details><summary style="cursor:pointer"><b>3. Tabulated values for 3 dice multinomial probability distribution</b></summary>
<p>

[Wolfram Alpha Query](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C3%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%293%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2910-6k-1%5C%2844%29+2%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2910-3%5C%2841%29%2C6%5D%5C%2841%29%7D%5D)

```yaml
3: 1/216
4: 1/72
5: 1/36
6: 5/108
7: 5/72
8: 7/72
9: 25/216
10: 1/8
11: 1/8
12: 25/216
13: 7/72
14: 5/72
15: 5/108
16: 1/36
17: 1/72
18: 1/216
```

</p>
</details>

<details><summary style="cursor:pointer"><b>4. Comparing observed vs. computed by class</b></summary>
<p>
We compare with the precise $Z_{class}$ distributions worked out by convolution above.

<div id="probhistappdxpala" style="width:600px;height:450px;"></div>
<script>
var data = [trace_trunconv_paladin, trace_obs_paladin];
var layout = {
  title: "Theoretical vs Observed Distributions for Paladin",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhistappdxpala'), data, layout, plotlycfg);
</script>

<div id="probhistappdxrang" style="width:600px;height:450px;"></div>
<script>
var data = [trace_trunconv_ranger, trace_obs_ranger];
var layout = {
  title: "Theoretical vs Observed Distributions for Ranger",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhistappdxrang'), data, layout, plotlycfg);
</script>

For fighter we have included the original uncorrected multinomial distribution for 18 dice before doing simulations. It was sufficiently close to the true distribution because flooring a single ability to `9` amounts to almost nothing in the right tail:

<div id="probhistappdxfig" style="width:600px;height:450px;"></div>
<script>
var data = [trace_trunconv_fighter, trace_obs_fighter, trace_single_trunc];
var layout = {
  title: "Theoretical vs Observed Distributions for Fighter",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhistappdxfig'), data, layout, plotlycfg);
</script>

That said, the true distribution taking into account the single floored stat has a much better fit.

</p>
</details>


<details><summary style="cursor:pointer"><b>5. Normal approximations</b></summary>
<p>

An original idea here was to avoid doing all the faff with convolution above, and "just" approximate the distribution with some normal $\mathcal{N}(μ, σ)$.

After all, [this is suggested for high n](https://mathworld.wolfram.com/Dice.html), and it will hold even for an unequal [sum of independent random variables with sufficient degrees of freedom](https://en.wikipedia.org/wiki/Central_limit_theorem).

However, there are many **complications** with this approach:

- we only **sample** the **doubly censored data**, we don't see the full normal distribution
- **distributions** are heavily **shifted** (as can be seen with the true paladin distribution)
- estimation of underlying normal distribution relies difficult for classes whose means precedes the truncation point

It does looks like there are tools to work with truncated or rectified normals:

- extension methods for [rectified normal distributions](https://en.wikipedia.org/wiki/Rectified_Gaussian_distribution#Extension_to_general_bounds)
- [formulas for dealing with truncation of a normal distributions](https://en.wikipedia.org/wiki/Truncated_normal_distribution#One_sided_truncation_(of_lower_tail))
- [cnorm r library](https://rdrr.io/cran/crch/man/cnorm.html) which comes with a [giant pdf](https://cran.r-project.org/web/packages/cNORM/cNORM.pdf) as documentation to help remind you of why we need rustdoc

But this felt like the wrong path to descend, and the path was littered with arcana:

<blockquote class="twitter-tweet" data-dnt="true" data-theme="light"><p lang="en" dir="ltr">ah, yes, just a vector. <a href="https://t.co/RvkpS4h0DX">pic.twitter.com/RvkpS4h0DX</a></p>&mdash; eirik ᐸ&#39;⧖ᐳ (@sszynrae) <a href="https://twitter.com/sszynrae/status/1512161877698174983?ref_src=twsrc%5Etfw">April 7, 2022</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

That said. If anyone wants to fill in something here, or link to alternate methods, feel free to PR in something [here](https://github.com/clux/probes/blob/main/content/post/2022-04-12-baldurs-roll.md) or write an [issue](https://github.com/clux/probes/issues).

</p>
</details>
