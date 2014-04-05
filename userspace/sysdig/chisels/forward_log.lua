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

-- package.path="./?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/lib/lua/5.1/?.lua;/usr/local/lib/lua/5.1/?/init.lua;/usr/share/lua/5.1/?.lua;/usr/share/lua/5.1/?/init.lua";
package.path = "/usr/share/lua/5.1/?.lua;/usr/share/lua/5.1/?/init.lua;" .. package.path;
package.cpath = "/usr/lib/i386-linux-gnu/lua/5.1/?.so;" .. package.cpath;
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
    eventNumber =  chisel.request_field("evt.num");
    eventTime =  chisel.request_field("evt.time");
    procName = chisel.request_field("proc.name");

	-- increase the snaplen so we capture more of the conversation
	sysdig.set_snaplen(2000)

	-- set the filter
	chisel.set_filter("evt.is_io=true")
	return true
end

-- Event parsing callback
function on_event()
    buf = string.format("%s %s %s", evt.field(eventNumber), evt.field(eventTime), evt.field(procName));
    local http = require("socket.http");
    local request_body = string.format("event=%s", buf);
    -- print(buf)
    local response_body = { };
	if buf ~= nil then
        b, c, h = http.request {
            url = server_url;
            method = "POST";
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded";
                ["Content-Length"] = #request_body;
            };
            source = ltn12.source.string(request_body);
            sink = ltn12.sink.table(response_body);
        }
	end
	return true
end
