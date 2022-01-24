local scripts_dir = os.path.join(os.getenv("CCPKG_ROOT"), "scripts")

local function load_ext(name)
  dofile(os.path.join(scripts_dir, "ext", name .. ".lua"))
end

load_ext("string")
load_ext("table")
