/obj/item/grenade
	name = "grenade"
	desc = "It has an adjustable timer."
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/grenade.dmi'
	icon_state = "grenade"
	item_state = "flashbang"
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'
	throw_speed = 3
	throw_range = 7
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	resistance_flags = FLAMMABLE
	max_integrity = 40
	var/active = 0
	var/det_time = 5 SECONDS
	var/display_timer = 1
	var/clumsy_check = GRENADE_CLUMSY_FUMBLE

/obj/item/grenade/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] primes [src], then eats it! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(src, 'sound/items/eatfood.ogg', 50, 1)
	preprime(user, det_time)
	user.transferItemToLoc(src, user, TRUE)//>eat a grenade set to 5 seconds >rush captain
	sleep(det_time)//so you dont die instantly
	return BRUTELOSS

/obj/item/grenade/deconstruct(disassembled = TRUE)
	if(!disassembled)
		prime()
	if(!QDELETED(src))
		qdel(src)

/obj/item/grenade/proc/clown_check(mob/living/carbon/human/user)
	var/clumsy = HAS_TRAIT(user, TRAIT_CLUMSY)
	if(clumsy && (clumsy_check == GRENADE_CLUMSY_FUMBLE))
		if(prob(50))
			to_chat(user, span_warning("Huh? How does this thing work?"))
			preprime(user, 5, FALSE)
			return FALSE
	else if(!clumsy && (clumsy_check == GRENADE_NONCLUMSY_FUMBLE))
		to_chat(user, span_warning("You pull the pin on [src]. Attached to it is a pink ribbon that says, \"[span_clown("HONK")]\""))
		preprime(user, 5, FALSE)
		return FALSE
	return TRUE


/obj/item/grenade/examine(mob/user)
	. = ..()
	if(display_timer)
		if(det_time > 0)
			. += "The timer is set to [DisplayTimeText(det_time)]."
		else
			. += "\The [src] is set for instant detonation."


/obj/item/grenade/attack_self(mob/user)
	if(!active)
		if(clown_check(user))
			preprime(user)

/obj/item/grenade/proc/log_grenade(mob/user, turf/T)
	log_bomber(user, "has primed a", src, "for detonation")

/obj/item/grenade/proc/preprime(mob/user, delayoverride, msg = TRUE, volume = 60)
	var/turf/T = get_turf(src)
	log_grenade(user, T) //Inbuilt admin procs already handle null users
	if(user)
		add_fingerprint(user)
		if(iscarbon(user))
			var/mob/living/carbon/C = user
			C.throw_mode_on()
		if(msg)
			to_chat(user, span_warning("You prime [src]! [capitalize(DisplayTimeText(det_time))]!"))
	playsound(src, 'sound/weapons/armbomb.ogg', volume, 1)
	active = TRUE
	icon_state = initial(icon_state) + "_active"
	addtimer(CALLBACK(src, PROC_REF(prime)), isnull(delayoverride)? det_time : delayoverride)

/obj/item/grenade/proc/prime()

/obj/item/grenade/proc/update_mob()
	if(ismob(loc))
		var/mob/M = loc
		M.dropItemToGround(src)

/obj/item/grenade/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(!active)
		change_det_time()
		to_chat(user, span_notice("You modify the time delay. It's set for [DisplayTimeText(det_time)]."))
	
/obj/item/grenade/multitool_act(mob/living/user, obj/item/I)
	. = ..()
	if(!active)
		var/newtime = text2num(stripped_input(user, "Please enter a new detonation time", name))
		if (newtime != null && user.canUseTopic(src, BE_CLOSE))
			change_det_time(newtime)
			to_chat(user, span_notice("You modify the time delay. It's set for [DisplayTimeText(det_time)]."))
			if (round(newtime * 10) != det_time)
				to_chat(user, span_warning("The new value is out of bounds. The lowest possible time is 3 seconds and highest is 5 seconds. Instant detonations are also possible."))

/obj/item/grenade/proc/change_det_time(time) //Time uses real time.
	if(time != null)
		if(time < 3)
			time = 3
		det_time = round(clamp(time * 1 SECONDS, 0, 5 SECONDS))
	else
		var/previous_time = det_time
		switch(det_time)
			if (0 SECONDS)
				det_time = 3 SECONDS
			if (3 SECONDS)
				det_time = 5 SECONDS
			if (5 SECONDS)
				det_time = 0 SECONDS
		if(det_time == previous_time)
			det_time = 5 SECONDS

/obj/item/grenade/attack_paw(mob/user)
	return attack_hand(user)

/obj/item/grenade/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	var/obj/projectile/P = hitby
	if(damage && attack_type == PROJECTILE_ATTACK && P.damage_type != STAMINA && prob(5))
		owner.visible_message(span_danger("[attack_text] hits [owner]'s [src], setting it off! What a shot!"))
		prime()
		return TRUE //It hit the grenade, not them

/obj/item/grenade/afterattack(atom/target, mob/user)
	. = ..()
	if(active)
		user.throw_item(target)
