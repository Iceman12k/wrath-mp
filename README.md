// Reki (September 14 2024)
Oh hello, you've found the MP code...

I did not originally intend to release this codebase, but as some time has passed since the release of WRATH I think it's appropriate to give this to the community.

This entire thing was done in my personal time and much of it in a crunch, so beware some questionable code in places, but I tried to keep it pretty sane and well organized. Regrettably it was not included in the official release, so that paused my work on it and it is supplied totally as-is.
Hopefully it can be used to create a robust Deathmatch mode, and maybe have some use for Coop if anyone is brave enough to take a stab at that. It is also just a decent general-purpose FTEQW/DarkPlaces MP codebase, tho it requires some FTE features be ported into DP as I did for Wrath's fork.
Someone should use this as a reason to bug DP maintainers for better FTE entrypoint adoption wink wink.

Anyway, a partial list of incomplete things are supplied in the TODO.md, though I'm sure there's a ton I've forgotten.

As far as "intent" behind the original MP mode as I saw it, I'll write some random verbal spew here:
I pictured the Wrath MP as a mostly team-based game, to set it apart from the standard AFPS duel fair (which I think doesn't lend itself to the fast movement and weapon roster anyway).
My intention was to have either 4v4 TDM with long weapon respawn times (a la QW), or some kind of Attack/Defend objective mode with team-allied monsters involved, which is something that hasn't really been done in an AFPS since some Q1/Q2 mods.
Artifacts would become a single-slot usable item, similar to the Wee-Balls [sic?] in DBT, and they would mostly match their SP behavior. I did have the idea of making Confound Attar desaturate your screen and turn off teammate indicators :) sounds kinda fun.

I hope this codebase proves useful to someone, and feel free to use it for your own standalone projects. If you do, attribution in the credits is always appreciated (and of course follow the GPLv2+ License).

Samuel "Reki" Piper
discord: reki5868