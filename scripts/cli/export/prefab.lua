---@diagnostic disable: undefined-field
local ccpkg = require "ccpkg"
local PrefabExporter = {
  machine_to_abi={
    arm='armeabi-v7a',
    arm64='arm64-v8a',
    x86='x86',
    x64='x86_64',
  }
}

function PrefabExporter:init(parser)
  return self
end

function PrefabExporter:load_package(name)
  local packages_dir = self.project.dirs.packages
  for f in os.listdir(packages_dir) do
    if f:startswith(name) then
      local package_file = os.path.join(packages_dir, f)
      return dofile(package_file)
    end
  end
  print('--- ' .. name .. ' is not installed')
end

function PrefabExporter:execute(project, spec)
  self.project = project
  self.platform = require('platform.android'):init(project)
  spec.min_sdk = spec.min_sdk or 21
  spec.target_sdk = spec.target_sdk or 31
  spec.ndk_api = spec.ndk_api or self.platform.ndk_api
  spec.group_id = spec.group_id or 'org.ccpkg.ndk.support'
  spec.artifact_id = spec.artifact_id or spec.name
  self.spec = spec
  if not spec.version then
    local package_data = self:load_package(spec.name)
    spec.version = package_data.version
  end

  self.project.dirs.prefab = os.path.join(self.project.dirs['.ccpkg'], 'prefab')
  if not os.path.exists(self.project.dirs.prefab) then
    os.mkdirs(self.project.dirs.prefab)
  end

  spec.package_dir = os.path.join(self.project.dirs.prefab, self.spec.name)
  if os.path.exists(self.spec.package_dir) then
    os.rmdirs(spec.package_dir)
  end

  spec.aar_dir = os.path.join(spec.package_dir, 'aar')
  os.mkdirs(spec.aar_dir)

  spec.prefab_dir = os.path.join(spec.aar_dir, 'prefab')
  os.mkdirs(spec.prefab_dir)

  for mod in table.each(spec.modules) do
    local module_data = self:load_package(mod)
    assert(module_data, mod .. ' is not installed')
  
    local module_name = mod
    if mod:match("^lib") then
      module_name = mod:gsub("^lib", "")
    end
    local module_dir = os.path.join(self.spec.prefab_dir, 'modules', module_name)
    local module_files = self:copy_module_files(module_data.files, module_dir)
    self:check_and_move_module_include_files(module_dir, module_files)
    self:remove_empty_dirs(module_dir)
    self:write_abi_files(module_dir)
  end

  self:write_prefab_json(spec)
  self:write_android_manifest(spec)
  self:make_aar_file(spec)
  if spec.maven then
    self:local_maven_install(spec)
  end
end

function PrefabExporter:copy_module_files(files, module_dir)
  local module_files = {}
  for machine, abi in pairs(self.machine_to_abi) do
    local abi_dir = os.path.join(module_dir, 'libs', 'android.' .. abi)
    local vars = {
      abi=abi,
      machine=machine,
      abi_dir=abi_dir,
      files=files,
      module_files=module_files
    }
    self:copy_abi_files(vars, files, module_files)
  end
  return module_files
end

function PrefabExporter:copy_abi_files(vars)
  for f in table.each(vars.files) do
    local src = os.path.join(self.project.dirs.installed, vars.machine .. '-android', f)
    -- assert(os.path.exists(src), src .. ' not exists')

    if f:startswith('include') then
      local dst = os.path.join(vars.abi_dir, f)
      local dst_dir = os.path.dirname(dst)
      if not os.path.exists(dst_dir) then
        os.mkdirs(dst_dir)
      end
      os.copy_file(src, dst)

      if not vars.module_files[f] then
        vars.module_files[f] = {}
      end
      vars.module_files[f][vars.abi] = dst
    elseif f:match('^lib.*%.so$') then
      local dst = os.path.join(vars.abi_dir, os.path.basename(f))
      os.copy_file(src, dst)
    elseif f:match('^lib.*%.a$') then
      local dst = os.path.join(vars.abi_dir, os.path.basename(f))
      os.copy_file(src, dst)
    end
  end
end

function PrefabExporter:check_and_move_module_include_files(module_dir, module_files)
  for f, machine_files in pairs(module_files) do
    local hash = nil
    local all_same = true
    for file in table.values(machine_files) do
      if hash == nil then
        hash = ccpkg.digest(file)
      elseif hash ~= ccpkg.digest(file) then
        all_same = false
        break
      end
    end

    if all_same then
      local dst = os.path.join(module_dir, f)
      local dst_dir = os.path.dirname(dst)
      if not os.path.exists(dst_dir) then
        os.mkdirs(dst_dir)
      end

      for src in table.values(machine_files) do
        os.copy_file(src, dst, {skip=1})
        os.remove(src)
      end
    end
  end
end

function PrefabExporter:remove_empty_dirs(module_dir)
  -- remove empty include dirs
  for abi in table.values(self.machine_to_abi) do
    local dir = os.path.join(module_dir, 'libs', 'android.' .. abi, 'include')
    if os.path.exists(dir) then
      local files = os.path.files(dir)
      if table.len(files) == 0 then
        os.rmdirs(dir)
      end
    end
  end

  -- remove empty libs dir
  local dir = os.path.join(module_dir, 'libs')
  if os.path.exists(dir) then
    local files = os.path.files(dir)
    if table.len(files) == 0 then
      os.rmdirs(dir)
    end
  end
end

function PrefabExporter:write_abi_files(module_dir)
  local module_libs_dir = os.path.join(module_dir, 'libs')
  if os.path.exists(module_libs_dir) then
    for abi in table.values(self.machine_to_abi) do
      local abi_dir = os.path.join(module_libs_dir, 'android.' .. abi)
      self:write_abi_file(abi, abi_dir)
    end
  end
end

function PrefabExporter:write_abi_file(abi, abi_dir)
  local file_path = os.path.join(abi_dir, 'abi.json')
  local abi_file = io.open(file_path, 'w+')
  abi_file:write(table.concat({
    '{',
    '  "abi": "' .. abi .. '"',
    ', "api": ' .. self.spec.target_sdk,
    ', "ndk": ' .. self.spec.ndk_api,
    ', "stl": "' .. self.platform.android_stl .. '"',
    "}"
  }, '\n'))
  abi_file:close()
end

function PrefabExporter:write_prefab_json(spec)
  print('--- write prefab.json')
  local file_path = os.path.join(spec.prefab_dir, 'prefab.json')
  local prefab_file = io.open(file_path, 'w+')
  prefab_file:write(table.concat({
    '{',
    '  "schema_version": 1',
    ', "name": "' .. spec.artifact_id .. '"',
    ', "version": "' .. spec.version .. '"',
    ', "dependencies": []',
    '}',
  }, '\n'))
  prefab_file:close()
end

function PrefabExporter:write_android_manifest(spec)
  print('--- write AndroidManifest.xml')

  local file_path = os.path.join(spec.aar_dir, 'AndroidManifest.xml')
  local package_name = "org.ccpkg.ndk.support." .. spec.artifact_id
  local manifest_file = io.open(file_path, 'w+')
  manifest_file:write(table.concat({
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android"',
    '          package="' .. package_name .. '"',
    '          android:versionCode="1"',
    '          android:versionName="1.0">',
   ('  <uses-sdk android:minSdkVersion="%s" android:targetSdkVersion="%s" />'):format(spec.min_sdk, spec.target_sdk),
    '</manifest>'
  }, '\n'))
  manifest_file:close()
end

function PrefabExporter:make_aar_file(spec)
  local jar_path = os.which('jar')
  local zip_path = os.which('zip')
  local aar_file = ("%s-%s.aar"):format(spec.name, spec.version)
  spec.aar_file = os.path.join(spec.package_dir, aar_file)
  print('--- make ' .. aar_file)

  if jar_path then
    -- jar --create --file library.aar -C aar/ .
    local args = {jar_path, '--create', '--file', aar_file, '-C', 'aar/', '.'}
    os.run(args, {check=1, cwd=spec.package_dir})
  elseif zip_path then
    -- zip -r ../library.aar *
    aar_file = os.path.join('..', aar_file)
    local args = {zip_path, '-r', aar_file, '*'}
    os.run(args, {check=1, cwd=spec.aar_dir})
  else
    error("both jar and zip are not found in $PATH")
  end
end

function PrefabExporter:local_maven_install(spec)
  local mvn_path = os.which('mvn')
  assert(mvn_path, 'mvn is not found in $PATH')

  local log_file = ('export-%s-%s.log'):format(spec.name, spec.version)
  print('--- install ' .. os.path.basename(spec.aar_file) .. ' to local Maven repository')
  local args = {
    mvn_path,
    'install:install-file',
    '-Dfile=' .. spec.aar_file,
    '-DgroupId=' .. spec.group_id,
    '-DartifactId=' .. spec.artifact_id,
    '-Dversion=' .. spec.version,
    '-Dpackaging=aar',
    '-DgeneratePom=true'
  }
  os.run(args, {check=1, cwd=spec.package_dir, file=log_file})
end

return PrefabExporter