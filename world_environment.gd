# This code is simply a script that must be attached to a WorldEnvironment node
# to match the quality of the environment to the available VRAM memory
extends WorldEnvironment

# Name of the unique GameInstance variable for THIS environment
@export var controlVar: String = ""

func _init() -> void : pass

func _ready() -> void :

	# -------------------------------------------------------------------------
	# BLOCK A: VIEWPORT AND GLOBAL DETECTION (Controlled within gpu_data)
	# -------------------------------------------------------------------------

	# In GameInstance we must have a structure like this:

	# Unified Data Structure for Hardware and Video Status
	# var gpu_data : Dictionary = {
	#	 "vp_detectada": false,         # Checks if the Viewport/Hardware has already been processed
	#	 "vram": 512.0 / 1024.0,        # Secure default value in Gigabytes
	#	 "type": 0                      # Device Type (Dedicated, Integrated, etc.)
	# }

	if not GameInstance.gpu_data["vp_detectada"] :
	
		# The Viewport is the window or region of the screen that is responsible for rendering and displaying your scene
		# The ViewPort configuration affects the last step of the rendering pipeline once we have the pixel mesh
		var vp = get_viewport()

		# ConfigRender is the static class where the configurations for each of the defined graphics profiles are carried out: Low, Medium, High, Ultra
		ConfigRender.apply_default_viewport_settings(vp)

	# -------------------------------------------------------------------------
	# BLOCK B: LOCAL ENVIRONMENT (Executed for each new map only once)
	# -------------------------------------------------------------------------

	# If controlVar is not defined, it means that the configuration must be done.
	if controlVar != "" :

		# The exported controlVar variable will have a variable name that will exist in GameInstance and will be assigned false as the default value
		var already_configured_env = GameInstance.get(controlVar)

		# If this specific environment has already been processed in the past or de defined variable in controlVar doesnt exist in GameInstance, we leave immediately
		if already_configured_env == true or already_configured_env == null : return

		# We mark this map as persistently configured in Autoload
		GameInstance.set(controlVar, true)

	# We apply the local parameters by consuming the data of the structure without recalculating anything
	_configure_local_environment(GameInstance.gpu_data)
	


func _configure_local_environment(gpu: Dictionary) -> void :

	# If the native property does not exist, we leave
	if not environment: return

	# Use this to avoid crashes if the dictionary is incomplete
	var vram: float = float(gpu.get("vram", 0.0))
	var type: int = int(gpu.get("type", RenderingDevice.DEVICE_TYPE_OTHER))

	# If the card is integrated or has less than 2.5 GB
	if (type == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU or vram <= 2.5) :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.LOW, null, environment)

	# If the card is dedicated with less than 4.5 GB
	elif (type != RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram <= 4.5) :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.MEDIUM, null, environment)

	# if the card is dedicated with less than 8.5 GB
	elif (type != RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram <= 8.5) :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.HIGH, null, environment)

	# if the card is dedicated with more than 8.5 GB
	else :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.ULTRA, null, environment)
