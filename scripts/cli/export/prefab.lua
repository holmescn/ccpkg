---@diagnostic disable: undefined-field
local ccpkg = require "ccpkg"
local PrefabExporter = {
  data={
    machine_to_abi={
      arm='armeabi-v7a',
      arm64='arm64-v8a',
      x86='x86',
      x64='x86_64',
    }
  },
  mt={
    __index=function (t, key)
      if t.data[key] then return t.data[key] end
      if t.data.project and t.data.project[key] then
        return t.data.project[key]
      end
    end
  }
}
setmetatable(PrefabExporter, PrefabExporter.mt)

function PrefabExporter:init(parser)
  return self
end

function PrefabExporter:execute(project, spec)
  for k, v in pairs(spec) do
    self.data[k] = v
  end
  self.data.project = project
  self.data.platform = require('platform.android'):init(project)
  self.data.min_sdk = self.min_sdk or 21
  self.data.target_sdk = self.target_sdk or 31
  self.data.ndk_api = self.ndk_api or self.platform.ndk_api

  self:make_dirs()
  print("--- copy files")
  self:copy_files()
  print("--- module level include files")
  self:module_level_include_files()
  self:write_abi_files()
  self:write_pom()
  self:write_prefab_json()
  self:write_android_manifest()
  self:make_aar_file()
end

function PrefabExporter:load_package(name)
  for f in os.listdir(self.dirs.packages) do
    if f:startswith(name) then
      local package_file = os.path.join(self.dirs.packages, f)
      return dofile(package_file)
    end
  end
  print('--- ' .. name .. ' is not installed')
end

function PrefabExporter:have_static_libs(dir)
  for f in os.listdir(dir) do
    if f:match("%.a$") then
      return true
    end
  end
  return false
end

function PrefabExporter:make_dirs()
  self.dirs.prefab = os.path.join(self.dirs['.ccpkg'], 'prefab')
  if not os.path.exists(self.dirs.prefab) then
    os.mkdirs(self.dirs.prefab)
  end

  self.data.package_dir = os.path.join(self.dirs.prefab, self.name)
  if os.path.exists(self.package_dir) then
    os.rmdirs(self.package_dir)
  end

  self.data.aar_dir = os.path.join(self.package_dir, 'aar')
  os.mkdirs(self.aar_dir)

  self.data.prefab_dir = os.path.join(self.aar_dir, 'prefab')
  os.mkdirs(self.prefab_dir)
end

function PrefabExporter:copy_files()
  self.data.module_include_files = {}
  for mod in table.each(self.modules) do
    self.data.module_include_files[mod] = {}
    self:copy_module_files(mod)
  end
end

function PrefabExporter:copy_module_files(mod)
  local package_data = self:load_package(mod)
  assert(package_data, mod .. ' is not installed')

  local module_dir = os.path.join(self.prefab_dir, 'modules', mod)
  for machine, abi_id in pairs(self.machine_to_abi) do
    local abi_dir = os.path.join(module_dir, 'libs', 'android.' .. abi_id)
    if not os.path.exists(abi_dir) then
      os.mkdirs(abi_dir)
    end
    self:copy_module_abi_files(mod, package_data.files, machine, abi_dir)
  end
end

function PrefabExporter:copy_module_abi_files(mod, files, machine, abi_dir)
  for f in table.each(files) do
    local src = os.path.join(self.dirs.installed, machine .. '-android', f)
    assert(os.path.exists(src), src .. ' not exists')

    if f:startswith('include') then
      local dst = os.path.join(abi_dir, f)
      local dst_dir = os.path.dirname(dst)
      if not os.path.exists(dst_dir) then
        os.mkdirs(dst_dir)
      end
      os.copy_file(src, dst)

      if not self.module_include_files[mod][f] then
        self.module_include_files[mod][f] = {}
      end
      self.module_include_files[mod][f][machine] = {
        digest=ccpkg.hexdigest(src),
        file=dst
      }
    elseif f:match('^lib.*%.so$') then
      local dst = os.path.join(abi_dir, os.path.basename(f))
      os.copy_file(src, dst)
    elseif f:match('^lib.*%.a$') then
      local dst = os.path.join(abi_dir, os.path.basename(f))
      os.copy_file(src, dst)
    end
  end
end

function PrefabExporter:module_level_include_files()
  for mod in table.each(self.modules) do
    self:check_and_move_module_include_files(mod)
  end
end

function PrefabExporter:check_and_move_module_include_files(mod)
  local module_dir = os.path.join(self.prefab_dir, 'modules', mod)
  for f, hashes in pairs(self.module_include_files[mod]) do
    local hash = nil
    local same = true
    for h in table.each(hashes) do
      if hash == nil then
        hash = h.digest
      elseif h.digest ~= hash then
        same = false
        break
      end
    end

    if same then
      local dir = os.path.dirname(f)
      dir = os.path.join(module_dir, dir)
      if not os.path.exists(dir) then
        os.mkdirs(dir)
      end
  
      local dst = os.path.join(module_dir, f)
      for h in table.each(hashes) do
        if not os.path.exists(dst) then
          os.copy_file(h.file, dst)
        end
        os.remove(h.file)
      end
    end
  end

  -- remove empty dirs
  for abi in table.values(self.machine_to_abi) do
    local dir = os.path.join(module_dir, 'libs', 'android.' .. abi, 'include')
    local files = os.path.files(dir)
    if os.path.exists(dir) then
      if table.len(files) == 0 then
        os.rmdirs(dir)
      end
    end
  end
end

function PrefabExporter:write_abi_files()
  for mod in table.each(self.modules) do
    self:write_module_abi_files(mod)
  end
end

function PrefabExporter:write_module_abi_files(mod)
  for abi_id in table.each(self.machine_to_abi) do
    local abi_dir = os.path.join(self.prefab_dir, 'modules', mod, 'libs', 'android.' .. abi_id)
    self:write_abi_file(abi_id, abi_dir)
  end
end

function PrefabExporter:write_abi_file(abi_id, abi_dir)
  local file_path = os.path.join(abi_dir, 'abi.json')
  print('--- write to ' .. os.path.relpath(file_path, self.dirs.project_dir))

  local abi_file = io.open(file_path, 'w+')
  abi_file:write(table.concat({
    '{',
    '  "abi": "' .. abi_id .. '"',
    ', "api": ' .. self.target_sdk,
    ', "ndk": ' .. self.ndk_api,
    ', "stl": "' .. self.platform.android_stl .. '"',
  }, '\n'))

  if self:have_static_libs(abi_dir) then
    abi_file:write('\n, "static": true')
  end

  abi_file:write("\n}")
  abi_file:close()
end

function PrefabExporter:write_pom()
  self.data.pom_file = os.path.join(self.dirs.prefab, self.name, 'pom.xml')
  print('--- write to ' .. os.path.relpath(self.pom_file, self.dirs.project_dir))

  local pom_file = io.open(self.pom_file, 'w+')
  pom_file:write(table.concat({
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<project xmlns="http://maven.apache.org/POM/4.0.0"',
    '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
    '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">',
    '  <modelVersion>4.0.0</modelVersion>\n',
    '  <groupId>org.ccpkg.ndk.support</groupId>',
   ('  <artifactId>%s</artifactId>'):format(self.name),
   ('  <version>%s</version>'):format(self.version),
    '  <packaging>aar</packaging>',
   ('  <description>The ccpkg AAR for %s</description>'):format(self.name),
    '  <url>https://github.com/holmescn/ccpkg.git</url>\n',
    '</project>'
  }, '\n'))
  pom_file:close()
end

function PrefabExporter:write_android_manifest()
  self.data.android_manifest_file = os.path.join(self.aar_dir, 'AndroidManifest.xml')
  print('--- write to ' .. os.path.relpath(self.android_manifest_file, self.dirs.project_dir))

  local package_name = "org.ccpkg.ndk.support." .. self.name
  local manifest_file = io.open(self.android_manifest_file, 'w+')
  manifest_file:write(table.concat({
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android"',
    '          package="' .. package_name .. '"',
    '          android:versionCode="1"',
    '          android:versionName="1.0">',
   ('  <uses-sdk android:minSdkVersion="%s" android:targetSdkVersion="%s" />'):format(self.min_sdk, self.target_sdk),
    '</manifest>'
  }, '\n'))
  manifest_file:close()
end

function PrefabExporter:write_prefab_json()
  local package_data = self:load_package(self.name)
  self.data.prefab_json_file = os.path.join(self.prefab_dir, 'prefab.json')
  print('--- write to ' .. os.path.relpath(self.prefab_json_file, self.dirs.project_dir))

  local prefab_file = io.open(self.prefab_json_file, 'w+')
  prefab_file:write(table.concat({
    '{',
    '  "schema_version": 2',
    ', "name": "' .. self.name .. '"',
    ', "version": "' .. package_data.version .. '"',
    ', "dependencies": []',
    '}',
  }, '\n'))
  prefab_file:close()
end

function PrefabExporter:make_aar_file()
  local jar_path = os.which('jar')
  local zip_path = os.which('zip')
  local package_data = self:load_package(self.name)
  local aar_file = ("%s-%s.aar"):format(self.name, package_data.version)
  print('--- make ' .. aar_file)

  if jar_path then
    -- jar --create --file library.aar -C aar/ .
    local args = {jar_path, '--create', '--file', aar_file, '-C', 'aar/', '.'}
    os.run(args, {check=1, cwd=self.package_dir})
  elseif zip_path then
    -- zip -r ../library.aar *
    aar_file = os.path.join('..', aar_file)
    local args = {zip_path, '-r', aar_file, '*'}
    os.run(args, {check=1, cwd=self.aar_dir})
  end
end

return PrefabExporter