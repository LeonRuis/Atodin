package Atalay

import rl "vendor:raylib"
import strconv "core:strconv"
import strings "core:strings"

sec: int = 0
min: int = 0 
hour: int = 0

day: int = 1 
month: int = 1 
year: int = 1 

update_time :: proc() {
	sec += 30 // 2 seems like a good number

	if sec >= 60 {
		min += 1	
		sec = 0
	}

	if min >= 60 {
		hour += 1
		min = 0
	}
	
	if hour >= 24 {
		day += 1
		hour = 0
	}

	if day >= 30 {
		month += 1 
		day = 1 
	}

	if month >= 11 {
		year += 1
		month = 1 
	}
}

draw_time :: proc() {
	time_rect: rl.Rectangle = {
		200,
		0, 
		100,
		20
	}

	date_rect: rl.Rectangle = {
		400,
		0, 
		100,
		20
	}

	// Time
	sec_buf: [4]byte
	min_buf: [4]byte
	hour_buf: [4]byte

	sec_str: string = strconv.itoa(sec_buf[:], sec)
	if sec < 10 {
		sec_str = strings.concatenate({"0", sec_str})
	}

	min_str: string = strconv.itoa(min_buf[:], min)
	if min < 10 {
		min_str = strings.concatenate({"0", min_str})
	}

	hour_str: string = strconv.itoa(hour_buf[:], hour)
	if hour < 10 {
		hour_str = strings.concatenate({"0", hour_str})
	}

	time_str: string = strings.concatenate({hour_str, " : ", min_str, " : ", sec_str})
	time_cstr: cstring = strings.clone_to_cstring(time_str)

	rl.GuiLabel(time_rect, time_cstr)


	// Date
	day_buf: [4]byte
	month_buf: [4]byte
	year_buf: [4]byte

	day_str: string = strconv.itoa(day_buf[:], day)
	month_str: string = strconv.itoa(month_buf[:], month)
	year_str: string = strconv.itoa(year_buf[:], year)

	date_str: string = strings.concatenate({
		day_str, get_current_day_ordinal(), ", ", 
		get_current_month(), ", ", 
		year_str
	})

	date_cstr: cstring = strings.clone_to_cstring(date_str)

	rl.GuiLabel(date_rect, date_cstr)
}

get_current_day_ordinal :: proc() -> string {
	switch day {
		case 1, 21:
			return "st"

		case 2, 22: 
			return "nd"

		case 3, 23: 
			return "rd"

		case: 
			return "th"
	}
}

get_current_month :: proc() -> string {
	switch month {
		case 1:
			return "January"

		case: 
			return "No valid month"
	}
}