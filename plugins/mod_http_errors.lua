-- * Metronome IM *
--
-- This file is part of the Metronome XMPP server and is released under the
-- ISC License, please see the LICENSE file in this source package for more
-- information about copyright and licensing.
--
-- As per the sublicensing clause, this file is also MIT/X11 Licensed.
-- ** Copyright (c) 2012-2013, Kim Alvefur, Matthew Wild

module:set_global();

local server = require "net.http.server";
local codes = require "net.http.codes";
local termcolours = require "util.termcolours";

local show_private = module:get_option_boolean("http_errors_detailed", false);
local always_serve = module:get_option_boolean("http_errors_always_show", true);
local default_message = { module:get_option_string("http_errors_default_message", "That's all I know.") };
local default_messages = {
	[400] = { "What kind of request do you call that??" };
	[403] = { "You're not allowed to do that." };
	[404] = { "Whatever you were looking for is not here. %";
		"Where did you put it?", "It's behind you.", "Keep looking." };
	[500] = { "% Check your error log for more info.";
		"Gremlins.", "It broke.", "Don't look at me." };
};

local messages = setmetatable(module:get_option("http_errors_messages", {}), { __index = default_messages });

local html = [[
<!DOCTYPE html>
<html>
<head>
	<link rel="icon" type="image/png" href="/assets/favicon.png" />
	<meta charset="utf-8">
	<style>
		body{
			margin-top:14%;
			text-align:center;
			background-color:#F8F8F8;
			font-family:sans-serif;
		}
		h1{
			font-size:xx-large;
		}
		p{
			font-size:x-large;
		}
		p+p { font-size: large; font-family: courier }
        </style>
</head>
<body>
	<h1>$title</h1>
	<p>$message</p>
	<p>$extra</p>
</body>
</html>]];
html = html:gsub("%s%s+", "");

local entities = {
	["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;",
	["'"] = "&apos;", ["\""] = "&quot;", ["\n"] = "<br/>",
};

local function tohtml(plain)
	return (plain:gsub("[<>&'\"\n]", entities));
	
end

local function get_page(code, extra)
	local message = messages[code];
	if always_serve or message then
		message = message or default_message;
		return (html:gsub("$(%a+)", {
			title = rawget(codes, code) or ("Code "..tostring(code));
			message = message[1]:gsub("%%", function ()
				return message[math.random(2, math.max(#message,2))];
			end);
			extra = tohtml(extra or "");
		}));
	end
end

module:hook_object_event(server, "http-error", function (event)
	local response = event.response;
	if response then response.headers["Content-Type"] = "text/html"; end
	return get_page(event.code, (show_private and event.private_message) or event.message);
end);
