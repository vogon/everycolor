# everycolor

colors, all of 'em.

[follow @everycolorbot](https://twitter.com/everycolorbot) on twitter if you wanna keep up on all the latest happenings in the world of color.

## deployment guide

1) get ruby, rake, and bundler

2) run *bundle install* to get all those gems

3) set up a scheduled task to run *rake tweet*

## the magic bits

here is an exhaustive list of halfway-interesting problems I solved over the course of writing this thing:

- *randomly selecting colors without repeats*: bog-standard PRNGs aren't guaranteed (as far as I'm aware) to generate *n*-bit numbers with a period of 2<sup>n</sup>, which is a necessity for something that claims to generate "every color."  either I could store a list of colors generated since the inception of @everycolorbot and reroll if I get a repeat (which is hard; see below), or use a custom PRNG that *does* have a guaranteed period of 2<sup>n</sup>.<p>*solution*: everycolor uses a 24-bit LFSR to generate numbers, using a set of taps (documented in everycolor.rb) which are guaranteed to have a period of 2<sup>24</sup> (which you can experimentally verify using the *test_lfsr* method.)  I could've used a better PRNG, but it wasn't worth researching.

- *statelessness*: heroku doesn't come stock with any stores of persistent data; the ephemeral file system associated with your dyno is destroyed when the dyno stops running.  this makes it hard to store a history of every color that's been generated (see above).  for the OAuth credentials required for @everycolorbot, standard config vars suffice, but there doesn't seem to be a way of updating config vars from inside a dyno, and in any case the docs say that your dyno gets restarted whenever a config var changes (which seems like it would lead to an infinite loop of tweets, Twitter jail, dogs and cats living together, mass hysteria, &c.)<p>*solution*: everycolor uses Twitter itself as a store of persistent data, by reloading the last color it tweeted every time it goes to tweet.
