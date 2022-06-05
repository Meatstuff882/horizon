/obj/machinery/vending/tool
	name = "\improper YouTool"
	desc = "Tools for tools."
	icon_state = "tool"
	icon_deny = "tool-deny"
	light_mask = "tool-light-mask"
	products = list(/obj/item/stack/cable_coil = 10,
					/obj/item/crowbar = 5,
					/obj/item/weldingtool = 3,
					/obj/item/wirecutters = 5,
					/obj/item/wrench = 5,
					/obj/item/analyzer = 5,
					/obj/item/t_scanner = 5,
					/obj/item/screwdriver = 5,
					/obj/item/flashlight/glowstick = 3,
					/obj/item/flashlight/glowstick/red = 3,
					/obj/item/flashlight = 5,
					/obj/item/clothing/ears/earmuffs = 1,
					/obj/item/paint/anycolor = 2
					/obj/item/clothing/gloves/color/fyellow = 2,
					/obj/item/storage/belt/utility = 2,
					/obj/item/multitool = 2,
					/obj/item/weldingtool/hugetank = 2,
					/obj/item/clothing/head/welding = 2,
					/obj/item/clothing/gloves/color/yellow = 1)
	refill_canister = /obj/item/vending_refill/youtool
	default_price = 0
	extra_price = 0
	payment_department = ACCOUNT_ENG

/obj/item/vending_refill/youtool
	machine_name = "YouTool"
	icon_state = "refill_engi"
