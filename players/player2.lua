#!/usr/bin/env lua

--[[
 @filename  player2.lua
 @version   1.0
 @autor     Máster Vitronic <mastervitronic@gmail.com>
 @date      21-02-2021 12:11:21 -04
 @licence   MIT licence

 @require   https://github.com/tacigar/lua-mqtt.git
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

This program is equal to
 $ mosquitto_sub -h ispcore.com.ve  -t song/stream | aplay -t raw

]]--

--@see https://github.com/tacigar/lua-mqtt.git
local mqtt	= require('mqtt')
--@see https://github.com/tdtrask/lua-subprocess
local subprocess= require("subprocess")

--local broker 	= 'broker.hivemq.com'
local broker 	= 'ispcore.com.ve'
local topic  	= 'song/stream'
local port  	= 1883
local keepalive = 60
local QoS	= 2

---The connection MQTT
client = mqtt.AsyncClient({
	serverURI = broker,
	clientID  = 'MQTTAudioPlayer'
})

---Other option is play -t raw -r 8k -e unsigned -b 8 -c 1 -
---The aplay subprocess
local aplay, err, errno = subprocess.popen({
	'aplay','-q','-t','raw',
	'--buffer-size=250',
	stdin  = subprocess.PIPE,
	stdout = subprocess.PIPE,
	stderr = subprocess.STDOUT
})

--@see https://stackoverflow.com/questions/41783274/how-to-clear-stdout-line-in-lua
local stdout, out = '', nil
function iop(str)
	io.output():setvbuf("no")
	io.output():setvbuf("line")
	io.write(('\b \b'):rep(#stdout))  -- erase old line
	io.write(str)                     -- write new line
	io.flush()
	stdout = str
end

function onMessageArrived(topicName, message)
	if ( topicName == 'song/info' ) then
		io.write(('\b \b'):rep(#stdout))
		io.write(message.payload .. "\n")
		io.flush()
	elseif ( topicName == topic ) then
		if (stdout == '/') then out = '\\' else out = '/' end
		iop(out)
		aplay.stdin:write(message.payload)
	end
	collectgarbage("collect")
end

client:setCallbacks(nil, onMessageArrived, nil)
client:connect({
	keepAliveInterval = keepalive,
	cleanSession	  = false,
	mqttVersion	  = 3,
	connectTimeout	  = 3
})
client:subscribe(topic, QoS)
client:subscribe('song/info', QoS)

aplay:wait()
aplay.stdout:close()


