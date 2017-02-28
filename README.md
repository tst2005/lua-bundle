# lua bundle util


* rewrote the lua-aio feature with the CIFE approach (Class/Instance/Filter/Env)
* use template
* new features
* advanced rockspec support (multiple list of modules)

# New features

* allow to make shadow embedding (in usual env only one package is visible, internally there are more than one module)
* allow module proxy (expose a proxy object)
* allow to embedde fallback implementation


## step of processing ...

* 1. create a new bundle instance
* 2. put every file/module that you need (for now only information are collected, no real file content)
* 3. drop duplicated file or make some re-ordering stuff
* 4. ask to do the pack job : that will add header, footer to the 
