#!/usr/bin/env lua

--[[
 @filename  player.lua
 @version   1.0
 @autor     Máster Vitronic <mastervitronic@gmail.com>
 @date      20-02-2021 21:11:21 -04
 @licence   MIT licence

 @inspired  https://github.com/leotok/multi-speakers-audio-streaming
 @require   http://luaforge.net/projects/luasocket/
 @require   https://github.com/tdtrask/lua-subprocess

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

--@see http://luaforge.net/projects/luasocket/
local socket	= require('socket')
--@see https://github.com/tdtrask/lua-subprocess
local subprocess= require("subprocess")

--Define the broker MQTT
local broker 	= 'broker.hivemq.com'
--local broker 	= 'ispcore.com.ve'

-- This is equal to
-- $ mosquitto_sub -h ispcore.com.ve  -t song/stream | aplay -t raw

---The mosquitto_sub subprocess
local msq_args  = {'mosquitto_sub','-h',broker, '-t', 'song/stream'}
msq_args.stdin  = '/dev/null'
msq_args.stdout = subprocess.PIPE
msq_args.stderr = subprocess.STDOUT
local msq_sub, errmsg, errno = subprocess.popen(msq_args)

---The aplay subprocess
local play_args  = {
	'aplay','-q','-t','raw',
	--'--vumeter=mono',
	--'--channels=1',
	--'--buffer-size=1000',
	--'--buffer-time=200','--period-time=200'
}
play_args.stdin  = msq_sub.stdout
play_args.stdout = subprocess.PIPE
play_args.stderr = subprocess.STDOUT
local aplay, aplay_err, aplay_errno = subprocess.popen(play_args)

--Show progress to STDOUT
--local last_str = ''
--while (nil == aplay:poll()) do
	--local str = aplay.stdout:read(64)
	--io.write(('\b \b'):rep(#last_str))  -- erase old line
	--io.write(str)
	--io.flush()
	--last_str = str
	--socket.sleep(0.06)
	--collectgarbage()
--end

msq_sub:wait()
aplay:wait()
msq_sub.stdout:close()
aplay.stdout:close()
