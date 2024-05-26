--!strict
--AnimTree @KashTheKing 5/26/2024

local ContentProvider = game:GetService("ContentProvider")

--[=[
	@class Tree
]=]
local Tree = require(script.Tree)

local animations = script.Animations

--[=[
	@class AnimTree
]=]
local AnimTree = {}
AnimTree.Tracks = {} :: { [Animator]: { [string]: AnimationTrack } }

--[=[
	Loads an animation from an animator object and an animation object.
	
	@param animator Animator -- The animator you want to load to.
	@param source Animation -- The animation you want to load.
	@return AnimationTrack -- Returns the loaded track.
]=]
function AnimTree:Load(animator: Animator, source: Animation): AnimationTrack
	return animator:LoadAnimation(source)
end

--[=[
	Retrieves cached animation tracks for an animator.
	
	@param animator Animator -- The cached animator.
	@return table<string, AnimationTrack> -- Returns the loaded track.
]=]
function AnimTree:GetCached(animator: Animator): { [string]: AnimationTrack }
	return self.Tracks[animator]
end

--[=[
	Clears cached animation tracks for an animator.
	
	@param animator Animator -- The cached animator.
]=]
function AnimTree:ClearCache(animator: Animator)
	local cache = self.Tracks[animator]

	for name, track in cache do
		track:Destroy()
	end

	self.Tracks[animator] = {}
end

--[=[
	Caches animation tracks for an animator.
	
	@param animator Animator -- Animator to be cached.
	@param tracks table<string, AnimationTrack> -- Tracks to be cached.
]=]
function AnimTree:Cache(animator: Animator, tracks: { [string]: AnimationTrack })
	if not self.Tracks[animator] then
		self.Tracks[animator] = {}
	end

	for name, track in tracks do
		self.Tracks[animator][name] = track
	end

	animator.Destroying:Once(function()
		self:ClearCache(animator)
	end)
end

--[=[
	Retrieves animation objects from an instance, or from the root path by default.
	
	@param parent Instance -- Instance to retrieve animations from.
	@return table<Animation>
]=]
function AnimTree:GetAnimationObjects(parent: Instance): { Animation }
	local animationObjects = {}

	parent = parent or animations

	for _, animation in parent:GetDescendants() do
		if animation:IsA("Animation") then
			table.insert(animationObjects, animation)
		end
	end

	return animationObjects
end

--[=[
	Retrieves an animation object from a given path.
	
	@param pathToAnimation string -- Path to animation object; i.e 'NPC/Movement/Walk'.
	@return Animation
]=]
function AnimTree:GetAnimationObject(pathToAnimation: string): Animation
	local sourceObject = Tree.Find(animations, pathToAnimation, "Animation")

	return sourceObject :: Animation
end

--[=[
	Loads an animation from a given path to an animator.
	
	@param animator Animator -- Animator to load animation to.
	@param pathToAnimation string -- Path to animation object.
	@return AnimationTrack
]=]
function AnimTree:LoadFromPath(animator: Animator, pathToAnimation: string): AnimationTrack
	local animation = self:GetAnimationObject(pathToAnimation)

	assert(animation, 'Missing animation at path: ' .. pathToAnimation)

	return self:Load(animator, animation)
end

--[=[
	Loads all animations from a directory to an animator.
	
	@param animator Animator -- Animator to load animations to.
	@param directoryPathOrInstance Folder | string -- Directory or path to load from.
	@return table<string, AnimationTrack>
]=]
function AnimTree:LoadDirectory(animator: Animator, directoryPathOrInstance: Folder | string): { [string]: AnimationTrack }
	local directory: Folder

	if type(directoryPathOrInstance) == 'string' then
		directory = Tree.Find(animations, directoryPathOrInstance) :: Folder 
		assert(directory, 'No directory found at ' .. directoryPathOrInstance)
	else
		directory = directoryPathOrInstance
	end

	local loadedTracks: { [string]: AnimationTrack } = {}

	for _, source: Animation in self:GetAnimationObjects(directory) do
		loadedTracks[source.Name] = self:Load(animator, source)
	end

	return loadedTracks
end

--[=[
	Preloads a list of animation objects or animation tracks.
	
	@param list table<AnimationTrack|Animation>
	@param assetCallback function -- Function to call for each asset being preloaded.
	@return boolean, string -- Indicates success and the result of the preload operation.
	@yields
]=]
function AnimTree:PreloadList(list: { AnimationTrack | Animation }, assetCallback: () -> (string, Enum.AssetFetchStatus))
	local success, result = pcall(function()
		ContentProvider:PreloadAsync(list, assetCallback)
	end)

	return success, result
end

--[=[
	Preloads all animation objects and cached animation tracks.
	
	@param assetCallback function -- Function to call for each asset being preloaded.
	@return boolean, string -- Indicates success and the result of the preload operation.
	@yields
]=]
function AnimTree:PreloadAll(assetCallback: () -> (string, Enum.AssetFetchStatus))
	local success, result = pcall(function()
		ContentProvider:PreloadAsync(self:GetAnimationObjects(), assetCallback)
		ContentProvider:PreloadAsync(self.Tracks, assetCallback)
	end)

	return success, result
end

return AnimTree