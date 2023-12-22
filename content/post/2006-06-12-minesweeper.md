+++
title = "Mineswept"
date = "2006-06-12"
slug = "2006-06-12-mineswept"

[taxonomies]
tags = []
categories = ["gaming"]

[extra]
+++

Historical scores with the now open source minesweeper replay player written in javascript.

<!-- more -->

In an effort to avoid the emotional pain from continued exam preparations in 2006, a lot of minesweeper games were played.

## Rankings
The games were played on [minesweeper profile](https://minesweepergame.com/profile.php?pid=3552) and show up in the [country rankings](https://minesweepergame.com/country-rankings.php) (Norway -> Time -> Eirik) as #3 at the time of writing.

Games were played on the flashier [Minesweeper Clone](http://www.minesweeper.info/downloads/MinesweeperClone.html) which allowed you to save the replays.

## Expert Replay

using file [f](/imgs/3552-Time-FL-30x16-53.490-119-2.224-20070611.mvf)

...TODO this needs an easier install thing...
currently requires
> Copy the packaged code of Flop Player to the project directory
plus bunch of stuff: https://github.com/hgraceb/flop-player

<iframe class="flop-player-iframe flop-player-display-none">
...TODO
</iframe>

<script>
    function playVideo(uri, options) {
        window.flop.playVideo(uri, options || {
            background: 'rgba(0, 0, 0, .5)',
            listener: function () {
                console.log('Flop player exit')
            }
        })
    }

    function active() {
        const elements = document.querySelectorAll(':disabled')
        for (let i = 0; i < elements.length; i++) {
            elements[i].disabled = false
        }
    }

    function playerOnload() {
        active()
        const uri = '/imgs/3552-Time-FL-30x16-53.490-119-2.224-20070611.mvf'
        playVideo(uri, {
            share: {
                uri: uri,
            },
            anonymous: true,
            background: 'rgba(0, 0, 0, .5)'
        })
    }

    (function () {
      if (window.flop) {
          console.log('Flop Player Loaded')
      } else {
        window.flop = {
          onload: function () {
            console.log('Flop Player Loaded');
            playerOnload();
        }
    }
    })()
</script>
