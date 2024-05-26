--!strict
--AnimTree @KashTheKing 5/26/2024

local ContentProvider = game:GetService("ContentProvider")

local Tree = require(script.Tree)

local animations = script.Animations

local AnimTree = {}
AnimTree.Tracks = {} :: { [Animator] : AnimationTrack }

--- Loads an animation into an AnimationTrack for the given animator.
-- @param animator The Animator instance to load the animation into.
-- @param source The Animation instance to load.
-- @return The loaded AnimationTrack.
function AnimTree:Load(animator: Animator, source: Animation) : AnimationTrack
	return animator:LoadAnimation(source)
end

--- Retrieves the cached animation tracks for the given animator.
-- @param animator The Animator instance whose cached tracks are to be retrieved.
-- @return A table containing the cached AnimationTrack instances for the animator.
function AnimTree:GetCached(animator: Animator) : { [string] : AnimationTrack }
	return self.Tracks[animator]
end

--- Clears the cached animation tracks for the given animator and destroys the tracks.
-- @param animator The Animator instance whose cache is to be cleared.
function AnimTree:ClearCache(animator: Animator)
	local cache = self.Tracks[animator]

	for name, track in cache do
		track:Destroy()
	end

	self.Tracks[animator] = {}
end

--- Caches the given animation tracks for the animator.
-- @param animator The Animator instance to cache tracks for.
-- @param tracks A table containing AnimationTrack instances to cache.
function AnimTree:Cache(animator: Animator, tracks: { [string] : AnimationTrack })
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

--- Retrieves all Animation objects from the given parent.
-- @param parent The parent instance to search for animations. Defaults to the `animations` script.
-- @return A table containing all Animation objects found.
function AnimTree:GetAnimationObjects(parent) : { Animation }
	local animationObjects = {}

	parent = parent or animations

	for _, animation in parent:GetDescendants() do
		if animation:IsA("Animation") then
			table.insert(animationObjects, animation)
		end
	end

	return animationObjects
end

--- Retrieves an Animation object given its path.
-- @param pathToAnimation The path to the Animation object.
-- @return The Animation object found at the given path.
function AnimTree:GetAnimationObject(pathToAnimation: string) : Animation
	local sourceObject = Tree.Find(animations, pathToAnimation, "Animation")

	return sourceObject :: Animation
end

--- Loads an AnimationTrack from a given path to an animation.
-- @param animator The Animator instance to load the animation into.
-- @param pathToAnimation The path to the Animation object.
-- @return The loaded AnimationTrack.
function AnimTree:LoadFromPath(animator: Animator, pathToAnimation: string) : AnimationTrack
	local animation = self:GetAnimationObject(pathToAnimation)

	assert(animation, 'Missing animation at path: '.. pathToAnimation)

	return self:Load(animator, animation)
end

--- Loads all AnimationTracks from a given directory path or instance.
-- @param animator The Animator instance to load the animations into.
-- @param directoryPathOrInstance The path to the directory or the Folder instance containing the animations.
-- @return A table containing all loaded AnimationTrack instances.
function AnimTree:LoadDirectory(animator: Animator, directoryPathOrInstance: Folder | string) : { [string] : AnimationTrack }
	local directory: Folder

	if type(directoryPathOrInstance) == 'string' then
		directory = Tree.Find(animations, directoryPathOrInstance) :: Folder 
		assert(directory, 'No directory found at ' .. directoryPathOrInstance)
	else
		directory = directoryPathOrInstance
	end

	local loadedTracks: {[string] : AnimationTrack} = {}

	for _, source: Animation in self:GetAnimationObjects(directory) do
		loadedTracks[source.Name] = self:Load(animator, source)
	end

	return loadedTracks
end

--- Preloads a given list of AnimationTrack objects or Animation objects
-- @param assetCallback A callback function to handle each asset being preloaded.
-- @return A boolean indicating success and the result of the preload operation.
function AnimTree:PreloadList(list: { AnimationTrack | Animation }, assetCallback: () -> (string, Enum.AssetFetchStatus))
	local success, result = pcall(function()
		ContentProvider:PreloadAsync(self.Tracks, assetCallback)
	end)

	return success, result
end

--- Preloads all animations and tracks.
-- @param assetCallback A callback function to handle each asset being preloaded.
-- @return A boolean indicating success and the result of the preload operation.
function AnimTree:PreloadAll(assetCallback: () -> (string, Enum.AssetFetchStatus))
	local success, result = pcall(function()
		ContentProvider:PreloadAsync(self:GetAnimationObjects(), assetCallback)
		ContentProvider:PreloadAsync(self.Tracks, assetCallback)
	end)

	return success, result
end

return AnimTree