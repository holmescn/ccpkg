local sh = {}

function sh.tar(args)
  local exec = os.search_path("tar")
  assert(exec, "`tar` is not found")
  return os.run {exe=exe, args=args, null=1}
end

return sh
