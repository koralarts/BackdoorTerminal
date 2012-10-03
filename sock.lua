-----------------------------
-- Global Socket Variables --
-----------------------------
socket = require("socket")
tcpsock = assert(socket.tcp())

-- Connect Function
function connect(cip, cport)
	print("connecting... \nIP: " .. cip .. "\nPort: " .. cport .. "\n") 
	assert(tcpsock:connect(cip, cport))
	print("connected!\n");
end

-- Receive Response Function
function recvResponse()
	local data, stat, part = tcpsock:receive()
end

-- Send Command Function
function sendCommand(ccmd)
	print(ccmd)
	tcpsock:send(ccmd)
	recvResponse()
end

-- Close Connection Function
function close()
	assert(tcpsock:close())
end
