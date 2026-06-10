# This code is simply a script that must be attached to a WorldEnvironment node
# to match the quality of the environment to the available VRAM memory
extends WorldEnvironment

# Name of the unique GameInstance variable for THIS environment
@export var controlVar: String = ""

func _init() -> void : pass

func _ready() -> void :

	if controlVar == "" : return

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

		# We save the hardware data directly in the structure
		# VRAM is saved in GB measure
		GameInstance.gpu_data["vram"] = _get_vram_real_mb() / 1024.0
		GameInstance.gpu_data["type"] = RenderingServer.get_video_adapter_type()
		
		# We configure the screen by passing the complete structure
		_configure_viewport_global(GameInstance.gpu_data)
		
		# We mark the Viewport as initialized directly in the structure
		GameInstance.gpu_data["vp_detectada"] = true

	# -------------------------------------------------------------------------
	# BLOCK B: LOCAL ENVIRONMENT (Executed for each new map only once)
	# -------------------------------------------------------------------------

	# The exported controlVar variable will have a variable name that will exist in GameInstance and will be assigned false as the default value
	var already_configured_env : bool = GameInstance.get(controlVar)
	
	# If this specific environment has already been processed in the past, we leave immediately
	if already_configured_env: return

	# We apply the local parameters by consuming the data of the structure without recalculating anything
	_configure_local_environment(GameInstance.gpu_data)
	
	# We mark this map as persistently configured in Autoload
	GameInstance.set(controlVar, true)




func _configure_viewport_global(gpu: Dictionary) -> void :

	# The Viewport is the window or region of the screen that is responsible for rendering and displaying your scene
	# The ViewPort configuration affects the last step of the rendering pipeline once we have the pixel mesh
	var vp = get_viewport()

	# We check if the Viewport has already been configured in the unified dictionary
	if not vp: return
	
	# Use this to avoid crashes if the dictionary is incomplete :
	var vram: float = float(gpu.get("vram", 0.0))
	var type: int = int(gpu.get("type", RenderingDevice.DEVICE_TYPE_OTHER))
	
	# If the card is integrated or has less than 2.5 GB
	if (type == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU or vram <= 2.5) :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.LOW, vp, null)

	# If the card is dedicated with less than 4.5 GB
	elif (type != RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram <=4.5) :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.MEDIUM, vp, null)

	# if the card is dedicated with less than 8.5 GB
	elif (type != RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram <= 8.5) :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.HIGH, vp, null)

	# if the card is dedicated with more than 8.5 GB
	else :
		ConfigRender.apply_graphics_profile(ConfigRender.Profile.ULTRA, vp, null)



func _configure_local_environment(gpu: Dictionary) -> void :

	# If the native property does not exist, we leave
	if not environment: return

	# We get the data from the gpu object
	var vram = gpu["vram"]
	var type = gpu["type"]

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



func _get_vram_real_mb() -> float :

	var os_name = OS.get_name()
	var output = []

	if os_name == "Windows" :

		# Runs PowerShell synchronously to detect which graphics card has the most memory
		OS.execute("powershell", [ "-Command", "(Get-ItemProperty -Path 'HKLM:/SYSTEM/ControlSet001/Control/Class/{4d36e968-e325-11ce-bfc1-08002be10318}/*' -ErrorAction SilentlyContinue | Where-Object { $_.'HardwareInformation.qwMemorySize' } | Sort-Object -Property 'HardwareInformation.qwMemorySize' -Descending | Select-Object -First 1).'HardwareInformation.qwMemorySize'" ], output)

		# Output is an array, the data comes in position 0
		if output.size() > 0 :
			if output[0].strip_edges().is_valid_int() :
				return output[0].strip_edges().to_int() / 1024.0 / 1024.0

	elif os_name == "Linux" :

		# 1. Try via nvidia-smi
		OS.execute("nvidia-smi", ["--query-gpu=memory.total", "--format=csv,noheader,nounits"], output)

		if output.size() > 0 :
			if output[0].strip_edges().is_valid_int() :
				return output[0].strip_edges().to_int()

		# CLEANUP: Empty the array in case nvidia-smi left error text,
		# avoiding dragging junk if you use 'output' further down in the script.
		output.clear()

		# 2. Try via sysfs (We look for the one with the most VRAM to avoid integrated)
		var max_vram_found = 0.0

		for card_index in ["card0", "card1", "card2"] :

			var vram_path = "/sys/class/drm/" + card_index + "/device/mem_info_vram_total"

			if FileAccess.file_exists(vram_path) :

				var file = FileAccess.open(vram_path, FileAccess.READ)

				if file :

					var bytes_text = file.get_as_text().strip_edges()
					file.close()

					if bytes_text.is_valid_int() :
						var vram_mb = bytes_text.to_int() / 1024.0 / 1024.0
						if vram_mb > max_vram_found : max_vram_found = vram_mb

		if max_vram_found > 0.0 : return max_vram_found

	# Default if all else fails or the platform is not supported (macOS, Android, Web, etc.)
	return 512.0
