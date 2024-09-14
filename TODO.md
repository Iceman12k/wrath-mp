Reki (September 14 2024)
Oh hello, you've found the MP code...

I have not touched this codebase in over a year at this point, so I'm sure the list of incomplete things is itself... uh. incomplete.
What comes to mind immediately is as follows:

- RKUI system (uielement.h) is outdated, it should be updated and the HUD needs to be brought in parity with the final release of WRATH.
- Pickup messages are rendered in the wrong color, they're dark grey when they should be closer to white.
- Plenty of pickup message asset paths changed between when this was written and the point-release, so those need to be updated.
- Lag compensation needs to be more fleshed out, currently it is pure gamestate extrapolation which is insufficient for netplay above 40ms ping or so give the insane player movement speed.
- Player movement has a bug where corners-on-steps cause the player to dead stop, this is really obvious with the blade jump. Just needs a cleanup and better port of Q2 collision or similar.
- Weapon roster is incomplete (currently only has what was in "DM1" which I'm not sure ever got publicly released).
- Artifacts are totally unimplemented.
- Gamemode is currently hardcoded to 5 minute FFA, this was just done as a proof-of-concept to pitch the build.
- The whole think timer thing was maybe a bit misguided, I had been perusing the Q3 codebase and thought it was a neat solution to Wrath's crazy-ass think time dependent weapon code. It does the job but it's not quite as elegant as I might have hoped.
- Lots of stuff isn't precached.