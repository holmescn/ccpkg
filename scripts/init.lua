-- reset package.path
package.path = './?/init.lua;./?.lua'
package.path = path.join {CCPKG_ROOT_DIR, 'scripts', "?.lua"} .. ";" .. package.path
package.path = path.join {CCPKG_ROOT_DIR, 'scripts', '?', "init.lua"} .. ";" .. package.path
package.path = path.join {CCPKG_ROOT_DIR, 'ports', "?.lua;"} .. ";" .. package.path
package.path = path.join {CCPKG_ROOT_DIR, 'ports', '?', "init.lua;"} .. ";" .. package.path
package.cpath = ''

require "ext"
require "ext.ccpkg"
require "cli"
