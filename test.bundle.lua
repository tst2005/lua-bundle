local bundle = require "bundle"

local x = bundle():init()
:def {as="module",mode="raw2"}
+ { name="shebang",	file=false,	content="#!/usr/bin/env lua\n", as="textcode", }
+ { name="a",		file="sample/a.lua",	}
+ "fallback"
+ { name="b",		file="sample/b.lua",	}
+ { name="c",		file="sample/c.lua",	fallback=false, }
+ "internal"
+ { name="d",		file="sample/d.lua",	}
- { name="b",					}
+ { name="C",		file="sample/C.lua",	fallback=true}
+ "fallback"
+ { name="foo",		file=false,	content="return {_VERSION='foo 0.1.0'}", }

x:readfiles()

print( x )

--x = nil
