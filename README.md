# Disney-Infinity-3.0-Any-Character-in-Any-Playset
A mod for Disney Infinity 3.0 that allows any character in any playset.

Well, as i said.. didn't wanna wait for someone to do this or nothing so i did it myself.
You guys won't believe how "simple" this all was. Simple, but hardcore.


## What does this mod do?

Disney Infinity 3.0 normally restricts characters depending on the Play Set, franchise, internal character lists, Play Set permissions, and several other systems spread across the game. This mod removes those restrictions and allows the full playable roster to be used across the four Disney Infinity 3.0 Play Sets included in Gold Edition: **Twilight of the Republic, Rise Against the Empire, Inside Out, and The Force Awakens**.

This is not a model swap. The goal from the beginning was to use the **actual character**, with their real model, animations, moveset, abilities, projectiles, traversal, voice, HUD, health, combat behavior, progression data, toolsets, and special mechanics. Spider-Man can walk into Star Wars. Lightning McQueen can drive around a Play Set he was never officially allowed into. Venom can appear immediately after an emotional Inside Out cutscene and simply stand there like that was always supposed to happen.

The strangest part is how naturally the game handles most of it.

---

## How this started

This entire project started because I wanted **Venom in Twilight of the Republic**. That's it, that was the whole plan. I wanted him playable for my birthday 30th August.

At first, I thought this would probably be a permissions edit or a few Lua changes. Instead, that one idea slowly turned into reverse engineering how Disney Infinity constructs a playable character, how the Play Sets decide what they are allowed to load, and how the executable itself validates which characters belong where.

The first real outside push came from **@Froggy** on Discord. His first hint was about munitions: *"The Clone Wars Munitions you can replace with Toybox Munitions."* That sent us into `core.zip`, where we copied the Toy Box munitions data and used it in place of `munitions_theclonewars.lua`. That became part of my working Twilight baseline, and later, when the project expanded to the other Play Sets, i realized the same replacement also needed to be carried over to Empire, Inside Out, and PlaysetX.

His next major hint was the one that really changed the project: take Venom's entries from `toybox_actors.lua` and `toyboxdatamap.lua`, and add them into `theclonewars_actors.lua` and `theclonewarsdatamap.lua`, correctly formatted. Those files live inside `gamedb\core.zip`, and that was the point where we stopped thinking in terms of "unlocking Venom" and started understanding that the character actually had to be transplanted into the destination Play Set's runtime data.

---

## Toy Box became the reference

Once that clicked, Toy Box became our canonical reference for character data. For every character, we started tracing the actor registration, DataMap entry, helper actors, Includes, munitions, SurfaceImpacts, avatar BTX files, progression scripts, toolsets, emuinfo files, bitmask memberships, asset definitions, traversal systems, and anything else the character expected to exist.

The method became pretty simple in concept: 

"look at what the character has in Toy Box, compare that against the destination Play Set, and bring over what is missing. If one dependency referenced another dependency, follow that too. If an Actor referenced another Actor, bring it. If an Include referenced another Include, follow it. If a character had a special projectile, tool, traversal system, or runtime contract, make sure the destination actually knew about it."

That is when this stopped being a collection of little shots in the dark. We were starting to understand the character system itself.

---

## The files that mattered

A big part of this project was realizing that there was no single "unlock characters" file. The restrictions and runtime requirements were spread across several layers... This SUUCKED to uncover!!!!

`gateway.lua` controls Play Set permissions. A character could have all of their runtime data transplanted correctly and still not be allowed into a destination if the gateway did not list that Play Set for them.

The `*_actors.lua` files register the actors available to each Play Set, while the matching `*datamap.lua` files contain the much larger dependency graph behind them. That is where we were dealing with character entities, helper actors, munitions, SurfaceImpacts, Includes, behavior data, progression, toolsets, avatar files, and other runtime dependencies.

`bitmasks.lua` (inside toybox.zip, theclonewars.zip and the other playsets zips on assets\gamedb) turned out to matter just as much. Characters belong to many internal groups that control things like player recognition, combat classes, movement, wall crawling, web swinging, super jumping, Jedi behavior, scripted checks, and other systems. A character could load and still behave incorrectly because the destination Play Set was missing a membership they had in Toy Box.

`assetdefs.lua` was another piece. Some character systems only worked correctly when the destination Play Set loaded the appropriate asset definitions. Venom's web swing was one of the clearest examples because the character data could be correct, but without the Play Set-level web swing asset definitions, parts of the ability still did not behave properly.

For `munitions_xxxx.lua`... Literally just replaced all of the playset munitions luas for `munitions_toybox.lua`. Yeah that's it lol but i'm not THAT sure if this is really that important. Again, i was just testing stuff out.

By the end, making a character work meant getting all of these layers to agree: `gateway.lua`, Actors, DataMap, bitmasks, asset definitions, munitions, character runtime dependencies, and eventually the executable itself.

---

## Venom was the test subject

Venom ended up teaching us almost everything.

Getting him to simply appear was easy compared to getting him to function properly. Over time, we restored his normal HUD, health, damage, death behavior, combat, web projectiles, web grab, tap and hold attacks, visible web swinging, wall crawling, super jump, mission participation, enemy recognition, and scripted interactions.
Twilight of the Republic also exposed the fact that some Play Set events were checking for specific runtime classifications rather than just "is this a playable character?" That led us into things like `AV_Jedi`, Jedi runtime emuinfo, and Play Set-specific bitmasks.
We also learned not to force the same solution onto every character. A biped superhero, a Cars character, a fish, and a web-swinging character do not all have the same architecture. The character's original runtime has to remain intact first, and Play Set-specific compatibility should only be added where it actually makes sense.

---

And then he came.. Donald Ducking Duck.
Donald Duck was one of the moments where this stopped feeling like luck.
Donald had a completely different dependency chain from Venom. He had his own tools, helper actors, projectiles, avatar behavior, progression, toolset, runtime files, and class data. Once all of those dependencies were transplanted correctly, Donald worked too.
That was the point where the obvious question became: if this process works for characters with completely different architectures, why am i doing them one at a time?

So i build a script on ChatGPT which worked almost like a factory. We tested multiple characters at once (added Thor and Hulkbuster at the same time), then larger batches, and eventually transplanted the entire official roster in one go (and a particular long bathroom break). Nothing broke A SINGLE TIME in this process.

---

## From one character to the full roster

Once the full roster worked in Twilight of the Republic, the project changed again. Twilight was no longer the goal; it had become the proof of concept. At this point i was hungry to be 100% what i can be as help to the world.

The four Play Sets we were dealing with are:

```text
theclonewars = Twilight of the Republic
empire       = Rise Against the Empire
insideout    = Inside Out
playsetx     = The Force Awakens
```

Each destination has its own Actors, DataMap, bitmasks, asset definitions, mission assumptions, filters, and runtime expectations, so the final system treats each one as its own adapter rather than assuming that a single generic copy will work everywhere.

Once those adapters were built, the full official character roster could be transplanted across all four Play Sets.

---

## Then we hit the executable

At this point, the archives were no longer the whole problem. A character could be correctly present in the game data, appear in My Collection, have all of their runtime dependencies loaded, and still be rejected when you tried to actually enter a Play Set.
That was when the project moved into `DisneyInfinity3.exe`.
Using Ghidra, binary comparisons, old patch information, and repeated testing, we found several native Virtual Reader functions, including:

```text
VirtualReaderPC_ValidateCurrentCharacter
VirtualReaderPC_GetBrandFromCurrentPlaySet
VirtualReaderPC_GetBrandFromName
VirtualReaderPC_GetCurrentCharacter
VirtualReaderPC_GetFilterButtonData
```

One important call chain looked like this:

```text
VirtualReaderPC_ValidateCurrentCharacter
        ↓
FUN_00b8ea20
        ↓
LAB_00b80830
        ↓
FUN_00b7fda0
        ↓
FUN_00b497b0
```

`FUN_00b497b0` turned out to behave like a membership lookup. It walks a list and returns whether a particular value exists inside it. In the validation path, a failed result could eventually cause the current character to be invalidated. That finally gave us a concrete native-level explanation for part of the lock.

---

## The old Twilight patch

There was also one strange piece of history we had to recover.

Very early in this whole journey, Gemini had somehow given me a patch that allowed unsupported characters to get through Twilight of the Republic. At the time, I did not understand why it worked. It just worked.

Much later, once me and GPT were trying to generalize the same behavior to Empire, Inside Out, and The Force Awakens, reproducing it became surprisingly difficult. Fortunately, the original working patched EXE still existed. So we compared it byte-for-byte against a clean `DisneyInfinity3.exe`. That let us recover exactly what had changed.

One of the important modifications was around:

```text
00B7FDE1
```

where the normal conditional validation path had been altered so the game would follow the successful branch instead.

But the old patch also contained several Twilight-specific identity substitutions involving:

```
TheCloneWars
PlaysetZ

IGP_PLAYSET_TheCloneWars
IGP_PLAYSET_PlaysetZ

TCW_Geonosis_TERRAIN
PSZ_Barbados_TERRAIN
```

The interesting part was that `PlaysetZ` and `PSZ_Barbados_TERRAIN` were not invented values. They already existed inside the clean executable. That old patch had been abusing a dormant Play Set identity already compiled into the game. Recovering that patch was useful not because we wanted to keep using the same Twilight-specific trick forever, but because it showed us there was another layer of validation still happening.

---

## The second lock

The first executable patch was enough to help My Collection behave differently, but it did not solve everything.
Characters could become selectable and still be stopped by:

> **Select Appropriate Character**

That proved there were at least two separate gates: one around character selection and validation, and another around actual Play Set acceptance. 
That second investigation led us to:

```
VirtualReaderPC_GetBrandFromCurrentPlaySet
```

Once the Play Set brand validation was neutralized correctly, the remaining restriction disappeared.

The first really memorable proof was Inside Out. The cutscene played normally, everything looked completely ordinary, and then it ended with a dry cut to Venom standing there.

That was the moment we knew the executable lock was actually gone.

---

What still surprises me is how well these characters work once the artificial restrictions are removed.
They do not feel like model swaps. They don't feel like cheating, nor out of place, nor nothing. The game already understands an enormous amount of their combat, traversal, abilities, HUD behavior, animation systems, damage, missions, enemy interactions, projectiles, tools, and character-specific mechanics outside the places where they were officially permitted.
It feels like the characters were made to be played like that.. in those playsets. Any character fits, man. I still don't understand why Avalanche locked us out of that for over 10 years.
Disney Infinity is a game about toys. If Spider-Man walks into Star Wars, why should the game stop you? When I was younger, Batman could fly because I decided Batman could fly. A Max Steel figure missing both hands would just have freaking proto cannons that could blast mountains off. Nobody stopped playing because two toys came from different boxes. That was the fun. In a weird way, that is what this mod restores.

**The Play Set is the world. The character is whatever toy you decided walked into it.**

---

## Shoutouts

A huge thank you goes to **Froggy**, because his hints were genuinely important to getting this project moving in the right direction.

The funny part is that even getting in contact took a while. I found the **Disney Infinity 4.0 + Development Discord server**, which Froggy owns, and then had to wait several days just to get access. By that point I was already completely invested in figuring this out. When I finally got in, the server itself was pretty quiet, but Froggy was the person who mattered. He did not hand me a finished mega mod or walk me through every step. What he gave me were hints. First the Toy Box munitions replacement. Then the instruction to take Venom's entries from `toybox_actors.lua` and `toyboxdatamap.lua` and correctly add them into `theclonewars_actors.lua` and `theclonewarsdatamap.lua`.

Those hints were enough to point us toward the right architecture. From there, we kept digging, testing, comparing, breaking things, rebuilding things, and eventually turned those first ideas into the full system described above.
So genuinely, thank you, Froggy. The final implementation became its own project, but some of the most important early signposts came from you.
And credit to the **Disney Infinity 4.0 + Development Discord server** as the place where that connection happened and where part of the history of Disney Infinity development and modding still exists.

---

I started this thing because I wanted Venom in Twilight of the Republic. For my birthday.

That turned into editing Lua, replacing munitions, transplanting Actors and DataMaps, following recursive dependencies, comparing bitmasks, fixing asset definitions, modifying `gateway.lua`, decrypting and rebuilding Disney's archive format, reverse engineering the executable, recovering old binary patches, tracing Virtual Reader functions, bypassing character validation, and finally bypassing the Play Set brand restriction itself.

Somewhere during all of that, the original Venom experiment became a full character-transplantation framework capable of putting the official playable roster into every Disney Infinity 3.0 Play Set that didn't have it in Gold Edition.

.... Definitely did not expect that when I started, i'll tell you some.

---

## Why release this?

Because projects like this are incredibly easy to lose. Even during this project, we had moments where something important had already been solved, but the explanation was scattered across old conversations, forgotten experiments, screenshots, or a modified file whose exact history was no longer obvious. One of the most important pieces of the executable work had to be recovered later by comparing an old working EXE against a clean one because the exact patch had become part of the project's archaeology. I do not want the same thing to happen to this.. Being the person always arriving later, trying to understand a technical problem while most of the useful context has disappeared. Sucks, man. Specially to as someone as lonely as me. If somebody comes along years from now wanting to understand how this works, I want them to have something better than fragments of dead Discord conversations and ancient screenshots.
I wrote here all i could remember. If it isn't all, well.. the files are already avaiable for tinkering.

Well, anywho..
**Take it. Break it. Improve it. Figure out something I missed.** Just please document your discoveries.

If somebody eventually understands this well enough to take it further than I did, that would be a much better ending than having the work disappear with me.

---

## Final words

I genuinely thought this might be impossible when I started.
What do you know, huh. It wasn't really that difficult. It was simply buried under enough layers of encrypted archives, Lua data, Actors, DataMaps, munitions, bitmasks, asset definitions, runtime dependencies, gateway permissions, Play Set filters, whitelist checks, brand validation, and executable logic to make the answer very difficult to see from the outside. Once those layers were separated and understood, the whole thing became surprisingly logical. 
Simple, but hardcore.

So here it is: the mod, the process, the discoveries... and the result.

Have fun, you babies S2 xoxo and all that jazz!!


