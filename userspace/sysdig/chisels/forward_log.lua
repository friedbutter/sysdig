--[[
Copyright (C) 2013-2014 Draios inc.
 
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.


This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

-- Chisel description
description = "Send log to a server. Combine this script with a filter to limit the output to a specific process or pid.";
short_description = "Print stdout of processes";
category = "I/O";

args = {
    {
        name = "server_name", 
        description = "the name of the server that the log will be forward to", 
        argtype = "string"
    },
}

-- Argument notification callback
function on_set_arg(name, val)
    server_url = val
    return true
end

-- Initialization callback
function on_init()
	-- Request the fileds that we need
	fbuf = chisel.request_field("evt.rawarg.data")

	-- increase the snaplen so we capture more of the conversation 
	sysdig.set_snaplen(2000)
	
	-- set the filter
	chisel.set_filter("fd.num=1 and evt.is_io=true")
	
	return true
end

-- Event parsing callback
function on_event()
	buf = evt.field(fbuf)
	
	if buf ~= nil then
        local request_body = string.format("[[event=%s]]", buf);
		local http = require("socket.http");
        b, c, h = http.request { 
            url = server_url;
            method = "POST";
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded";
                ["Content-Length"] = #request_body;
            };
        }
        source = ltn12.source.string(request_body);
        sink = ltn12.sink.table(response_body);
	end
	return true
end
