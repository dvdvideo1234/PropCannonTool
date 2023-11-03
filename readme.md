# PropCannonTool

![PropCannonTool][ref-screen]

[![][ref-ws-down]][ref-ws] [![][ref-ws-date]][ref-ws-updt]

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
  local fireMass = PCannonLib.GetCase(wfireMass ~= nil and wfireMass > 0, wfireMass, self.fireMass)
```

### Custom bullet setup
You can use the following keys to implement custom configuration for your bullet. This
is often used by scripted bombs when the fire direction does not correspond to the local up direction.
```lua
  BULLET:Arm() -- The Arm() method is called when the class does not match the integrated bullet
  BULLET.CannonNoArm = true -- Forces the cannon not to call the Arm() method when firing
  BULLET.CannonAimAxis = Vector(1,0,0) -- Bullet forward local is used to calculate spawn angle
  BULLET.CannonArmArgs = {1, nil, 2} -- Passes maximum of nine arguments as is to the Arm() method
  BULLET.CannonEnAlign = true/false -- Enable or disable the bullet velocity alignment
  BULLET.CannonVeAlign = 10 -- Overrides the server owner enabled bullet align magnitude
```

[ref-iif]: https://en.wikipedia.org/wiki/If_and_only_if
[ref-screen]: https://raw.githubusercontent.com/dvdvideo1234/PropCannonTool/master/data/propcannon/tools/pictures/screenshot.jpg
[ref-lexi]: https://github.com/Lexicality
[ref-ws-down]: https://img.shields.io/steam/downloads/286474801
[ref-ws]: https://steamcommunity.com/sharedfiles/filedetails/?id=286474801
[ref-ws-date]: https://img.shields.io/steam/update-date/286474801
[ref-ws-updt]: https://steamcommunity.com/sharedfiles/filedetails/changelog/286474801
