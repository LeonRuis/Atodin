package Atalay

import rl "vendor:raylib"
import strconv "core:strconv"
import strings "core:strings"
import fmt "core:fmt"

sec: int = 0
min: int = 0 
hour: int = 0

day: int = 1 
month: int = 1 
year: int = 0

secs_per_tic: int = 30 // 2 seems like a good number

tick: int = 0
speed: i32 = 1

speed_gui :: proc() {
	rect: rl.Rectangle = {
		0,
		0, 
		100,
		20
	}

	// Speed by GUI
	rl.GuiToggleGroup(rect, "Pause;Normal;Fast;Forward", &speed)

	// Speed by Input
	if rl.IsKeyReleased(.G) {
		if speed == 0 {
			speed = 1	
		} else {
			speed = 0
		}
	} else if rl.IsKeyReleased(.ONE) {
		speed = 1
	} else if rl.IsKeyReleased(.TWO) {
		speed = 2
	} else if rl.IsKeyReleased(.THREE) {
		speed = 3
	}

	// Speed Control
	switch speed {
		case 0: 
			return

		case 1:
			tick += 1

		case 2:
			tick += 2

		case 3:
			tick += 15

		case:	
			fmt.println("No Speed Defined")
			tick += 0 
	}
}

update_time :: proc() {
	sec += secs_per_tic 
	// min += 30
	// month += 1

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
		WINDOW_WIDTH / 3.3,
		0, 
		100,
		20
	}

	date_rect: rl.Rectangle = {
		WINDOW_WIDTH / 2.8,
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

		case 2: 
			return "February"

		case 3: 
			return "March"

		case 4: 
			return "April"

		case 5: 
			return "May"

		case 6: 
			return "June"

		case 7: 
			return "July"

		case 8: 
			return "August"

		case 9: 
			return "September"

		case 10: 
			return "October"

		case 11: 
			return "November"

		case 12: 
			return "December"

		case: 
			return "No valid month"
	}
}

date_to_string :: proc(dob: Time) -> string {
	day_buf: [4]byte
	month_buf: [4]byte
	year_buf: [4]byte

	day_str: string = strconv.itoa(day_buf[:], dob[3])
	month_str: string = strconv.itoa(month_buf[:], dob[4])
	year_str: string = strconv.itoa(year_buf[:], dob[5])

	date_str: string = strings.concatenate({
		day_str, get_current_day_ordinal(), ", ", 
		get_current_month(), ", Year ", 
		year_str
	})

	return date_str
}
