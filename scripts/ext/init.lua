local function load_ext(name)
  dofile(os.path.join(ccpkg.scripts_dir, "ext", name .. ".lua"))
end

load_ext("string")
load_ext("table")