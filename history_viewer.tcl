
#
# Logic
#

set ::history_match_profile 0

blt::vector create history_elapsed history_pressure_goal history_flow_goal history_temperature_goal

blt::vector create history_pressure history_flow history_flow_weight
blt::vector create history_weight

blt::vector create history_state_change
blt::vector create history_resistance_weight history_resistance

blt::vector create history_flow_delta_negative_2x history_flow_delta_negative history_pressure_delta

blt::vector create history_temperature_basket history_temperature_mix  history_temperature_goal


array set ::past_shot {}

proc show_history_page {} {
	fill_history_listbox
	page_to_show_when_off "history"
	set_history_scrollbar_dimensions
}

proc fill_history_listbox {} {
	#puts "fill_history_listbox $widget"
	set widget $::history_widget
	$widget delete 0 99999
	set cnt 0

	set ::history_files [lsort -dictionary -decreasing [glob -nocomplain -tails -directory "[homedir]/history/" *.shot]]

    foreach shot_file $::history_files {
        set tailname [file tail $shot_file]
        set newfile [file rootname $tailname]
        set fname "history/$newfile.csv"

		array unset -nocomplain shot
		catch {
			array set shot [read_file "history/$shot_file"]
		}
		if {[array size shot] == 0} {
			msg "Corrupted shot history item: 'history/$shot_file'"
			continue
		}
		set dbg [array get shot]

		if {$::history_match_profile == 1} {
			array set shot_settings $shot(settings)
			if {$shot_settings(profile_to_save) != $::settings(profile_to_save)} {
				continue
			}
		}

		$widget insert $cnt $newfile
		incr cnt		
	}

	set $::history_widget widget
}

proc god_shot_from_history {} {
    set ::settings(god_espresso_pressure) [history_pressure range 0 end]
    set ::settings(god_espresso_temperature_basket) [history_temperature_basket range 0 end]
    set ::settings(god_espresso_flow) [history_flow range 0 end]
    set ::settings(god_espresso_flow_weight) [history_flow_weight range 0 end]
    set ::settings(god_espresso_elapsed) [history_elapsed range 0 end]

    save_settings
    god_shot_reference_reset
}


proc past_title {} {
	if {[info exists ::past_shot(settings)] == 1} {
		array set settings_array $::past_shot(settings)
		return $settings_array(profile_title)
	}

	return ""
}



proc show_past_shot {} {
	set stepnum [$::history_widget curselection]
	if {$stepnum == ""} {
		return
	}

	set shotfile [lindex $::history_files $stepnum]
	set fn "[homedir]/history/$shotfile"

	array set ::past_shot [encoding convertfrom utf-8 [read_binary_file $fn]]

	msg "Read shot $fn"

	history_elapsed set $::past_shot(espresso_elapsed)
	history_pressure_goal set $::past_shot(espresso_pressure_goal)
	history_flow_goal set $::past_shot(espresso_flow_goal)
	history_pressure set $::past_shot(espresso_pressure)
	history_flow set $::past_shot(espresso_flow)
	history_flow_weight set $::past_shot(espresso_flow_weight)
	history_weight set $::past_shot(espresso_weight)
	history_temperature_basket set $::past_shot(espresso_temperature_basket)
	history_temperature_mix set $::past_shot(espresso_temperature_mix)
	history_temperature_goal set $::past_shot(espresso_temperature_goal)

	# New 1.34.5 shot fields
	history_temperature_goal set $::past_shot(espresso_temperature_goal)
	history_state_change set $::past_shot(espresso_state_change)
	history_resistance_weight set $::past_shot(espresso_resistance_weight)
	history_resistance set $::past_shot(espresso_resistance)
	history_flow_delta_negative_2x set $::past_shot(espresso_flow_delta_negative_2x)
	history_flow_delta_negative set $::past_shot(espresso_flow_delta_negative)
	history_pressure_delta set $::past_shot(espresso_pressure_delta)

	#msg $::past_shot(settings)
}

#
# UI
#

add_background "history"

add_de1_widget "history" graph 680 240 {
	#Target
	$widget element create line_history_espresso_pressure_goal -xdata history_elapsed -ydata history_pressure_goal -symbol none -label "" -linewidth [rescale_x_skin 8] -color [theme primary_light]  -smooth $::settings(live_graph_smoothing_technique) -pixels 0 -dashes {5 5};
	$widget element create line_history_espresso_flow_goal -xdata history_elapsed -ydata history_flow_goal -symbol none -label "" -linewidth [rescale_x_skin 8] -color [theme secondary_light] -smooth $::settings(live_graph_smoothing_technique) -pixels 0  -dashes {5 5};

	$widget element create line_history_espresso_pressure -xdata history_elapsed -ydata history_pressure  -symbol none -label "" -linewidth [rescale_x_skin 12] -color [theme primary]  -smooth $::settings(live_graph_smoothing_technique) -pixels 0 -dashes $::settings(chart_dashes_pressure);
	$widget element create line_history_espresso_flow -xdata history_elapsed -ydata history_flow -symbol none -label "" -linewidth [rescale_x_skin 12] -color  [theme secondary] -smooth $::settings(live_graph_smoothing_technique) -pixels 0  -dashes $::settings(chart_dashes_flow);

	$widget element create line_history_espresso_weight -xdata history_elapsed -ydata history_weight -symbol none -label "" -linewidth [rescale_x_skin 6] -color #f8b888 -smooth $::settings(live_graph_smoothing_technique) -pixels 0 -dashes $::settings(chart_dashes_espresso_weight);

	$widget element create line_history_state_change -xdata history_elapsed -ydata history_state_change -label "" -linewidth [rescale_x_skin 6] -color #AAAAAA  -pixels 0 ;

	$widget element create line_history_resistance_weight  -xdata history_elapsed -ydata history_resistance_weight -symbol none -label "" -linewidth [rescale_x_skin 4] -color #e5e500 -smooth $::settings(live_graph_smoothing_technique) -pixels 0
	$widget element create line_history_resistance  -xdata history_elapsed -ydata history_resistance -symbol none -label "" -linewidth [rescale_x_skin 4] -color #e5e500 -smooth $::settings(live_graph_smoothing_technique) -pixels 0  -dashes {6 2};

	$widget element create line_history_delta_pressure -xdata history_elapsed -ydata history_pressure_delta -symbol none -label "" -linewidth [rescale_x_skin 4] -color #e5e500 -smooth $::settings(live_graph_smoothing_technique) -pixels 0  -dashes {6 2};
	$widget element create line_history_delta_flow  -xdata history_elapsed -ydata history_flow_delta_negative -symbol none -label "" -linewidth [rescale_x_skin 4] -color #e5e500 -smooth $::settings(live_graph_smoothing_technique) -pixels 0  -dashes {6 2};
	$widget element create line_history_delta_flow_2x  -xdata history_elapsed -ydata history_flow_delta_negative_2x -symbol none -label "" -linewidth [rescale_x_skin 4] -color #e5e500 -smooth $::settings(live_graph_smoothing_technique) -pixels 0  -dashes {6 2};

	$widget axis configure x -color [theme background_text] -tickfont Helv_7 -min 0.0;
	$widget axis configure y -color [theme background_text] -tickfont Helv_7 -min 0.0 -max 12 -subdivisions 5 -majorticks {0 1 2 3 4 5 6 7 8 9 10 11 12}  -hide 0;
} -plotbackground [theme background] -width [rescale_x_skin 1860] -height [rescale_y_skin 1180] -borderwidth 1 -background [theme background] -plotrelief flat

add_de1_widget "history" checkbutton 80 80 {} -text [translate "Match current profile"] -indicatoron true  -font $::font_tiny -bg [theme background] -anchor nw -foreground [theme background_text] -variable ::history_match_profile -borderwidth 0 -selectcolor [theme background] -highlightthickness 0 -activebackground [theme background]  -bd 0 -activeforeground [theme background_text] -relief flat -bd 0 -command {fill_history_listbox}

add_de1_widget "history" listbox 80	180 {
	set ::history_widget $widget
	bind $::history_widget <<ListboxSelect>> ::show_past_shot
	fill_history_listbox
} -background #fbfaff -font Helv_9 -bd 0 -height 18 -width 16 -borderwidth 0 -selectborderwidth 0  -relief flat -highlightthickness 0 -selectmode single -foreground [theme primary] -selectbackground [theme primary_dark]  -selectforeground [theme button_text_light] -yscrollcommand {scale_scroll_new $::history_widget ::history_slider}

set ::history_slider 0
set ::history_scrollbar [add_de1_widget "history" scale 10000 1 {} -from 0 -to .90 -bigincrement 0.2 -background [theme primary] -borderwidth 1 -showvalue 0 -resolution .01 -length [rescale_x_skin 400] -width [rescale_y_skin 150] -variable ::history_slider -font Helv_10_bold -sliderlength [rescale_x_skin 125] -relief flat -command {listbox_moveto $::history_widget $::history_slider}  -foreground [theme background] -troughcolor [theme background] -borderwidth 2  -highlightthickness 0]

proc set_history_scrollbar_dimensions {} {
	set_scrollbar_dimensions $::history_scrollbar $::history_widget
}

add_de1_variable "history" 80 1360 -width [rescale_x_skin 380]  -text "" -font $::font_big -fill [theme primary_light] -anchor "nw" -justify "center" -state "hidden" -textvariable {[past_title]}

create_button "history" 580 1440 1160 1560 [translate "Make Reference / Godshot"] $::font_tiny [theme button_tertiary] [theme button_text_light] { say [translate "settings"] $::settings(sound_button_in); god_shot_from_history; page_to_show_when_off "off" }
create_button "history" 1210 1440 1880 1560 [translate "Done"] $::font_tiny [theme button_tertiary] [theme button_text_light] { say [translate "settings"] $::settings(sound_button_in); page_to_show_when_off "off" }
