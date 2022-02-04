local root_dir=os.getenv("CCPKG_ROOT")

-- reset package.path
package.path = '?/init.lua;?.lua'
package.path = os.path.join(root_dir, 'scripts', "?.lua") .. ";" .. package.path
package.path = os.path.join(root_dir, 'scripts', '?', "init.lua") .. ";" .. package.path
package.path = os.path.join(root_dir, "?.lua") .. ";" .. package.path
package.cpath = ''

dofile( os.path.join(root_dir, "scripts", "ext", "init.lua") )
--dofile( os.path.join(root_dir, "scripts", "cli", "init.lua") )
--print(os.search_path("bash"))
