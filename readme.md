# PropCannonTool

### Description
The non-working poerted prop cannotn tool that that I fixed and ported to GM13. The original
author is most likely being [`Lexi`][ref-lexi], but he has stopped the
support for the prop cannon tool. I fixed it and improved it because I had so good memories with it!

### How to install
Clone this repo in your addons folder or subscribe to it at the [workshop here][ref-ws].

### Bug reports
If there is something wrong with the addon don't fix it but rather please inform me via the issue system!

### How to use
Just weld it to a prop or spawn it on the map. When `Autofire toggle` is active the cannon will
shoot bullets continuously until it is stopped by the user. When `Single shot` is pressed, as
the name suggests, the cannon will shoot one single bullet whenever it is ready to fire.

### Wire support
This addon contains the prop cannon `gmod_propcannon` and the cannon bullet `cannon_prop`
scripted entities. They are both controlled and can utilize wire inputs/outputs. The wire
ports will check when they are connected. [If so][ref-iif], they will get validated. When
the wire port value is not in the desired bounds or it is invalid, the internal setup
values from the cannon will be used. For example the valid value for the billet mass
`fireMass` is positive, so negatives including `0` are considered invalid.
```lua
  local fireMass = self:GetCase(wfireMass ~= nil and wfireMass > 0, wfireMass, self.fireMass)
```

![PropCannonTool][ref-screen]

[ref-iif]: https://en.wikipedia.org/wiki/If_and_only_if
[ref-screen]: https://raw.githubusercontent.com/dvdvideo1234/PropCannonTool/master/data/propcannon/tools/pictures/screenshot.jpg
[ref-ws]: https://steamcommunity.com/sharedfiles/filedetails/?id=286474801
[ref-lexi]: https://github.com/Lexicality
