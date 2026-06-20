# This code is simply a script that must be attached to a WorldEnvironment node
# to match the quality of the environment to the available VRAM memory
extends WorldEnvironment

# Name of the unique GameInstance variable for THIS environment
# It may or may not be created in GameInstance; if it is created, it will be used as a flag to uniquely configure an environment
# If it is not declared, the environment configuration process will be ignored
# If no value is assigned to this String variable, it means that the environment configuration will always be done.
# All of this will only be carried out if the set graphic profile is DEFAULT
# If a graphics profile is set manually, it will take precedence over the default profile defined by the graphics card.
@export var controlVar: String = ""

func _enter_tree() -> void : MyLogger.info(name + " Instantiated ... " , 'world_environment.gd',13,true)

func _ready() -> void :

	MyLogger.info(name + " Ready ... " , 'world_environment.gd',17,true)

	# -------------------------------------------------------------------------
	# BLOCK A: VIEWPORT AND GLOBAL DETECTION (Controlled within gpu_data)
	# -------------------------------------------------------------------------

	# In GameInstance we must have a structure like this:

	# Unified Data Structure for Hardware and Video Status
	# var gpu_data : Dictionary = {
	#	 "vp_detected": false,         # Checks if the Viewport/Hardware has already been processed
	#	 "vram": 512.0 / 1024.0,        # Secure default value in Gigabytes
	#	 "type": 0                      # Device Type (Dedicated, Integrated, etc.)
	# }

	# And a varible called graphicsProfile with the value ConfigRender.Profile.DEFAULT must be declared in GameInstance

	# If the ViewPort has not been previously configured, it is done now; otherwise, the configuration is omitted.
	if "gpu_data" in GameInstance and "vp_detected" in GameInstance.gpu_data and not GameInstance.gpu_data["vp_detected"] :
	
		# The Viewport is the window or region of the screen that is responsible for rendering and displaying your scene
		# The ViewPort configuration affects the last step of the rendering pipeline once we have the pixel mesh
		var vp = get_viewport()

		# ConfigRender is the static class where the configurations for each of the defined graphics profiles are carried out: Low, Medium, High, Ultra
		ConfigRender.apply_default_viewport_settings(vp)

	# -------------------------------------------------------------------------
	# BLOCK B: LOCAL ENVIRONMENT (Executed for each new map only once)
	# -------------------------------------------------------------------------

	if "graphicsProfile" in GameInstance and GameInstance.graphicsProfile != null : 

		# Because a message is being sent to be displayed on the screen, we must ensure that the HUD is ready to display it.
		await get_tree().process_frame

		if GameInstance.graphicsProfile == ConfigRender.Profile.DEFAULT :
	
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

		else :
		
			# If the native property does not exist, we leave
			if not environment: return

			# The environment is configured based on the assigned graphic profile
			match GameInstance.graphicsProfile :
				ConfigRender.Profile.LOW :
					ConfigRender.apply_graphics_profile(ConfigRender.Profile.LOW, null, environment)
					EventBus.emit(_ready, EventBus.EVENT.GraphicProfile_Changed, "LOW")
				ConfigRender.Profile.MEDIUM :
					ConfigRender.apply_graphics_profile(ConfigRender.Profile.MEDIUM, null, environment)
					EventBus.emit(_ready, EventBus.EVENT.GraphicProfile_Changed, "MEDIUM")
				ConfigRender.Profile.HIGH :
					ConfigRender.apply_graphics_profile(ConfigRender.Profile.HIGH, null, environment)
					EventBus.emit(_ready, EventBus.EVENT.GraphicProfile_Changed, "HIGH")
				ConfigRender.Profile.ULTRA :
					ConfigRender.apply_graphics_profile(ConfigRender.Profile.ULTRA, null, environment)
					EventBus.emit(_ready, EventBus.EVENT.GraphicProfile_Changed, "ULTRA")


func _configure_local_environment(gpu: Dictionary) -> void :

	# If the native property does not exist, we leave
	if not environment: return

	# Use this to avoid crashes if the dictionary is incomplete
	var vram: float = float(gpu.get("vram", 0.0))
	var type: int = int(gpu.get("type", RenderingDevice.DEVICE_TYPE_OTHER))

	# If the card is integrated or has less than 2.5 GB
	if (type == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU or vram <= 2.5) :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.LOW, null, environment)
		EventBus.emit(_configure_local_environment, EventBus.EVENT.GraphicProfile_Changed, "LOW")

	# If the card is dedicated with less than 4.5 GB
	elif (type != RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram <= 4.5) :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.MEDIUM, null, environment)
		EventBus.emit(_configure_local_environment, EventBus.EVENT.GraphicProfile_Changed, "MEDIUM")

	# if the card is dedicated with less than 8.5 GB
	elif (type != RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram <= 8.5) :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.HIGH, null, environment)
		EventBus.emit(_configure_local_environment, EventBus.EVENT.GraphicProfile_Changed, "HIGH")

	# if the card is dedicated with more than 8.5 GB
	else :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.ULTRA, null, environment)
		EventBus.emit(_configure_local_environment, EventBus.EVENT.GraphicProfile_Changed, "ULTRA")
