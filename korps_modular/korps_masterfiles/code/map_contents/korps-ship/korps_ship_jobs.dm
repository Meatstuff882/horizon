/datum/job/korps_ship_captain
	title = "Commander"
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD|DEADMIN_POSITION_SECURITY
	department_head = list("Korps Institute")
	faction = FACTION_KORPS_SHIP
	total_positions = 1
	spawn_positions = 1
	supervisors = "the Korps’ upper management, and your crew"
	selection_color = "#ce68c8"
	req_admin_notify = 1
	minimal_player_age = 14
	exp_requirements = 180
	exp_granted_type = EXP_TYPE_CREW

	outfit = /datum/outfit/job/commander
	plasmaman_outfit = /datum/outfit/plasmaman/captain

	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_SEC

	display_order = JOB_DISPLAY_ORDER_CAPTAIN
	departments_list = list(
		/datum/job_department/command,
		)
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE

/datum/job/korps_ship_first_mate
	title = "First Mate"
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD
	head_announce = list(RADIO_CHANNEL_SUPPLY, RADIO_CHANNEL_SERVICE)
	department_head = list("Korps Institute")
	faction = FACTION_KORPS_SHIP
	total_positions = 1
	spawn_positions = 1
	supervisors = "the Commander, and the crew"
	selection_color = "#f2b2ee"
	req_admin_notify = 1
	minimal_player_age = 10
	exp_requirements = 180
	exp_granted_type = EXP_TYPE_CREW

	outfit = /datum/outfit/job/first_mate
	plasmaman_outfit = /datum/outfit/plasmaman/warden
	departments_list = list(
		/datum/job_department/command,
		)

	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_SRV
	bounty_types = CIV_JOB_RANDOM

	display_order = JOB_DISPLAY_ORDER_HEAD_OF_PERSONNEL
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE

/datum/job/korps_ship_engineer
	title = "Technician"
	department_head = list("Commander")
	faction = FACTION_KORPS_SHIP
	total_positions = 3
	spawn_positions = 3
	supervisors = "the First Mate, the Commander and the crew"
	selection_color = "#fff5cc"
	exp_requirements = 60
	exp_granted_type = EXP_TYPE_CREW

	outfit = /datum/outfit/job/technician
	plasmaman_outfit = /datum/outfit/plasmaman/engineering

	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_ENG

	display_order = JOB_DISPLAY_ORDER_STATION_ENGINEER
	bounty_types = CIV_JOB_ENG
	departments_list = list(
		/datum/job_department/engineering,
		)
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE

/datum/job/korps_ship_doctor
	title = "SciMed Doctor"
	department_head = list("Commander")
	faction = FACTION_KORPS_SHIP
	total_positions = 2
	spawn_positions = 2
	supervisors = "the First Mate, the Commander and the crew"
	selection_color = "#ffeef0"

	outfit = /datum/outfit/job/scimed_doctor
	plasmaman_outfit = /datum/outfit/plasmaman/medical

	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED

	display_order = JOB_DISPLAY_ORDER_MEDICAL_DOCTOR
	bounty_types = CIV_JOB_MED
	departments_list = list(
		/datum/job_department/medical,
		)
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE

/datum/job/korps_ship_researcher
	title = "SciMed Researcher"
	department_head = list("Commander")
	faction = FACTION_KORPS_SHIP
	total_positions = 2
	spawn_positions = 2
	supervisors = "the First Mate, the Commander and the crew"
	selection_color = "#ffeeff"
	exp_requirements = 60
	exp_granted_type = EXP_TYPE_CREW

	outfit = /datum/outfit/job/scimed_researcher
	plasmaman_outfit = /datum/outfit/plasmaman/science

	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_SCI

	display_order = JOB_DISPLAY_ORDER_SCIENTIST
	bounty_types = CIV_JOB_SCI
	departments_list = list(
		/datum/job_department/science,
		)
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE

/datum/job/korps_ship_deckhand
	title = "Deckhand"
	department_head = list("Commander")
	faction = FACTION_KORPS_SHIP
	total_positions = 3
	spawn_positions = 3
	supervisors = "the First Mate, the Commander and the crew"
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/deckhand
	plasmaman_outfit = /datum/outfit/plasmaman/cargo

	paycheck = PAYCHECK_EASY
	paycheck_department = ACCOUNT_CAR

	display_order = JOB_DISPLAY_ORDER_CARGO_TECHNICIAN
	bounty_types = CIV_JOB_RANDOM
	departments_list = list(
		/datum/job_department/cargo,
		)
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE

/datum/job/korps_ship_cook
	title = "Amenities Officer"
	department_head = list("Commander")
	faction = FACTION_KORPS_SHIP
	total_positions = 3
	spawn_positions = 3
	supervisors = "the First Mate, the Commander and the crew"
	selection_color = "#bbe291"

	outfit = /datum/outfit/job/amenities_officer
	plasmaman_outfit = /datum/outfit/plasmaman/chef

	paycheck = PAYCHECK_EASY
	paycheck_department = ACCOUNT_SRV

	display_order = JOB_DISPLAY_ORDER_COOK
	bounty_types = CIV_JOB_RANDOM
	departments_list = list(
		/datum/job_department/service,
		)
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE

/datum/job/korps_ship_operative
	title = "Operative"
	department_head = list("Commander")
	faction = FACTION_KORPS_SHIP
	total_positions = 10
	spawn_positions = 10
	supervisors = "the First Mate, the Commander and the crew"
	selection_color = "#dddddd"
	outfit = /datum/outfit/job/operative
	plasmaman_outfit = /datum/outfit/plasmaman
	paycheck = PAYCHECK_ASSISTANT

	paycheck_department = ACCOUNT_CIV
	display_order = JOB_DISPLAY_ORDER_ASSISTANT
	job_flags = JOB_NEW_PLAYER_JOINABLE | JOB_EQUIP_RANK

/datum/job/cyborg/korps_ship
	title = "Korps Cyborg"
	faction = FACTION_KORPS_SHIP
