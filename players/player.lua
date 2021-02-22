#!/usr/bin/env lua

--[[
 @filename  player.lua
 @version   1.0
 @autor     Máster Vitronic <mastervitronic@gmail.com>
 @date      20-02-2021 21:11:21 -04
 @licence   MIT licence

 @see	    https://nodemcu.readthedocs.io/en/release/modules/pcm/
 @require   https://github.com/tdtrask/lua-subprocess
 @require   https://mosquitto.org/man/mosquitto_sub-1.html
 @require   https://en.wikipedia.org/wiki/Aplay

===============================================================================

Copyright (C) 2021 Díaz Devera Víctor Diex Gamar (Máster Vitronic)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

===============================================================================

To run the server
 $ lua streaming.lua

To play the audio on the client
 $ paho_c_sub -h ispcore.com.ve -t song/stream | aplay -t raw
or
 $ mosquitto_sub -h ispcore.com.ve -t song/stream | aplay -t raw
or
 $ mosquitto_sub -h ispcore.com.ve  -t song/stream | ffplay -f u8 -ar 8k -ac 1 -
or
 $ lua player.lua
]]--

--@see https://github.com/tdtrask/lua-subprocess
local subprocess= require("subprocess")

--Define the broker MQTT
--local broker 	= 'broker.hivemq.com'
local broker 	= 'ispcore.com.ve'

-- This is equal to
-- $ mosquitto_sub -h ispcore.com.ve  -t song/stream | aplay -t raw

---The mosquitto_sub subprocess
local msq_sub, errmsg, errno = subprocess.popen({
	'mosquitto_sub','-h',broker, '-t',
	'song/stream',
	stdin  = '/dev/null',
	stdout = subprocess.PIPE,
	stderr = subprocess.STDOUT
})

---The aplay subprocess
local aplay, aplay_err, aplay_errno = subprocess.popen({
	'aplay','-q','-t','raw',
	'--buffer-size=250',
	stdin  = msq_sub.stdout,
	stdout = subprocess.PIPE,
	stderr = subprocess.STDOUT
})

msq_sub:wait()
aplay:wait()
msq_sub.stdout:close()
aplay.stdout:close()
