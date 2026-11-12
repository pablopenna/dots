class_name RemoteEditorsTreeDataSourceGithub


class Self extends RemoteEditorsTreeDataSource.I:
	var _assets: RemoteEditorsTreeDataSource.RemoteAssets
	const platforms = {
		"X11": {
			"suffixes": [
				"_x11.64.zip", "_linux.64.zip", "_linux.x86_64.zip", "_linux.x86_32.zip",
				"_linux_x86_64.zip", "_linux_x86_32.zip",
				# Redot
				"_linux_x64.zip", "_linux_arm64.zip",
				"_linux_mono_x64.zip", "_linux_mono_arm64.zip",
			],
		},
		"OSX": {
			"suffixes": [
				"_osx.universal.zip", "_macos.universal.zip", "_osx.fat.zip", "_osx32.zip", "_osx64.zip",
				# Redot
				"_macos_universal.zip", "_macos_mono_universal.zip",
			],
		},
		"Windows": {
			"suffixes": [
				"_win64.exe.zip", "_win32.exe.zip", "_win64.zip", "_win32.zip",
				# Redot
				"_windows_win64.zip", "_windows_mono_win64.zip",
			],
		}
	}
	
	func _init(assets: RemoteEditorsTreeDataSource.RemoteAssets) -> void:
		_assets = assets
	
	func setup(tree: Tree) -> void:
		var root := tree.create_item()
		var godot_source := GithubVersionSourceParseYml.new(
			YmlSourceGithub.new(),
			GithubAssetSourceDefault.new()
		)
		root.set_meta(
			"delegate", 
			GithubRootsItem.new(
				root,
				_assets,
				[
					GithubRoot.new("Godot", godot_source),
					GithubRoot.new("Redot", RedotVersionSource.new()),
				],
			)
		)
	
	func cleanup(tree: Tree) -> void:
		tree.clear()
	
	func get_platform_suffixes() -> Array:
		var current_platform: Dictionary
		if OS.has_feature("windows"):
			current_platform = platforms["Windows"]
		elif OS.has_feature("macos"):
			current_platform = platforms["OSX"]
		elif OS.has_feature("linux"):
			current_platform = platforms["X11"]
		return current_platform["suffixes"]
	
	func to_remote_item(item: TreeItem) -> RemoteEditorsTreeDataSource.Item:
		return item.get_meta("delegate")


class GithubVersion:
	var name: String
	var flavor: String
	var releases: Array[String] = []
	var is_redot := false
	var _assets_src: GithubAssetSource
	
	func get_flavor_release() -> GodotRelease:
		return GodotRelease.new(name, flavor, _assets_src, is_redot)
	
	func get_recent_releases() -> Array[GodotRelease]:
		var result: Array[GodotRelease] = []
		for r in releases:
			result.append(GodotRelease.new(name, r, _assets_src, is_redot))
		return result


class GodotRelease:
	var name: String
	var is_redot: bool
	var _version: String
	var _assets_src: GithubAssetSource
	
	func _init(version: String, name: String, assets_src: GithubAssetSource, is_redot:=false) -> void:
		self.name = name
		self.is_redot = is_redot
		_assets_src = assets_src
		_version = version
	
	func is_stable() -> bool:
		return name == "stable"
	
	func async_load_assets() -> Array[GodotAsset]:
		return await _assets_src.async_load(_version, name)


class GodotAsset:
	var _json: Dictionary
	
	var name: String:
		get: return _json.get("name", "")
	
	var file_name: String:
		get: return browser_download_url.get_file()
	
	var browser_download_url: String:
		get: return _json.get("browser_download_url", "")
	
	var is_zip: bool:
		get: return name.get_extension() == "zip"
	
	func _init(json: Dictionary) -> void:
		_json = json


class GithubItemBase extends RemoteEditorsTreeDataSource.Item:
	var _item: TreeItem
	var _assets: RemoteEditorsTreeDataSource.RemoteAssets
	
	func _init(item: TreeItem, assets: RemoteEditorsTreeDataSource.RemoteAssets) -> void:
		_item = item
		_assets = assets
	
	func is_loaded() -> bool:
		return _item.has_meta("loaded")
	
	func async_expand(tree: RemoteTree) -> void:
		return
	
	func handle_item_activated() -> void:
		pass
	
	func handle_button_clicked(col: int, id: int, mouse: int) -> void:
		pass
	
	func update_visibility(filters: Array) -> void:
		var filter_target := _to_filter_target() 
		if filter_target == null:
			return
		_item.visible = _should_be_visible(filter_target, filters)
	
	func _should_be_visible(target: GithubFilterTarget, filters: Array) -> bool:
		if target.is_file() and not target.is_zip():
			return false

		for filter: RemoteEditorsTreeControl.RowFilter in filters:
			if filter.test(target):
				return false
		
		return true
	
	func _to_filter_target() -> GithubFilterTarget:
		return null
	
	func _asset_to_item(asset: GodotAsset, tree: RemoteEditorsTreeDataSource.RemoteTree, is_redot:=false) -> void:
		var tree_item := tree.create_item(_item)
		tree_item.set_meta("delegate", GithubAssetItem.new(tree_item, _assets, asset))
		tree_item.set_text(0, asset.name)
		if is_redot:
			tree_item.set_icon(0, preload("res://assets/Redot128x128.svg") as Texture2D)
		else:
			tree_item.set_icon(0, tree.theme_source.get_theme_icon("Godot", "EditorIcons"))
		var btn_texture: Texture2D = tree.theme_source.get_theme_icon("AssetLib", "EditorIcons")
		tree_item.add_button(0, btn_texture)
		tree_item.collapsed = true
	
	func get_children() -> Array[RemoteEditorsTreeDataSource.Item]:
		var result: Array[RemoteEditorsTreeDataSource.Item] = []
		for child in _item.get_children():
			if child.has_meta("delegate"):
				result.append(child.get_meta("delegate"))
		return result


class GithubAssetItem extends GithubItemBase:
	var _asset: GodotAsset
	
	func _init(item: TreeItem, assets: RemoteEditorsTreeDataSource.RemoteAssets, asset: GodotAsset) -> void:
		super._init(item, assets)
		_asset = asset
	
	func _to_filter_target() -> GithubFilterTarget:
		return GithubFilterTarget.new(_asset.name, false, true, _asset.is_zip)

	func handle_item_activated() -> void:
		_assets.download(_asset.browser_download_url, _asset.file_name)

	func handle_button_clicked(col: int, id: int, mouse: int) -> void:
		_assets.download(_asset.browser_download_url, _asset.file_name)


class GithubReleaseItem extends GithubItemBase:
	var _release: GodotRelease
	
	func _init(item: TreeItem, assets: RemoteEditorsTreeDataSource.RemoteAssets, release: GodotRelease) -> void:
		super._init(item, assets)
		_release = release
	
	func async_expand(tree: RemoteEditorsTreeDataSource.RemoteTree) -> void:
		_item.set_meta("loaded", true)
		var assets := await _release.async_load_assets()
		for asset in assets:
			_asset_to_item(asset, tree, _release.is_redot)
		tree.free_loading_placeholder(_item)

	func _to_filter_target() -> GithubFilterTarget:
		return GithubFilterTarget.new(_release.name, false, false, false)


class GithubVersionItem extends GithubItemBase:
	var _version: GithubVersion
	
	func _init(item: TreeItem, assets: RemoteEditorsTreeDataSource.RemoteAssets, version: GithubVersion) -> void:
		super._init(item, assets)
		_version = version
	
	func async_expand(tree: RemoteEditorsTreeDataSource.RemoteTree) -> void:
		_item.set_meta("loaded", true)
		
		var releases: Array[GodotRelease] = []
		var flavor := _version.get_flavor_release()
		if not flavor.is_stable():
			releases.append(flavor)
		releases.append_array(_version.get_recent_releases())
		
		for release in releases:
			var tree_item := tree.create_item(_item)
			tree_item.visible = false
			tree_item.set_text(0, release.name)
			tree.set_as_folder(tree_item)
			tree_item.set_meta(
				"delegate", 
				GithubReleaseItem.new(tree_item, _assets, release)
			)
			tree_item.collapsed = true
		
		if flavor.is_stable():
			var assets := await flavor.async_load_assets()
			for asset in assets:
				_asset_to_item(asset, tree, _version.is_redot)

		tree.free_loading_placeholder(_item)

	func _to_filter_target() -> GithubFilterTarget:
		return GithubFilterTarget.new(_version.name, true, false, false, _version.is_redot)


class GithubRoot:
	var name: String
	var versions_source: GithubVersionSource

	func _init(name: String, versions_source: GithubVersionSource) -> void:
		self.name = name
		self.versions_source = versions_source


class GithubRootsItem extends GithubItemBase:
	var _roots: Array[GithubRoot]

	func _init(item: TreeItem, assets: RemoteEditorsTreeDataSource.RemoteAssets, roots: Array[GithubRoot]) -> void:
		super._init(item, assets)
		_roots = roots

	func async_expand(tree: RemoteEditorsTreeDataSource.RemoteTree) -> void:
		_item.set_meta("loaded", true)
		for root in _roots:
			var tree_item := tree.create_item(_item)
			tree.set_as_folder(tree_item)
			tree_item.set_text(0, root.name)
			var root_item := GithubRootItem.new(tree_item, _assets, root.versions_source)
			tree_item.set_meta("delegate", root_item)
			await root_item.async_expand(tree)
			tree_item.collapsed = false
		tree.free_loading_placeholder(_item)


class GithubRootItem extends GithubItemBase:
	var _versions_source: GithubVersionSource
	
	func _init(item: TreeItem, assets: RemoteEditorsTreeDataSource.RemoteAssets, versions_source: GithubVersionSource) -> void:
		super._init(item, assets)
		_versions_source = versions_source
	
	func async_expand(tree: RemoteEditorsTreeDataSource.RemoteTree) -> void:
		_item.set_meta("loaded", true)
		var versions := await _versions_source.async_load()
		for version in versions:
			var tree_item := tree.create_item(_item)
			tree.set_as_folder(tree_item)
			tree_item.set_text(0, version.name)
			tree_item.set_meta("delegate", GithubVersionItem.new(tree_item, _assets, version))
			tree_item.collapsed = true
		tree.free_loading_placeholder(_item)


class GithubFilterTarget extends RemoteEditorsTreeDataSource.FilterTarget:
	var _name: String
	var _is_possible_version_folder: bool
	var _is_file: bool
	var _is_zip: bool
	var _is_redot: bool

	func _init(name: String, is_possible_version_folder: bool, is_file: bool, is_zip: bool, is_redot:=false) -> void:
		_name = name
		_is_possible_version_folder = is_possible_version_folder
		_is_file = is_file
		_is_zip = is_zip
		_is_redot = is_redot

	func is_possible_version_folder() -> bool:
		return _is_possible_version_folder

	func is_file() -> bool:
		return _is_file

	func is_zip() -> bool:
		return _is_zip

	func is_redot() -> bool:
		return _is_redot

	func is_for_different_platform(platform_suffixes: Array) -> bool:
		var cached_name := get_name()
		return not platform_suffixes.any(func(suffix: String) -> bool: return cached_name.ends_with(suffix))

	func get_name() -> String:
		return _name


class GithubVersionSource:
	func async_load() -> Array[GithubVersion]:
		return []


class GithubAssetSource:
	func async_load(version: String, release: String) -> Array[GodotAsset]:
		return []


class GithubAssetSourceDefault extends GithubAssetSource:
	const url = "https://api.github.com/repos/godotengine/godot-builds/releases/tags/%s"
	
	func async_load(version: String, release: String) -> Array[GodotAsset]:
		var tag := "%s-%s" % [version, release]
		var response := await HttpClient.async_http_get(
			url % tag,
			["Accept: application/vnd.github.v3+json"]
		)
		var json: Dictionary = JSON.parse_string(
			(response[3] as PackedByteArray).get_string_from_utf8()
		)
		var result: Array[GodotAsset] = []
		for asset_json: Dictionary in json.get('assets', []):
			result.append(GodotAsset.new(asset_json))
		return result


class GithubAssetSourceRepo extends GithubAssetSource:
	const url = "https://api.github.com/repos/%s/releases/tags/%s"

	var _repo: String
	var _tag_format: String

	func _init(repo: String, tag_format: String) -> void:
		_repo = repo
		_tag_format = tag_format

	func async_load(version: String, release: String) -> Array[GodotAsset]:
		var tag := _tag_format % [version, release]
		var response := await HttpClient.async_http_get(
			url % [_repo, tag],
			["Accept: application/vnd.github.v3+json"]
		)
		var json: Variant = utils.parse_json_safe(
			(response[3] as PackedByteArray).get_string_from_utf8()
		)
		var result: Array[GodotAsset] = []
		if not json is Dictionary:
			return result
		var json_dict := json as Dictionary
		for asset_json: Dictionary in json_dict.get('assets', []):
			result.append(GodotAsset.new(asset_json))
		return result


class GithubAssetSourceFileJson extends GithubAssetSource:
	var _file_path: String
	
	func _init(file_path: String) -> void:
		_file_path = file_path
	
	func async_load(version: String, release: String) -> Array[GodotAsset]:
		var json: Dictionary = JSON.parse_string(FileAccess.open(_file_path, FileAccess.READ).get_as_text())
		var result: Array[GodotAsset] = []
		for asset_json: Dictionary in json.get('assets', []):
			result.append(GodotAsset.new(asset_json))
		return result


class GithubVersionSourceFileJson extends GithubVersionSource:
	var _file_path: String
	var _assets_src: GithubAssetSource
	
	func _init(file_path: String, assets_src: GithubAssetSource) -> void:
		_file_path = file_path
		_assets_src = assets_src
	
	func async_load() -> Array[GithubVersion]:
		var json: Array = JSON.parse_string(FileAccess.open(_file_path, FileAccess.READ).get_as_text())
		var result: Array[GithubVersion] = []
		for el: Dictionary in json:
			var version := GithubVersion.new()
			version._assets_src = _assets_src
			version.name = el.name
			version.flavor = el.flavor
			for release: Dictionary in el.get('releases', []):
				version.releases.append(release.name)
			result.append(version)
		return result


class YmlSource:
	func async_load(errors: Array[String]=[]) -> String:
		return ""


class YmlSourceFile extends YmlSource:
	var _file_path: String
	
	func _init(file_path: String) -> void:
		_file_path = file_path
	
	func async_load(errors: Array[String]=[]) -> String:
		var text := FileAccess.open(_file_path, FileAccess.READ).get_as_text() 
		return text


class YmlSourceGithub extends YmlSource:
	const url = "https://raw.githubusercontent.com/godotengine/godot-website/master/_data/versions.yml"
	func async_load(errors: Array[String]=[]) -> String:
		var response := HttpClient.Response.new(await HttpClient.async_http_get(url))
		var info := response.to_response_info(url)
		if info.error_text:
			errors.append(info.error_text)
		var text := response.get_string_from_utf8()
		return text


class RedotVersionSource extends GithubVersionSource:
	const REPO = "Redot-Engine/redot-engine"
	const RELEASES_URL = "https://api.github.com/repos/Redot-Engine/redot-engine/releases"
	const PER_PAGE = 100

	var _tag_regex := RegEx.create_from_string("^redot-(?<version>\\d+(?:\\.\\d+)+)-(?<release>.+)$")
	var _assets_src := GithubAssetSourceRepo.new(REPO, "redot-%s-%s")

	func async_load() -> Array[GithubVersion]:
		var result: Array[GithubVersion] = []
		var versions_by_name: Dictionary[String, GithubVersion] = {}
		var page := 1
		while true:
			var response := await HttpClient.async_http_get(
				"%s?per_page=%s&page=%s" % [RELEASES_URL, PER_PAGE, page],
				["Accept: application/vnd.github.v3+json"]
			)
			var json: Variant = utils.parse_json_safe(
				(response[3] as PackedByteArray).get_string_from_utf8()
			)
			if not json is Array:
				break
			var releases: Array = json
			for release: Dictionary in releases:
				var tag_match := _tag_regex.search(str(release.get("tag_name", "")))
				if tag_match == null:
					continue
				var version_name := tag_match.get_string("version")
				var release_name := tag_match.get_string("release")
				var version := versions_by_name.get(version_name) as GithubVersion
				if version == null:
					version = GithubVersion.new()
					version._assets_src = _assets_src
					version.name = version_name
					version.is_redot = true
					versions_by_name[version_name] = version
					result.append(version)
				version.releases.append(release_name)
			if releases.size() < PER_PAGE:
				break
			page += 1

		for version in result:
			# The flavor is shown directly under the version node and must not
			# be duplicated as a separate release folder.
			if version.releases.has("stable"):
				version.flavor = "stable"
			elif not version.releases.is_empty():
				version.flavor = version.releases[0]
			version.releases.erase(version.flavor)
		return result


class GithubVersionSourceParseYml extends GithubVersionSource:
	var _src: YmlSource
	var _assets_src: GithubAssetSource
	
	var _version_regex := RegEx.create_from_string('(?m)^-[\\s\\S]*?(?=^-|\\Z)')
	var _name_regex := RegEx.create_from_string('(?m)\\sname:\\s"(?<name>[^"]+)"$')
	var _flavor_regex := RegEx.create_from_string('(?m)\\sflavor:\\s"(?<flavor>[^"]+)"$')
	
	func _init(src: YmlSource, assets_src: GithubAssetSource) -> void:
		_src = src
		_assets_src = assets_src
	
	func async_load() -> Array[GithubVersion]:
		var yml := await _src.async_load()
		var result: Array[GithubVersion] = []
		var versions := _version_regex.search_all(yml)
		for version_result in versions:
			var version_string := version_result.get_string()
			var name_results := _name_regex.search_all(version_string)
			var flavor_result := _flavor_regex.search(version_string)
			if len(name_results) == 0 or flavor_result == null:
				continue
			var version := GithubVersion.new()
			version._assets_src = _assets_src
			version.name = name_results[0].get_string("name")
			version.flavor = flavor_result.get_string("flavor")
			for release_name: RegExMatch in name_results.slice(1):
				version.releases.append(release_name.get_string("name"))
			result.append(version)
		return result
