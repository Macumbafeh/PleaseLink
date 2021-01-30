# PleaseLink

###### Scary warning: Most of these addons were made long ago during Feenix days, then a lot was changed/added to prepare for Corecraft. Since it died, they still haven't been extensively tested on modern servers.

### [Downloads](https://github.com/Shanghi/PleaseLink/releases)

***

## Purpose:
When someone says something like "link agi on boots" or "what are the mats for mongoose" it will attempt to find and link what they asked for. Links can be player spells, talents, or many craft/enchanting things. Each chat type (numbered channels/group/guild/etc) has its own settings to tell how to respond or not.

| Commands | Description |
| --- | --- |
| /pleaselink                        | _show these commands and current settings_ |
| /pleaselink&nbsp;maxmessages&nbsp;\<amount>  | _limit the amount of messages of links to reply with_ |
| /pleaselink suggest \<"on"\|"off"> | _if whispered to link an enchantment but nothing was found, reply with a list of possibilities (except for weapons)_ |
| /pleaselink content \<tier>        | _only link gems and enchantments at or below this content tier -<br>\<tier> can be: T4, T5, T6, ZA, SW_ |
| /pleaselink channel \<setting>     | _set how to respond to numbered channel messages_ |
| /pleaselink group \<setting>       | _set how to respond to group messages_ |
| /pleaselink guild \<setting>       | _set how to respond to guild messages_ |
| /pleaselink say \<setting>         | _set how to respond to say messages_ |
| /pleaselink whisper \<setting>     | _set how to respond to whispers_ |
| /pleaselink yell \<setting>        | _set how to respond to yell messages_ |
| /pleaselink all \<setting>         | _set all the channel/chat options at ance_ |

\<setting> can be:<br/>**off**: don't watch for link requests here<br/>**short**: say link(s) on same channel if it's 1 message long, or else whisper them<br/>**long**: say link(s) on same channel no matter how many messages it is<br/>**whisper**: whisper the link to whoever asked<br/>**show**: print the link to yourself only

## Screenshot:
![!](https://i.imgur.com/0Sm9u9O.png)

## Notes:
* It works best when the request's details come before what it's for, like "stats on chest" instead of "chest stats." It will try to understand either way though.

* Maybe the content level is wrong on some things!

* There were a lot of special cases to handle (like how Surefooted is both a talent and enchant, and someone asking about a stamina gem surely doesn't want to see millions of half stamina/half other stat gems), so there may be other things like that I haven't noticed yet.

* There are 2 types of searches: keyword-based (agi on gloves) and name-based (seal of blood). Keyword-based searches can be combined in a message ("link agi on back/hands and stats for chest please"), but name-based searches can't be. It would be possible to fix, but probably too complicated to be worth it with all the extra special cases when combining the 2 types!
