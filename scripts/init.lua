-- reset package.path
package.path = './?/init.lua;./?.lua'
package.path = path.join {ccpkg.root_dir, 'scripts', "?.lua"} .. ";" .. package.path
package.path = path.join {ccpkg.root_dir, 'scripts', '?', "init.lua"} .. ";" .. package.path
package.path = path.join {ccpkg.root_dir, 'ports', "?.lua;"} .. ";" .. package.path
package.path = path.join {ccpkg.root_dir, 'ports', '?', "init.lua;"} .. ";" .. package.path
package.cpath = ''

require "ext"
require "ext.ccpkg"
require "cli"
