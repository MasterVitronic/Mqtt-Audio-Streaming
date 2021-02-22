#!/usr/bin/env lua

--[[
 @filename  player2.lua
 @version   1.0
 @autor     Máster Vitronic <mastervitronic@gmail.com>
 @date      21-02-2021 12:11:21 -04
 @licence   MIT licence

 @see	    https://nodemcu.readthedocs.io/en/release/modules/pcm/
 @require   https://github.com/tacigar/lua-mqtt.git
 @require   https://github.com/tdtrask/lua-subprocess
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

This program is equal to

 $ mosquitto_sub -h ispcore.com.ve  -t song/stream | aplay -t raw

Although I must clarify that with this program a significant
improvement in sound quality is obtained.

]]--

--@see https://github.com/tacigar/lua-mqtt.git
local mqtt	= require('mqtt')
--@see https://github.com/tdtrask/lua-subprocess
local subprocess= require("subprocess")
--utilities
local util 	= require("utils")

--local broker 	= 'broker.hivemq.com'
local broker 	= 'ispcore.com.ve'
local topic  	= 'song/stream'
local port  	= 1883
local keepalive = 60
local QoS	= 2

---The connection MQTT
client = mqtt.AsyncClient({
	serverURI = broker,
	clientID  = 'MQTTAudioPlayer2'
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

function onMessageArrived(topicName, message)
	if ( topicName == 'song/info' ) then
		io.write(('\b \b'):rep(#stdout))
		io.write(message.payload .. "\n")
		io.flush()
	elseif ( topicName == topic ) then
		if (stdout == '/') then out = '\\' else out = '/' end
		util:iop(out)
		aplay.stdin:write(message.payload)
	end
	collectgarbage("collect")
end

function onDeliveryComplete()
	io.write("onDeliveryComplete\n")
end

function onConnectionLost()
	io.write("onConnectionLost\n")
end

client:setCallbacks(
	onConnectionLost,
	onMessageArrived,
	onDeliveryComplete
)

client:connect({
	keepAliveInterval = 60,
	cleanSession	  = true,
	--mqttVersion	  = 3,
	connectTimeout	  = 5,
	retryInterval	  = 5
})

client:subscribe(topic, QoS)
client:subscribe('song/info', QoS)

aplay:wait()
aplay.stdout:close()


