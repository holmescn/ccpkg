local root_dir=os.getenv("CCPKG_ROOT")

-- reset package.path
package.path = '?/init.lua;?.lua'
package.path = os.path.join(root_dir, 'scripts', "?.lua") .. ";" .. package.path
package.path = os.path.join(root_dir, 'scripts', '?', "init.lua") .. ";" .. package.path
package.path = os.path.join(root_dir, 'ports', "?.lua") .. ";" .. package.path
package.path = os.path.join(root_dir, 'ports', '?', "init.lua") .. ";" .. package.path
package.cpath = ''

dofile( os.path.join (root_dir, "scripts", "ccpkg", "init.lua") )