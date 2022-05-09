#define FACTION_KORPS_SHIP "KorpsShip"

/datum/map_config/korps_ship
	map_name = "KMV Chasse-Galerie"
	map_path = "map_files/korps_ship"
	map_file = list("korps_ship_z1.dmm",
					"korps_ship_z2.dmm",
					"korps_ship_z3.dmm",
					"korps_ship_z4.dmm")

	traits = list(list("Up" = 1),
					list("Up" = 1,
						"Down" = -1,
						"Baseturf" = "/turf/open/openspace"),
					list("Up" = 1,
						"Down" = -1,
						"Baseturf" = "/turf/open/openspace"),
					list("Down" = -1,
						"Baseturf" = "/turf/open/openspace"))
	space_ruin_levels = 3

	minetype = "none"

	global_trading_hub_type = /datum/trade_hub/worldwide/bearcat

	allow_custom_shuttles = TRUE

	job_faction = FACTION_KORPS_SHIP
	overflow_job = /datum/job/korps_ship_operative

	overmap_object_type = /datum/overmap_object/shuttle/ship/bearcat

	amount_of_planets_spawned = 2

/datum/map_config/korps_ship/get_map_info()
	return "You're aboard the <b>[map_name],</b> a survey and military vessel affiliated from the Korps Institute. \
	The ship serves as a routine patrol by the edges of the Institute’s influence spheres, ever aware of SolGov’s presence in nearby systems."
