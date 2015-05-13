# deadbolt

Transform your Yubikey into a literal key to your Mac.

## What is it?

[Yubikeys](https://www.yubico.com/products/yubikey-hardware/) are great little devices for 2FA and other crypto applications. With just a little tweaking—and `deadbolt`—you can turn your Yubikey into a physical key for your Mac.

The use case is simple: You want your Mac to operate *when* and *only when* your Yubikey is present.

The *when* can be achieved by installing Yubico’s PAM module (decent instructions for which can be found [here](http://blog.avisi.nl/2014/05/06/two-factor-authentication-on-osx-a-yubikey-example/)—I’ll probably write up my own soon enough.)

But the PAM module isn’t sufficient alone. The PAM module allows you to set things up so that you you need your Yubikey to unlock your computer. But once you are logged in, you can safely remove the Yubikey and continue to use your Mac.

`deadbolt` provides the *only when*—`deadbolt` monitors when your Yubikey (or any other USB device of your choosing, for that matter) is removed, and immediately locks your computer. So now, not only do you need your Yubikey to unlock your computer, it must remain in place to even use your computer. No Yubikey, no access.

## License

`deadbolt` Copyright © 2015 D.E. Goodman-Wilson.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

## FAQ

* Do I need a Yubikey for `deadbolt` to be of use?
No, in fact you don’t. `deadbolt` can monitor any USB device of your choosing, and lock your computer on removal. But `deadbolt` is most useful when you have some kind of cryptographic hardware that enables 2FA for unlocking the computer.

* Why isn’t there an app icon?
Because I am no artist. @pavelmacek has kindly offered to make one—wait for it!

* What license is the source code released under?
GPL v3.0.

* Seriously? Why would you do such a thing?
Because Richard Stallman was right.

## Downloads
You can download pre-built binaries here:
* [1.0.0](https://github.com/DEGoodmanWilson/deadbolt/blob/master/Releases/deadbolt-1.0.0.app.zip)

## Credits
### MASShortcut

Copyright © 2012–2013, Vadim Shpakovski
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 