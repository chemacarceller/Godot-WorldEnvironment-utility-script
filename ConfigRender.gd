extends RefCounted  

class_name ConfigRender

# We define an Enum to have control of the available profiles
enum Profile { LOW, MEDIUM, HIGH, ULTRA }

## Main method to apply a complete graphic profile
static func apply_graphics_profile(profile: Profile, vp: Viewport, environment: Environment) -> void:

	# Settings that apply to all profiles when passing the ViewPort
	if vp : 
		# Tells Godot to turn off the edge smoothing filter completely based on the final image of the screen
		# Disabled on all profiles because in no scenario does it offer a real advantage with the settings designed
		# It destroys the visual quality in powerful graphics and makes things worse on low-end screens in terms of performance
		# Screen-Space Anti-Aliasing : Configured as disabled -> Viewport.SCREEN_SPACE_AA_DISABLED,
		# Fast Approximate Anti-Aliasing -> Viewport.SCREEN_SPACE_AA_FXAA (light option) or
		# Subpixel Morphological Anti-Aliasing -> Viewport.SCREEN_SPACE_AA_SMAA (advanced option)
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

		# The VRS requires specific hardware support
		# Older or very low-end integrated circuits will suffer or give an error if you force it due to the hardware lack example Intel HD Graphics
		# If in medium, high and ultra mode with the current settings you can move it without problems it makes no sense to apply it
		# because the objective of this is to gain fps, it would be for environments que lo requieran
		vp.vrs_mode = Viewport.VRS_DISABLED

		# Antialiasing Temporal (TAA) - TAA is an edge smoothing technique that combines information from previous (past) frames with the current frame.
		vp.use_taa = false

	# Settings that apply to all profiles when passing the Environment
	if environment : 
		# We forget about RayTracing since until the minimum version 4.8 will not be available in the Godot editor
		# In version 4.7 it will be implemented internally but not usable from the Godot editor
		# It will be pending to rewrite the script when Hardware Ray Tracing is a reality in Godot
		# For the time being, SDGGI (Lumen in Unreal Engine) will be used and its study will be deepened

 		# Global Illumination by Signed Distance Fields (SDFGI)
		# SDFGI is an advanced 3D graphics technique used in Godot 4 to achieve real-time global illumination
		# It would be the equivalent of Lumen in Unreal
		environment.sdfgi_enabled = true

		# Screen Space Ambient Occlusion (SSAO)
		# SSAO is a post-processing effect that adds realistic shadows in corners, cracks, and points where objects intersect
		environment.ssao_enabled = true

		# Indirect Screen Space Lighting (SSIL)
		# SSIL (Screen-Space Indirect Lighting) is responsible for simulating how the colors of a surface are subtly reflected on a nearby one
		environment.ssil_enabled = true

		# Screen-Space Reflections (SSR)
		# SSR is a 3D graphics rendering technique used to generate dynamic, real-time reflections on shiny surfaces.
		environment.ssr_enabled = true

	match profile:
		Profile.LOW :
			if vp : _set_low_profile_vp(vp)
			if environment : _set_low_profile_env(environment)
		Profile.MEDIUM:
			if vp : _set_medium_profile_vp(vp)
			if environment : _set_medium_profile_env(environment)
		Profile.HIGH:
			if vp : _set_high_profile_vp(vp)
			if environment : _set_high_profile_env(environment)
		Profile.ULTRA:
			if vp : _set_ultra_profile_vp(vp)
			if environment : _set_ultra_profile_env(environment)



# --- INDIVIDUAL PROFILES (Private/Internal Methods) ---

static func _set_low_profile_vp(vp: Viewport) -> void :

	# Define the scaling and filtering algorithm that is applied to the 3D resolution when rendering at a size smaller or larger than the game window.
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	vp.scaling_3d_scale = 0.70
	vp.fsr_sharpness = 0.3

	# Controls the level of Multiple Sampling Anti-Aliasing (MSAA) applied exclusively to the 3D environment
	vp.msaa_3d = Viewport.MSAA_DISABLED

	# It tells the GPU how sharp or blurry the textures of objects should appear when they move away from the camera.
	vp.texture_mipmap_bias = 0.5

	# They control the size of the memory and the resolution that the GPU will allocate to calculate shadows in your game.
	vp.positional_shadow_atlas_size = 512
	RenderingServer.directional_shadow_atlas_set_size(1024, true)

	# Change the quality of the soft shadow filter for positional lights in real time
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)

	# Change the quality of the soft shadow filter for directional lights in real time
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)

	# Configure the Anisotropic Filtering level of textures globally in the engine.
	# In simple terms: it tells the GPU how sharp and detailed the textures of objects should look when viewed from a very steep angle or lying flat
	ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 4)
	
	# Optional: Save the change to the project.godot file
	ProjectSettings.save() 

	MyLogger.info("[ViewPort] Integrated or low VRAM ", "ConfigRender.gd", 102 , true)


static func _set_medium_profile_vp(vp: Viewport) -> void :

	# Scaling configuration...
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	vp.scaling_3d_scale = 0.85
	vp.fsr_sharpness = 0.15

	vp.msaa_3d = Viewport.MSAA_2X

	vp.texture_mipmap_bias = 0.2

	vp.positional_shadow_atlas_size = 1024
	RenderingServer.directional_shadow_atlas_set_size(1024, true)

	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)

	# [Godot 4.6] SSAO setting to Low Quality and half resolution (half_size = true)
	RenderingServer.environment_set_ssao_quality(
		RenderingServer.ENV_SSAO_QUALITY_LOW, # Quality
		true,                                 # half_size (Saves tons of FPS!)
		0.5,                                  # adaptive_target
		1,                                    # blur_passes (Fewer blur passes = faster)
		50.0,                                 # fadeout_from
		300.0                                 # fadeout_to
	)

	ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 8)
	
	# Optional: Save the change to the project.godot file
	ProjectSettings.save()

	MyLogger.info("[ViewPort] Medium (VRAM <= 4GB) ", "ConfigRender.gd", 137, true)


static func _set_high_profile_vp(vp: Viewport) -> void :

	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = 1.5

	vp.msaa_3d = Viewport.MSAA_2X

	vp.texture_mipmap_bias = 0.0

	vp.positional_shadow_atlas_size = 2048
	RenderingServer.directional_shadow_atlas_set_size(2048, true)

	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)

	# [Godot 4.6] Medium Quality for SSAO (Keep using half_size to balance performance)
	RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_MEDIUM, true, 0.5, 2, 50.0, 300.0)

	# [Godot 4.6] Medium Quality for SSIL (half_size = true)
	RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_MEDIUM, true, 0.5, 2, 50.0, 300.0)

	ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 16)
	
	# Optional: Save the change to the project.godot file
	ProjectSettings.save()

	MyLogger.info("[ViewPort] High (VRAM 6GB-8GB) ", "ConfigRender.gd", 166, true)


static func _set_ultra_profile_vp(vp: Viewport) -> void :

	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = 1.5

	vp.msaa_3d = Viewport.MSAA_4X

	vp.texture_mipmap_bias = 0.0

	vp.positional_shadow_atlas_size = 4096
	RenderingServer.directional_shadow_atlas_set_size(4096, true)

	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)

	# [Godot 4.6] Maximum Quality: We disable half_size (false) so that SSAO and SSIL
	# Rendered pixel by pixel at full native resolution. Absolute sharpness.
	RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_HIGH, false, 0.5, 3, 50.0, 300.0)
	RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_HIGH, false, 0.5, 3, 50.0, 300.0)

	ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 16)
	
	# Optional: Save the change to the project.godot file
	ProjectSettings.save() 
	
	MyLogger.info("[ViewPort] Full (VRAM > 8GB) ", "ConfigRender.gd", 194, true)



static func _set_low_profile_env(environment: Environment) -> void :

	# Disabling Global Illumination by Signed Distance Fields (SDFGI)
	environment.sdfgi_enabled = false

	# Disabling Screen Space Ambient Occlusion (SSAO)
	environment.ssao_enabled = false

	# Disabling Indirect Screen Space Lighting (SSIL)
	environment.ssil_enabled = false

	# Disabling Screen-Space Reflections (SSR)
	environment.ssr_enabled = false

	MyLogger.info("[Render] Integrated or low VRAM. SDFGI: OFF ", "ConfigRender.gd", 212, true)


static func _set_medium_profile_env(environment: Environment) -> void :

	# RTX 3050 Laptop/GTX 1650 (4GB)

	# Configuring Global Illumination by Signed Distance Fields (SDFGI)
	environment.sdfgi_cascades = 4
	environment.sdfgi_use_occlusion = false
	environment.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT

	# Disabling Indirect Screen Space Lighting (SSIL)
	environment.ssil_enabled = false

	# Configure and optimize Screen-Space Reflections (SSR)
	environment.ssr_max_steps = 64
	ProjectSettings.set_setting("rendering/reflections/screen_space_reflections/roughness_low_quality", true)
	environment.ssr_fade_out = 1.0

	# Optional: Save the change to the project.godot file
	ProjectSettings.save() 

	MyLogger.info("[Render] SDFGI Optimized (VRAM <= 4GB) ", "ConfigRender.gd", 235, true)


static func _set_high_profile_env(environment: Environment) -> void :

	# RTX 4060 / RX 6600 (8GB) - Balance

	# Configuring Global Illumination by Signed Distance Fields (SDFGI)
	environment.sdfgi_cascades = 4
	environment.sdfgi_use_occlusion = true
	environment.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_100_PERCENT

	# Configure and optimize Screen-Space Reflections (SSR) applied noly if enabled
	environment.ssr_max_steps = 128
	ProjectSettings.set_setting("rendering/reflections/screen_space_reflections/roughness_low_quality", false)
	environment.ssr_fade_out = 1.5
	
	# Optional: Save the change to the project.godot file
	ProjectSettings.save() 

	MyLogger.info("[Render] SDFGI High (VRAM 6GB-8GB) ", "ConfigRender.gd", 255, true)


static func _set_ultra_profile_env(environment: Environment) -> void :
	
	# GTX 1080 Ti / RTX 3060 12GB / RTX 4070+ (10GB+)
	
	# Configuring Global Illumination by Signed Distance Fields (SDFGI)
	environment.sdfgi_cascades = 6
	environment.sdfgi_use_occlusion = true
	environment.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_100_PERCENT

	# Configure and optimize Screen-Space Reflections (SSR) applied noly if enabled
	environment.ssr_max_steps = 256
	ProjectSettings.set_setting("rendering/reflections/screen_space_reflections/roughness_low_quality", false)
	environment.ssr_fade_out = 2.0
		
	# Optional: Save the change to the project.godot file
	ProjectSettings.save() 

	MyLogger.info("[Render] SDFGI Full (VRAM > 8GB) ", "ConfigRender.gd", 275, true)
