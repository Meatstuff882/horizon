/*
 * Vending machine types - Can be found under /code/modules/vending/
 */

/*

/obj/machinery/vending/[vendors name here]   // --vending machine template   :)
	name = ""
	desc = ""
	icon = ''
	icon_state = ""
	products = list()
	contraband = list()
	premium = list()

IF YOU MODIFY THE PRODUCTS LIST OF A MACHINE, MAKE SURE TO UPDATE ITS RESUPPLY CANISTER CHARGES in vending_items.dm
*/

#define MAX_VENDING_INPUT_AMOUNT 30
/**
 * # vending record datum
 *
 * A datum that represents a product that is vendable
 */
/datum/data/vending_product
	name = "generic"
	///Typepath of the product that is created when this record "sells"
	var/product_path = null
	///How many of this product we currently have
	var/amount = 0
	///How many we can store at maximum
	var/max_amount = 0
	///Does the item have a custom price override
	var/custom_price
	///Does the item have a custom premium price override
	var/custom_premium_price
	///Whether spessmen with an ID with an age below AGE_MINOR (20 by default) can buy this item
	var/age_restricted = FALSE

/**
 * # vending machines
 *
 * Captalism in the year 2525, everything in a vending machine, even love
 */
/obj/machinery/vending
	name = "\improper Vendomat"
	desc = "A generic vending machine."
	icon = 'icons/obj/vending.dmi'
	icon_state = "generic"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	verb_say = "beeps"
	verb_ask = "beeps"
	verb_exclaim = "beeps"
	max_integrity = 300
	integrity_failure = 0.33
	armor = list(MELEE = 20, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 70)
	circuit = /obj/item/circuitboard/machine/vendor
	payment_department = ACCOUNT_SRV
	light_power = 0.5
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	/// Is the machine active (No sales pitches if off)!
	var/active = 1
	///Are we ready to vend?? Is it time??
	var/vend_ready = TRUE
	///Next world time to send a purchase message
	var/purchase_message_cooldown
	///The ref of the last mob to shop with us
	var/last_shopper
	var/tilted = FALSE
	var/tiltable = TRUE
	var/squish_damage = 75
	var/forcecrit = 0
	var/num_shards = 7
	var/list/pinned_mobs = list()

	/**
	  * List of products this machine sells
	  *
	  * form should be list(/type/path = amount, /type/path2 = amount2)
	  */
	var/list/products = list()

	/**
	  * List of products this machine sells when you hack it
	  *
	  * form should be list(/type/path = amount, /type/path2 = amount2)
	  */
	var/list/contraband = list()

	/**
	  * List of premium products this machine sells
	  *
	  * form should be list(/type/path, /type/path2) as there is only ever one in stock
	  */
	var/list/premium = list()

	///String of slogans separated by semicolons, optional
	var/product_slogans = ""
	///String of small ad messages in the vending screen - random chance
	var/product_ads = ""

	var/list/product_records = list()
	var/list/hidden_records = list()
	var/list/coin_records = list()
	var/list/slogan_list = list()
	///Small ad messages in the vending screen - random chance of popping up whenever you open it
	var/list/small_ads = list()
	///Message sent post vend (Thank you for shopping!)
	var/vend_reply
	///Last world tick we sent a vent reply
	var/last_reply = 0
	///Last world tick we sent a slogan message out
	var/last_slogan = 0
	///How many ticks until we can send another
	var/slogan_delay = 6000
	///Icon when vending an item to the user
	var/icon_vend
	///Icon to flash when user is denied a vend
	var/icon_deny
	///World ticks the machine is electified for
	var/seconds_electrified = MACHINE_NOT_ELECTRIFIED
	///When this is TRUE, we fire items at customers! We're broken!
	var/shoot_inventory = 0
	///How likely this is to happen (prob 100) per second
	var/shoot_inventory_chance = 1
	//Stop spouting those godawful pitches!
	var/shut_up = 0
	///can we access the hidden inventory?
	var/extended_inventory = 0
	///Are we checking the users ID
	var/scan_id = 1
	///Coins that we accept?
	var/obj/item/coin/coin
	///Bills we accept?
	var/obj/item/stack/spacecash/bill
	///Default price of items if not overridden
	var/default_price = 25
	///Default price of premium items if not overridden
	var/extra_price = 50
	///Whether our age check is currently functional
	var/age_restrictions = TRUE
	/**
	  * Is this item on station or not
	  *
	  * if it doesn't originate from off-station during mapload, everything is free
	  */
	var/onstation = TRUE //if it doesn't originate from off-station during mapload, everything is free
	///A variable to change on a per instance basis on the map that allows the instance to force cost and ID requirements
	var/onstation_override = FALSE //change this on the object on the map to override the onstation check. DO NOT APPLY THIS GLOBALLY.

	///ID's that can load this vending machine wtih refills
	var/list/canload_access_list


	var/list/vending_machine_input = list()
	///Display header on the input view
	var/input_display_header = "Custom Vendor"

	//The type of refill canisters used by this machine.
	var/obj/item/vending_refill/refill_canister = null

	/// how many items have been inserted in a vendor
	var/loaded_items = 0

	///Name of lighting mask for the vending machine
	var/light_mask

	/// used for narcing on underages
	var/obj/item/radio/Radio


/**
 * Initialize the vending machine
 *
 * Builds the vending machine inventory, sets up slogans and other such misc work
 *
 * This also sets the onstation var to:
 * * FALSE - if the machine was maploaded on a zlevel that doesn't pass the is_station_level check
 * * TRUE - all other cases
 */
/obj/machinery/vending/Initialize(mapload)
	var/build_inv = FALSE
	if(!refill_canister)
		circuit = null
		build_inv = TRUE
	. = ..()
	wires = new /datum/wires/vending(src)
	if(build_inv) //non-constructable vending machine
		build_inventory(products, product_records)
		build_inventory(contraband, hidden_records)
		build_inventory(premium, coin_records)

	slogan_list = splittext(product_slogans, ";")
	// So not all machines speak at the exact same time.
	// The first time this machine says something will be at slogantime + this random value,
	// so if slogantime is 10 minutes, it will say it at somewhere between 10 and 20 minutes after the machine is crated.
	last_slogan = world.time + rand(0, slogan_delay)
	power_change()

	if(onstation_override) //overrides the checks if true.
		onstation = TRUE
		return
	if(mapload) //check if it was initially created off station during mapload.
		if(!is_station_level(src))
			onstation = FALSE
			if(circuit)
				circuit.onstation = onstation //sync up the circuit so the pricing schema is carried over if it's reconstructed.
	else if(circuit && (circuit.onstation != onstation)) //check if they're not the same to minimize the amount of edited values.
		onstation = circuit.onstation //if it was constructed outside mapload, sync the vendor up with the circuit's var so you can't bypass price requirements by moving / reconstructing it off station.
	Radio = new /obj/item/radio(src)
	Radio.listening = 0

/obj/machinery/vending/Destroy()
	QDEL_NULL(wires)
	QDEL_NULL(coin)
	QDEL_NULL(bill)
	QDEL_NULL(Radio)
	return ..()

/obj/machinery/vending/can_speak()
	return !shut_up

/obj/machinery/vending/RefreshParts()         //Better would be to make constructable child
	if(!component_parts)
		return

	product_records = list()
	hidden_records = list()
	coin_records = list()
	build_inventory(products, product_records, start_empty = TRUE)
	build_inventory(contraband, hidden_records, start_empty = TRUE)
	build_inventory(premium, coin_records, start_empty = TRUE)
	for(var/obj/item/vending_refill/VR in component_parts)
		restock(VR)

/obj/machinery/vending/deconstruct(disassembled = TRUE)
	if(!refill_canister) //the non constructable vendors drop metal instead of a machine frame.
		if(!(flags_1 & NODECONSTRUCT_1))
			new /obj/item/stack/sheet/iron(loc, 3)
		qdel(src)
	else
		..()

/obj/machinery/vending/update_appearance(updates=ALL)
	. = ..()
	if(machine_stat & BROKEN)
		set_light(0)
		return
	set_light(powered() ? MINIMUM_USEFUL_LIGHT_RANGE : 0)


/obj/machinery/vending/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
		return ..()
	icon_state = "[initial(icon_state)][powered() ? null : "-off"]"
	return ..()


/obj/machinery/vending/update_overlays()
	. = ..()
	if(!light_mask)
		return
	if(!(machine_stat & BROKEN) && powered())
		. += emissive_appearance(icon, light_mask)

/obj/machinery/vending/obj_break(damage_flag)
	. = ..()
	if(!.)
		return

	var/dump_amount = 0
	var/found_anything = TRUE
	while (found_anything)
		found_anything = FALSE
		for(var/record in shuffle(product_records))
			var/datum/data/vending_product/R = record
			if(R.amount <= 0) //Try to use a record that actually has something to dump.
				continue
			var/dump_path = R.product_path
			if(!dump_path)
				continue
			R.amount--
			// busting open a vendor will destroy some of the contents
			if(found_anything && prob(80))
				continue

			var/obj/O = new dump_path(loc)
			step(O, pick(GLOB.alldirs))
			found_anything = TRUE
			dump_amount++
			if (dump_amount >= 16)
				return

GLOBAL_LIST_EMPTY(vending_products)
/**
 * Build the inventory of the vending machine from it's product and record lists
 *
 * This builds up a full set of /datum/data/vending_products from the product list of the vending machine type
 * Arguments:
 * * productlist - the list of products that need to be converted
 * * recordlist - the list containing /datum/data/vending_product datums
 * * startempty - should we set vending_product record amount from the product list (so it's prefilled at roundstart)
 */
/obj/machinery/vending/proc/build_inventory(list/productlist, list/recordlist, start_empty = FALSE)
	default_price = round(initial(default_price) * SSeconomy.inflation_value())
	extra_price = round(initial(extra_price) * SSeconomy.inflation_value())
	for(var/typepath in productlist)
		var/amount = productlist[typepath]
		if(isnull(amount))
			amount = 0

		var/atom/temp = typepath
		var/datum/data/vending_product/R = new /datum/data/vending_product()
		GLOB.vending_products[typepath] = 1
		R.name = initial(temp.name)
		R.product_path = typepath
		if(!start_empty)
			R.amount = amount
		R.max_amount = amount
		///Prices of vending machines are all increased uniformly.
		R.custom_price = round(initial(temp.custom_price) * SSeconomy.inflation_value())
		R.custom_premium_price = round(initial(temp.custom_premium_price) * SSeconomy.inflation_value())
		R.age_restricted = initial(temp.age_restricted)
		recordlist += R

/**
 * Reassign the prices of the vending machine as a result of the inflation value, as provided by SSeconomy
 *
 * This rebuilds both /datum/data/vending_products lists for premium and standard products based on their most relevant pricing values.
 * Arguments:
 * * recordlist - the list of standard product datums in the vendor to refresh their prices.
 * * premiumlist - the list of premium product datums in the vendor to refresh their prices.
 */
/obj/machinery/vending/proc/reset_prices(list/recordlist, list/premiumlist)
	default_price = round(initial(default_price) * SSeconomy.inflation_value())
	extra_price = round(initial(extra_price) * SSeconomy.inflation_value())
	for(var/R in recordlist)
		var/datum/data/vending_product/record = R
		var/atom/potential_product = record.product_path
		record.custom_price = round(initial(potential_product.custom_price) * SSeconomy.inflation_value())
	for(var/R in premiumlist)
		var/datum/data/vending_product/record = R
		var/atom/potential_product = record.product_path
		var/premium_sanity = round(initial(potential_product.custom_premium_price))
		if(premium_sanity)
			record.custom_premium_price = round(premium_sanity * SSeconomy.inflation_value())
			continue
		//For some ungodly reason, some premium only items only have a custom_price
		record.custom_premium_price = round(extra_price + (initial(potential_product.custom_price) * (SSeconomy.inflation_value() - 1)))

/**
 * Refill a vending machine from a refill canister
 *
 * This takes the products from the refill canister and then fills the products,contraband and premium product categories
 *
 * Arguments:
 * * canister - the vending canister we are refilling from
 */
/obj/machinery/vending/proc/restock(obj/item/vending_refill/canister)
	if (!canister.products)
		canister.products = products.Copy()
	if (!canister.contraband)
		canister.contraband = contraband.Copy()
	if (!canister.premium)
		canister.premium = premium.Copy()
	. = 0
	. += refill_inventory(canister.products, product_records)
	. += refill_inventory(canister.contraband, hidden_records)
	. += refill_inventory(canister.premium, coin_records)
/**
 * Refill our inventory from the passed in product list into the record list
 *
 * Arguments:
 * * productlist - list of types -> amount
 * * recordlist - existing record datums
 */
/obj/machinery/vending/proc/refill_inventory(list/productlist, list/recordlist)
	. = 0
	for(var/R in recordlist)
		var/datum/data/vending_product/record = R
		var/diff = min(record.max_amount - record.amount, productlist[record.product_path])
		if (diff)
			productlist[record.product_path] -= diff
			record.amount += diff
			. += diff
/**
 * Set up a refill canister that matches this machines products
 *
 * This is used when the machine is deconstructed, so the items aren't "lost"
 */
/obj/machinery/vending/proc/update_canister()
	if (!component_parts)
		return

	var/obj/item/vending_refill/R = locate() in component_parts
	if (!R)
		CRASH("Constructible vending machine did not have a refill canister")

	R.products = unbuild_inventory(product_records)
	R.contraband = unbuild_inventory(hidden_records)
	R.premium = unbuild_inventory(coin_records)

/**
 * Given a record list, go through and and return a list of type -> amount
 */
/obj/machinery/vending/proc/unbuild_inventory(list/recordlist)
	. = list()
	for(var/R in recordlist)
		var/datum/data/vending_product/record = R
		.[record.product_path] += record.amount

/obj/machinery/vending/crowbar_act(mob/living/user, obj/item/I)
	if(!component_parts)
		return FALSE
	default_deconstruction_crowbar(I)
	return TRUE

/obj/machinery/vending/wrench_act(mob/living/user, obj/item/I)
	..()
	if(panel_open)
		default_unfasten_wrench(user, I, time = 60)
		unbuckle_all_mobs(TRUE)
	return TRUE

/obj/machinery/vending/screwdriver_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE
	if(anchored)
		default_deconstruction_screwdriver(user, icon_state, icon_state, I)
		cut_overlays()
		if(panel_open)
			add_overlay("[initial(icon_state)]-panel")
		updateUsrDialog()
	else
		to_chat(user, SPAN_WARNING("You must first secure [src]."))
	return TRUE

/obj/machinery/vending/attackby(obj/item/I, mob/living/user, params)
	if(panel_open && is_wire_tool(I))
		wires.interact(user)
		return

	if(refill_canister && istype(I, refill_canister))
		if (!panel_open)
			to_chat(user, SPAN_WARNING("You should probably unscrew the service panel first!"))
		else if (machine_stat & (BROKEN|NOPOWER))
			to_chat(user, SPAN_NOTICE("[src] does not respond."))
		else
			//if the panel is open we attempt to refill the machine
			var/obj/item/vending_refill/canister = I
			if(canister.get_part_rating() == 0)
				to_chat(user, SPAN_WARNING("[canister] is empty!"))
			else
				// instantiate canister if needed
				var/transferred = restock(canister)
				if(transferred)
					to_chat(user, SPAN_NOTICE("You loaded [transferred] items in [src]."))
				else
					to_chat(user, SPAN_WARNING("There's nothing to restock!"))
			return
	if(compartmentLoadAccessCheck(user) && !user.combat_mode)
		if(canLoadItem(I))
			loadingAttempt(I,user)
			updateUsrDialog() //can't put this on the proc above because we spam it below

		if(istype(I, /obj/item/storage/bag)) //trays USUALLY
			var/obj/item/storage/T = I
			var/loaded = 0
			var/denied_items = 0
			for(var/obj/item/the_item in T.contents)
				if(contents.len >= MAX_VENDING_INPUT_AMOUNT) // no more than 30 item can fit inside, legacy from snack vending although not sure why it exists
					to_chat(user, SPAN_WARNING("[src]'s compartment is full."))
					break
				if(canLoadItem(the_item) && loadingAttempt(the_item,user))
					SEND_SIGNAL(T, COMSIG_TRY_STORAGE_TAKE, the_item, src, TRUE)
					loaded++
				else
					denied_items++
			if(denied_items)
				to_chat(user, SPAN_WARNING("[src] refuses some items!"))
			if(loaded)
				to_chat(user, SPAN_NOTICE("You insert [loaded] dishes into [src]'s compartment."))
				updateUsrDialog()
	else
		. = ..()
		if(tiltable && !tilted && I.force)
			switch(rand(1, 100))
				if(1 to 5)
					freebie(user, 3)
				if(6 to 15)
					freebie(user, 2)
				if(16 to 25)
					freebie(user, 1)
				if(76 to 90)
					tilt(user)
				if(91 to 100)
					tilt(user, crit=TRUE)

/obj/machinery/vending/proc/freebie(mob/fatty, freebies)
	visible_message(SPAN_NOTICE("[src] yields [freebies > 1 ? "several free goodies" : "a free goody"]!"))

	for(var/i in 1 to freebies)
		playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
		for(var/datum/data/vending_product/R in shuffle(product_records))

			if(R.amount <= 0) //Try to use a record that actually has something to dump.
				continue
			var/dump_path = R.product_path
			if(!dump_path)
				continue

			R.amount--
			new dump_path(get_turf(src))
			break

///Tilts ontop of the atom supplied, if crit is true some extra shit can happen. Returns TRUE if it dealt damage to something.
/obj/machinery/vending/proc/tilt(atom/fatty, crit=FALSE)
	visible_message(SPAN_DANGER("[src] tips over!"))
	tilted = TRUE
	layer = ABOVE_MOB_LAYER

	var/crit_case
	if(crit)
		crit_case = rand(1,6)

	if(forcecrit)
		crit_case = forcecrit

	. = FALSE

	if(in_range(fatty, src))
		for(var/mob/living/L in get_turf(fatty))
			var/was_alive = (L.stat != DEAD)
			var/mob/living/carbon/C = L

			SEND_SIGNAL(L, COMSIG_ON_VENDOR_CRUSH)

			if(istype(C))
				var/crit_rebate = 0 // lessen the normal damage we deal for some of the crits

				if(crit_case < 5) // the body/head asplode case has its own description
					C.visible_message(SPAN_DANGER("[C] is crushed by [src]!"), \
						SPAN_USERDANGER("You are crushed by [src]!"))

				switch(crit_case) // only carbons can have the fun crits
					if(1) // shatter their legs and bleed 'em
						crit_rebate = 60
						C.bleed(150)
						var/obj/item/bodypart/l_leg/l = C.get_bodypart(BODY_ZONE_L_LEG)
						if(l)
							l.receive_damage(brute=200)
						var/obj/item/bodypart/r_leg/r = C.get_bodypart(BODY_ZONE_R_LEG)
						if(r)
							r.receive_damage(brute=200)
						if(l || r)
							C.visible_message(SPAN_DANGER("[C]'s legs shatter with a sickening crunch!"), \
								SPAN_USERDANGER("Your legs shatter with a sickening crunch!"))
					if(2) // pin them beneath the machine until someone untilts it
						forceMove(get_turf(C))
						buckle_mob(C, force=TRUE)
						C.visible_message(SPAN_DANGER("[C] is pinned underneath [src]!"), \
							SPAN_USERDANGER("You are pinned down by [src]!"))
					if(3) // glass candy
						crit_rebate = 50
						for(var/i = 0, i < num_shards, i++)
							var/obj/item/shard/shard = new /obj/item/shard(get_turf(C))
							shard.embedding = list(embed_chance = 100, ignore_throwspeed_threshold = TRUE, impact_pain_mult=1, pain_chance=5)
							shard.updateEmbedding()
							C.hitby(shard, skipcatch = TRUE, hitpush = FALSE)
							shard.embedding = list()
							shard.updateEmbedding()
					if(4) // paralyze this binch
						// the new paraplegic gets like 4 lines of losing their legs so skip them
						visible_message(SPAN_DANGER("[C]'s spinal cord is obliterated with a sickening crunch!"), ignored_mobs = list(C))
						C.gain_trauma(/datum/brain_trauma/severe/paralysis/paraplegic)
					if(5) // limb squish!
						for(var/i in C.bodyparts)
							var/obj/item/bodypart/squish_part = i
							if(squish_part.is_organic_limb())
								var/type_wound = pick(list(/datum/wound/blunt/critical, /datum/wound/blunt/severe, /datum/wound/blunt/moderate))
								squish_part.force_wound_upwards(type_wound)
							else
								squish_part.receive_damage(brute=30)
						C.visible_message(SPAN_DANGER("[C]'s body is maimed underneath the mass of [src]!"), \
							SPAN_USERDANGER("Your body is maimed underneath the mass of [src]!"))
					if(6) // skull squish!
						var/obj/item/bodypart/head/O = C.get_bodypart(BODY_ZONE_HEAD)
						if(O)
							C.visible_message(SPAN_DANGER("[O] explodes in a shower of gore beneath [src]!"), \
								SPAN_USERDANGER("Oh f-"))
							O.dismember()
							O.drop_organs()
							qdel(O)
							new /obj/effect/gibspawner/human/bodypartless(get_turf(C))

				if(prob(30))
					C.apply_damage(max(0, squish_damage - crit_rebate), forced=TRUE, spread_damage=TRUE) // the 30% chance to spread the damage means you escape breaking any bones
				else
					C.take_bodypart_damage((squish_damage - crit_rebate)*0.5, wound_bonus = 5) // otherwise, deal it to 2 random limbs (or the same one) which will likely shatter something
					C.take_bodypart_damage((squish_damage - crit_rebate)*0.5, wound_bonus = 5)
				C.AddElement(/datum/element/squish, 80 SECONDS)
			else
				L.visible_message(SPAN_DANGER("[L] is crushed by [src]!"), \
				SPAN_USERDANGER("You are crushed by [src]!"))
				L.apply_damage(squish_damage, forced=TRUE)
				if(crit_case)
					L.apply_damage(squish_damage, forced=TRUE)
			if(was_alive && L.stat == DEAD && L.client)
				L.client.give_award(/datum/award/achievement/misc/vendor_squish, L) // good job losing a fight with an inanimate object idiot

			L.Paralyze(60)
			L.emote("scream")
			. = TRUE
			playsound(L, 'sound/effects/blobattack.ogg', 40, TRUE)
			playsound(L, 'sound/effects/splat.ogg', 50, TRUE)

	var/matrix/M = matrix()
	M.Turn(pick(90, 270))
	transform = M

	if(get_turf(fatty) != get_turf(src))
		throw_at(get_turf(fatty), 1, 1, spin=FALSE, quickstart=FALSE)

/obj/machinery/vending/proc/untilt(mob/user)
	if(user)
		user.visible_message(SPAN_NOTICE("[user] rights [src]."), \
			SPAN_NOTICE("You right [src]."))

	unbuckle_all_mobs(TRUE)

	tilted = FALSE
	layer = initial(layer)

	var/matrix/M = matrix()
	M.Turn(0)
	transform = M

/obj/machinery/vending/proc/loadingAttempt(obj/item/I, mob/user)
	. = TRUE
	if(!user.transferItemToLoc(I, src))
		return FALSE
	if(vending_machine_input[format_text(I.name)])
		vending_machine_input[format_text(I.name)]++
	else
		vending_machine_input[format_text(I.name)] = 1
	to_chat(user, SPAN_NOTICE("You insert [I] into [src]'s input compartment."))
	loaded_items++

/obj/machinery/vending/unbuckle_mob(mob/living/buckled_mob, force=FALSE)
	if(!force)
		return
	. = ..()

/**
 * Is the passed in user allowed to load this vending machines compartments
 *
 * Arguments:
 * * user - mob that is doing the loading of the vending machine
 */
/obj/machinery/vending/proc/compartmentLoadAccessCheck(mob/user)
	if(!canload_access_list)
		return TRUE
	else
		var/do_you_have_access = FALSE
		var/req_access_txt_holder = req_access_txt
		for(var/i in canload_access_list)
			req_access_txt = i
			if(!allowed(user) && !(obj_flags & EMAGGED) && scan_id)
				continue
			else
				do_you_have_access = TRUE
				break //you passed don't bother looping anymore
		req_access_txt = req_access_txt_holder // revert to normal (before the proc ran)
		if(do_you_have_access)
			return TRUE
		else
			to_chat(user, SPAN_WARNING("[src]'s input compartment blinks red: Access denied."))
			return FALSE

/obj/machinery/vending/exchange_parts(mob/user, obj/item/storage/part_replacer/W)
	if(!istype(W))
		return FALSE
	if((flags_1 & NODECONSTRUCT_1) && !W.works_from_distance)
		return FALSE
	if(!component_parts || !refill_canister)
		return FALSE

	var/moved = 0
	if(panel_open || W.works_from_distance)
		if(W.works_from_distance)
			display_parts(user)
		for(var/I in W)
			if(istype(I, refill_canister))
				moved += restock(I)
	else
		display_parts(user)
	if(moved)
		to_chat(user, SPAN_NOTICE("[moved] items restocked."))
		W.play_rped_sound()
	return TRUE

/obj/machinery/vending/on_deconstruction()
	update_canister()
	. = ..()

/obj/machinery/vending/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	to_chat(user, SPAN_NOTICE("You short out the product lock on [src]."))

/obj/machinery/vending/_try_interact(mob/user)
	if(seconds_electrified && !(machine_stat & NOPOWER))
		if(shock(user, 100))
			return

	if(tilted && !user.buckled && !isAI(user))
		to_chat(user, SPAN_NOTICE("You begin righting [src]."))
		if(do_after(user, 50, target=src))
			untilt(user)
		return

	return ..()

/obj/machinery/vending/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/vending),
	)

/obj/machinery/vending/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Vending")
		ui.open()

/obj/machinery/vending/ui_static_data(mob/user)
	. = list()
	.["onstation"] = onstation
	.["department"] = payment_department
	.["jobDiscount"] = VENDING_DISCOUNT
	.["product_records"] = list()
	for (var/datum/data/vending_product/R in product_records)
		var/list/data = list(
			path = replacetext(replacetext("[R.product_path]", "/obj/item/", ""), "/", "-"),
			name = R.name,
			price = R.custom_price || default_price,
			max_amount = R.max_amount,
			ref = REF(R)
		)
		.["product_records"] += list(data)
	.["coin_records"] = list()
	for (var/datum/data/vending_product/R in coin_records)
		var/list/data = list(
			path = replacetext(replacetext("[R.product_path]", "/obj/item/", ""), "/", "-"),
			name = R.name,
			price = R.custom_premium_price || extra_price,
			max_amount = R.max_amount,
			ref = REF(R),
			premium = TRUE
		)
		.["coin_records"] += list(data)
	.["hidden_records"] = list()
	for (var/datum/data/vending_product/R in hidden_records)
		var/list/data = list(
			path = replacetext(replacetext("[R.product_path]", "/obj/item/", ""), "/", "-"),
			name = R.name,
			price = R.custom_premium_price || extra_price,
			max_amount = R.max_amount,
			ref = REF(R),
			premium = TRUE
		)
		.["hidden_records"] += list(data)

/obj/machinery/vending/ui_data(mob/user)
	. = list()
	var/obj/item/card/id/C
	if(isliving(user))
		var/mob/living/L = user
		C = L.get_idcard(TRUE)
	if(C?.registered_account)
		.["user"] = list()
		.["user"]["name"] = C.registered_account.account_holder
		.["user"]["cash"] = C.registered_account.account_balance
		if(C.registered_account.account_job)
			.["user"]["job"] = C.registered_account.account_job.title
			.["user"]["department"] = C.registered_account.account_job.paycheck_department
		else
			.["user"]["job"] = "No Job"
			.["user"]["department"] = "No Department"
	.["stock"] = list()
	for (var/datum/data/vending_product/R in product_records + coin_records + hidden_records)
		var/list/product_data = list(
			name = R.name,
			amount = R.amount,
		)
		.["stock"][R.name] = product_data
	.["extended_inventory"] = extended_inventory

/obj/machinery/vending/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("vend")
			. = vend(params)

/obj/machinery/vending/proc/can_vend(user, silent=FALSE)
	. = FALSE
	if(!vend_ready)
		return
	if(panel_open)
		to_chat(user, SPAN_WARNING("The vending machine cannot dispense products while its service panel is open!"))
		return
	return TRUE

/obj/machinery/vending/proc/vend(list/params, list/greyscale_colors)
	. = TRUE
	if(!can_vend(usr))
		return
	vend_ready = FALSE //One thing at a time!!
	var/datum/data/vending_product/R = locate(params["ref"])
	var/list/record_to_check = product_records + coin_records
	if(extended_inventory)
		record_to_check = product_records + coin_records + hidden_records
	if(!R || !istype(R) || !R.product_path)
		vend_ready = TRUE
		return
	var/price_to_use = default_price
	if(R.custom_price)
		price_to_use = R.custom_price
	if(R in hidden_records)
		if(!extended_inventory)
			vend_ready = TRUE
			return
	else if (!(R in record_to_check))
		vend_ready = TRUE
		message_admins("Vending machine exploit attempted by [ADMIN_LOOKUPFLW(usr)]!")
		return
	if (R.amount <= 0)
		say("Sold out of [R.name].")
		flick(icon_deny,src)
		vend_ready = TRUE
		return
	if(onstation)
		var/obj/item/card/id/C
		if(isliving(usr))
			var/mob/living/L = usr
			C = L.get_idcard(TRUE)
		if(!C)
			say("No card found.")
			flick(icon_deny,src)
			vend_ready = TRUE
			return
		else if (!C.registered_account)
			say("No account found.")
			flick(icon_deny,src)
			vend_ready = TRUE
			return
		else if(!C.registered_account.account_job)
			say("Departmental accounts have been blacklisted from personal expenses due to embezzlement.")
			flick(icon_deny, src)
			vend_ready = TRUE
			return
		else if(age_restrictions && R.age_restricted && (!C.registered_age || C.registered_age < AGE_MINOR))
			say("You are not of legal age to purchase [R.name].")
			if(!(usr in GLOB.narcd_underages))
				Radio.set_frequency(FREQ_SECURITY)
				Radio.talk_into(src, "SECURITY ALERT: Underaged crewmember [usr] recorded attempting to purchase [R.name] in [get_area(src)]. Please watch for substance abuse.", FREQ_SECURITY)
				GLOB.narcd_underages += usr
			flick(icon_deny,src)
			vend_ready = TRUE
			return
		var/datum/bank_account/account = C.registered_account
		if(account.account_job && account.account_job.paycheck_department == payment_department)
			price_to_use = max(round(price_to_use * VENDING_DISCOUNT), 1) //No longer free, but signifigantly cheaper.
		if(coin_records.Find(R) || hidden_records.Find(R))
			price_to_use = R.custom_premium_price ? R.custom_premium_price : extra_price
		if(price_to_use && !account.adjust_money(-price_to_use))
			say("You do not possess the funds to purchase [R.name].")
			flick(icon_deny,src)
			vend_ready = TRUE
			return
		var/datum/bank_account/D = SSeconomy.get_dep_account(payment_department)
		if(D)
			D.adjust_money(price_to_use)
			SSblackbox.record_feedback("amount", "vending_spent", price_to_use)
			log_econ("[price_to_use] credits were inserted into [src] by [D.account_holder] to buy [R].")
	if(last_shopper != REF(usr) || purchase_message_cooldown < world.time)
		say("Thank you for shopping with [src]!")
		purchase_message_cooldown = world.time + 5 SECONDS
		//This is not the best practice, but it's safe enough here since the chances of two people using a machine with the same ref in 5 seconds is fuck low
		last_shopper = REF(usr)
	use_power(5)
	if(icon_vend) //Show the vending animation if needed
		flick(icon_vend,src)
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	var/obj/item/vended_item = new R.product_path(get_turf(src))
	R.amount--
	if(usr.CanReach(src) && usr.put_in_hands(vended_item))
		to_chat(usr, SPAN_NOTICE("You take [R.name] out of the slot."))
	else
		to_chat(usr, SPAN_WARNING("[capitalize(R.name)] falls onto the floor!"))
	SSblackbox.record_feedback("nested tally", "vending_machine_usage", 1, list("[type]", "[R.product_path]"))
	vend_ready = TRUE

/obj/machinery/vending/process(delta_time)
	if(machine_stat & (BROKEN|NOPOWER))
		return PROCESS_KILL
	if(!active)
		return

	if(seconds_electrified > MACHINE_NOT_ELECTRIFIED)
		seconds_electrified--

	//Pitch to the people!  Really sell it!
	if(last_slogan + slogan_delay <= world.time && slogan_list.len > 0 && !shut_up && DT_PROB(2.5, delta_time))
		var/slogan = pick(slogan_list)
		speak(slogan)
		last_slogan = world.time

	if(shoot_inventory && DT_PROB(shoot_inventory_chance, delta_time))
		throw_item()
/**
 * Speak the given message verbally
 *
 * Checks if the machine is powered and the message exists
 *
 * Arguments:
 * * message - the message to speak
 */
/obj/machinery/vending/proc/speak(message)
	if(machine_stat & (BROKEN|NOPOWER))
		return
	if(!message)
		return

	say(message)

/obj/machinery/vending/power_change()
	. = ..()
	if(powered())
		START_PROCESSING(SSmachines, src)

//Somebody cut an important wire and now we're following a new definition of "pitch."
/**
 * Throw an item from our internal inventory out in front of us
 *
 * This is called when we are hacked, it selects a random product from the records that has an amount > 0
 * This item is then created and tossed out in front of us with a visible message
 */
/obj/machinery/vending/proc/throw_item()
	var/obj/throw_item = null
	var/mob/living/target = locate() in view(7,src)
	if(!target)
		return FALSE

	for(var/datum/data/vending_product/R in shuffle(product_records))
		if(R.amount <= 0) //Try to use a record that actually has something to dump.
			continue
		var/dump_path = R.product_path
		if(!dump_path)
			continue

		R.amount--
		throw_item = new dump_path(loc)
		break
	if(!throw_item)
		return FALSE

	pre_throw(throw_item)

	throw_item.throw_at(target, 16, 3)
	visible_message(SPAN_DANGER("[src] launches [throw_item] at [target]!"))
	return TRUE
/**
 * A callback called before an item is tossed out
 *
 * Override this if you need to do any special case handling
 *
 * Arguments:
 * * I - obj/item being thrown
 */
/obj/machinery/vending/proc/pre_throw(obj/item/I)
	return
/**
 * Shock the passed in user
 *
 * This checks we have power and that the passed in prob is passed, then generates some sparks
 * and calls electrocute_mob on the user
 *
 * Arguments:
 * * user - the user to shock
 * * prb - probability the shock happens
 */
/obj/machinery/vending/proc/shock(mob/living/user, prb)
	if(!istype(user) || machine_stat & (BROKEN|NOPOWER)) // unpowered, no shock
		return FALSE
	if(!prob(prb))
		return FALSE
	do_sparks(5, TRUE, src)
	var/check_range = TRUE
	if(electrocute_mob(user, get_area(src), src, 0.7, check_range))
		return TRUE
	else
		return FALSE
/**
 * Are we able to load the item passed in
 *
 * Arguments:
 * * I - the item being loaded
 * * user - the user doing the loading
 */
/obj/machinery/vending/proc/canLoadItem(obj/item/I, mob/user)
	return FALSE

/obj/machinery/vending/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	. = ..()
	var/mob/living/L = AM
	if(tilted || !istype(L) || !prob(20 * (throwingdatum.speed - L.throw_speed))) // hulk throw = +20%, neckgrab throw = +20%
		return

	tilt(L)

/obj/machinery/vending/attack_tk_grab(mob/user)
	to_chat(user, SPAN_WARNING("[src] seems to resist your mental grasp!"))

///Crush the mob that the vending machine got thrown at
/obj/machinery/vending/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(isliving(hit_atom))
		tilt(fatty=hit_atom)
	return ..()

/obj/machinery/vending/custom
	name = "Custom Vendor"
	icon_state = "custom"
	icon_deny = "custom-deny"
	max_integrity = 400
	payment_department = NO_FREEBIES
	light_mask = "custom-light-mask"
	refill_canister = /obj/item/vending_refill/custom
	/// where the money is sent
	var/datum/bank_account/private_a
	/// max number of items that the custom vendor can hold
	var/max_loaded_items = 20
	/// Base64 cache of custom icons.
	var/list/base64_cache = list()

/obj/machinery/vending/custom/compartmentLoadAccessCheck(mob/user)
	. = FALSE
	if(!isliving(user))
		return FALSE
	var/mob/living/L = user
	var/obj/item/card/id/C = L.get_idcard(FALSE)
	if(C?.registered_account && C.registered_account == private_a)
		return TRUE

/obj/machinery/vending/custom/canLoadItem(obj/item/I, mob/user)
	. = FALSE
	if(I.flags_1 & HOLOGRAM_1)
		say("This vendor cannot accept nonexistent items.")
		return
	if(loaded_items >= max_loaded_items)
		say("There are too many items in stock.")
		return
	if(istype(I, /obj/item/stack))
		say("Loose items may cause problems, try to use it inside wrapping paper.")
		return
	if(I.custom_price)
		return TRUE

/obj/machinery/vending/custom/ui_data(mob/user)
	. = ..()
	.["access"] = compartmentLoadAccessCheck(user)
	.["vending_machine_input"] = list()
	for (var/O in vending_machine_input)
		if(vending_machine_input[O] > 0)
			var/base64
			var/price = 0
			for(var/obj/T in contents)
				if(T.name == O)
					price = T.custom_price
					if(!base64)
						if(base64_cache[T.type])
							base64 = base64_cache[T.type]
						else
							base64 = icon2base64(icon(T.icon, T.icon_state))
							base64_cache[T.type] = base64
					break
			var/list/data = list(
				name = O,
				price = price,
				img = base64
			)
			.["vending_machine_input"] += list(data)

/obj/machinery/vending/custom/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("dispense")
			. = TRUE
			if(!vend_ready)
				return
			var/N = params["item"]
			var/obj/S
			vend_ready = FALSE
			var/obj/item/card/id/C
			if(isliving(usr))
				var/mob/living/L = usr
				C = L.get_idcard(TRUE)
			if(!C)
				say("No card found.")
				flick(icon_deny,src)
				vend_ready = TRUE
				return
			else if (!C.registered_account)
				say("No account found.")
				flick(icon_deny,src)
				vend_ready = TRUE
				return
			var/datum/bank_account/account = C.registered_account
			for(var/obj/O in contents)
				if(O.name == N)
					S = O
					break
			if(S)
				if(compartmentLoadAccessCheck(usr))
					vending_machine_input[N] = max(vending_machine_input[N] - 1, 0)
					S.forceMove(drop_location())
					loaded_items--
					use_power(5)
					vend_ready = TRUE
					updateUsrDialog()
					return
				if(account.has_money(S.custom_price))
					account.adjust_money(-S.custom_price)
					var/datum/bank_account/owner = private_a
					if(owner)
						owner.adjust_money(S.custom_price)
						SSblackbox.record_feedback("amount", "vending_spent", S.custom_price)
						log_econ("[S.custom_price] credits were spent on [src] buying a [S] by [owner.account_holder], owned by [private_a.account_holder].")
					vending_machine_input[N] = max(vending_machine_input[N] - 1, 0)
					S.forceMove(drop_location())
					loaded_items--
					use_power(5)
					if(last_shopper != REF(usr) || purchase_message_cooldown < world.time)
						say("Thank you for buying local and purchasing [S]!")
						purchase_message_cooldown = world.time + 5 SECONDS
						last_shopper = REF(usr)
					vend_ready = TRUE
					updateUsrDialog()
					return
				else
					say("You do not possess the funds to purchase this.")
			vend_ready = TRUE

/obj/machinery/vending/custom/attackby(obj/item/I, mob/user, params)
	if(!private_a && isliving(user))
		var/mob/living/L = user
		var/obj/item/card/id/C = L.get_idcard(TRUE)
		if(C?.registered_account)
			private_a = C.registered_account
			say("\The [src] has been linked to [C].")

	if(compartmentLoadAccessCheck(user))
		if(istype(I, /obj/item/pen))
			name = stripped_input(user,"Set name","Name", name, 20)
			desc = stripped_input(user,"Set description","Description", desc, 60)
			slogan_list += stripped_input(user,"Set slogan","Slogan","Epic", 60)
			last_slogan = world.time + rand(0, slogan_delay)
			return

	return ..()

/obj/machinery/vending/custom/crowbar_act(mob/living/user, obj/item/I)
	return FALSE

/obj/machinery/vending/custom/Destroy()
	unbuckle_all_mobs(TRUE)
	var/turf/T = get_turf(src)
	if(T)
		for(var/obj/item/I in contents)
			I.forceMove(T)
		explosion(src, devastation_range = -1, light_impact_range = 3)
	return ..()

/obj/machinery/vending/custom/unbreakable
	name = "Indestructible Vendor"
	resistance_flags = INDESTRUCTIBLE

/obj/item/vending_refill/custom
	machine_name = "Custom Vendor"
	icon_state = "refill_custom"
	custom_premium_price = PAYCHECK_ASSISTANT

/obj/item/price_tagger
	name = "price tagger"
	desc = "This tool is used to set a price for items used in custom vendors."
	icon = 'icons/obj/device.dmi'
	icon_state = "pricetagger"
	custom_premium_price = PAYCHECK_ASSISTANT * 0.5
	///the price of the item
	var/price = 1

/obj/item/price_tagger/attack_self(mob/user)
	price = max(1, round(input(user,"set price","price") as num|null, 1))
	to_chat(user, SPAN_NOTICE(" The [src] will now give things a [price] cr tag."))

/obj/item/price_tagger/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(isitem(target))
		var/obj/item/I = target
		I.custom_price = price
		to_chat(user, SPAN_NOTICE("You set the price of [I] to [price] cr."))

/obj/machinery/vending/custom/greed //name and like decided by the spawn
	icon_state = "greed"
	icon_deny = "greed-deny"
	light_mask = "greed-light-mask"
	custom_materials = list(/datum/material/gold = MINERAL_MATERIAL_AMOUNT * 5)

/obj/machinery/vending/custom/greed/Initialize(mapload)
	. = ..()
	//starts in a state where you can move it
	panel_open = TRUE
	set_anchored(FALSE)
	add_overlay("[initial(icon_state)]-panel")
	//and references the deity
	name = "[GLOB.deity]'s Consecrated Vendor"
	desc = "A vending machine created by [GLOB.deity]."
	slogan_list = list("[GLOB.deity] says: It's your divine right to buy!")
	add_filter("vending_outline", 9, list("type" = "outline", "color" = COLOR_VERY_SOFT_YELLOW))
	add_filter("vending_rays", 10, list("type" = "rays", "size" = 35, "color" = COLOR_VIVID_YELLOW))


