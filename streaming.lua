#!/usr/bin/env lua

--[[
 @filename  streaming.lua
 @version   1.0
 @autor     Máster Vitronic <mastervitronic@gmail.com>
 @date      20-02-2021 21:11:21 -04
 @licence   MIT licence

 @inspired  https://github.com/leotok/multi-speakers-audio-streaming
 @see	    https://nodemcu.readthedocs.io/en/release/modules/pcm/
 @require   http://luaforge.net/projects/luasocket/
 @require   https://github.com/tacigar/lua-mqtt.git

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
--@see https://github.com/tacigar/lua-mqtt.git
local mqtt	= require('mqtt')
--the list of audio files
local songs	= dofile('audio_list.lua')

local broker 	= 'broker.hivemq.com'
--local broker 	= 'ispcore.com.ve'
local topic  	= 'song'
local port  	= 1883
local keepalive = 60
local QoS	= 0
local chunk_size= 1024
local quit 	= false


function onMessageArrived(_topic, message)
	print(_topic, message)
	if ( _topic == ('%s/cmd'):format(topic)  ) then
		if ( message.payload == '/quit' ) then
			io.write("Bye \n")
			quit = true
		end
	end
end

client = mqtt.AsyncClient {
	serverURI = broker,
	clientID  = 'MQTTAudioStream'
}
client:setCallbacks(nil, onMessageArrived, nil)

client:connect{
	keepAliveInterval = keepalive,
	cleanSession	  = false,
	mqttVersion	  = 3,
	connectTimeout	  = 3
}
client:subscribe(('%s/cmd'):format(topic), QoS)



function stream()
	while true do --infinite loop
		if quit then break end
		for _,value in pairs(songs) do -- loop for songs
			local file = io.open(value.path, "rb")
			client:publish(('%s/info'):format(topic),{
				payload = ('{name:"%s",desc:"%s"}'):format(
					value.name,value.desc
				),
				qos 	= QoS,
				retained= false
			})
			while true do -- loop for read bytes
				local bytes = file:read(chunk_size)
				if not bytes or quit then
					break
				end
				client:publish(
					('%s/stream'):format(topic),{
					payload = bytes,
					qos 	= QoS,
					retained= false
				})
				socket.sleep(0.12)
				collectgarbage()
			end
			if quit then break end
		end
	end
end

stream()
client:disconnect(100)
client:destroy()
