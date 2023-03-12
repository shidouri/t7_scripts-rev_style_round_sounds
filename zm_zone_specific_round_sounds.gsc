
#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\system_shared;
#insert scripts\shared\shared.gsh;

#define SHORT_SOUND_MAX_TIME 25


#namespace rev_style_round_sounds;

REGISTER_SYSTEM_EX( "rev_style_round_sounds", &__init__, &__main__, undefined )

// WHY ARE YOU LOOKING HERE? GET TO LINE 28, YOU SILLY SAUSAGE.

function __init__()
{
    level.a_location_round_sound_begin = [];
    level.a_location_round_sound_begin_short = [];
    level.a_location_round_sound_end = [];

}


function __main__() 
{
    //  Round Start Definitions
    //  FORMAT: level.a_location_round_sound_begin["ZONENAME"] = array("zone1Alias1", "zone1Alias2", "zone1Alias3" [etc]); [NO COMMA ON LAST!]
    //  ie.     level.a_location_round_sound_begin["start_zone"] = array("soe_roundstart_1", "soe_roundstart_2", "soe_roundstart_3", "soe_roundstart_4");

    //  To setup multiple zones to a single sound-set, set up one of the zone sounds as normal (seen above), and for the other
    //  zone entries, assign them the variable of the zone you just set up.

    //  For example, if "start_zone" and "zone_2" were part of the same area, you could do this:
    //  level.a_location_round_sound_begin["start_zone"] = array("soe_roundstart_1", "soe_roundstart_2", "soe_roundstart_3", "soe_roundstart_4");
    //  level.a_location_round_sound_begin["zone_2"] = level.a_location_round_sound_begin["start_zone"];

    //  NOTE: If a zone is not set up here, "default_start_round_sound" will be played [Shidouri's rip of WAW/BO1 Start Round]
    //  If a zone is giving you this sound instead of the one you want, it's because you haven't set it up here.
    //  If a zone is giving you NO sound, check the linker for snd_convert errors. A wise man once said "snd_convert is an asshat".
    
    level.a_location_round_sound_begin["start_zone"] = array( "rsrs_zone1_start1", "rsrs_zone1_start2", "rsrs_zone1_start3", "rsrs_zone1_start4" );
    level.a_location_round_sound_begin["zone_2"] = array( "rsrs_zone2_start1", "rsrs_zone2_start2", "rsrs_zone2_start3", "rsrs_zone2_start4", "rsrs_zone2_start5" );
    level.a_location_round_sound_begin["zone_3"] = array( "rsrs_zone3_start1", "rsrs_zone3_start2", "rsrs_zone3_start3", "rsrs_zone3_start4" );
    level.a_location_round_sound_begin["zone_4"] = level.a_location_round_sound_begin["start_zone"];
    


    //  Round End Definitions
    //  FORMAT: level.a_location_round_sound_end["ZONENAME"] = array("zone1Alias1", "zone1Alias2", "zone1Alias3" [etc]); [NO COMMA ON LAST!]  
    //  ie.     level.a_location_round_sound_end["start_zone"] = array("soe_roundend_1", "soe_roundend_2", "soe_roundend_3", "soe_roundend_4");
    
    //  Exact same as the above, just for round end instead of round start.
    
    level.a_location_round_sound_end["start_zone"] = array( "rsrs_zone1_end1", "rsrs_zone1_end2", "rsrs_zone1_end3", "rsrs_zone1_end4", "rsrs_zone1_end5" );
    level.a_location_round_sound_end["zone_2"] = array( "rsrs_zone2_end1", "rsrs_zone2_end2", "rsrs_zone2_end3" );
    level.a_location_round_sound_end["zone_3"] = array( "rsrs_zone3_end1", "rsrs_zone3_end2", "rsrs_zone3_end3", "rsrs_zone3_end4" );
    level.a_location_round_sound_end["zone_4"] = level.a_location_round_sound_end["start_zone"];




        
    //  DO NOT TOUCH ANYTHING IN THE FILE FROM HERE UNLESS YOU KNOW WHAT YOU ARE DOING.

    callback::on_connect(&revelations_style_round_sounds);

    keys = GetArrayKeys(level.a_location_round_sound_begin);
    foreach(k in keys)
    {
        level.a_location_round_sound_begin_short[k] = [];
        iPrintLnBold("KEY = &&1", k);
        foreach(sound in level.a_location_round_sound_begin[k])
        {
            if(isDefined(SoundGetPlaybackTime(sound)) && Ceil(SoundGetPlaybackTime(sound) / 1000) <= SHORT_SOUND_MAX_TIME)
                array::add(level.a_location_round_sound_begin_short[k], sound, false);
        }

        WAIT_SERVER_FRAME;
    }

}



function revelations_style_round_sounds()
{
    self endon("disconnect");
    self endon("game_over");

    round_start_to_play = undefined;
    round_end_to_play = undefined;
    while(isDefined(self))
    {
        level waittill("start_of_round");

        wait .5; // let dogs or other ai round stuff go first
        if(level flag::exists("dog_round") && level flag::get("dog_round"))
            continue;
        // add other special rounds here to avoid being overridden


        if(level.round_number > 1 && level.round_number < 8) // let initial opening sound play without overwriting
        {
            round_start_to_play = self get_round_start_sound_for_location(round_start_to_play, true);
            self PlaySoundToPlayer(round_start_to_play, self); 
        }
        else if(level.round_number >= 8)
        {
            round_start_to_play = self get_round_start_sound_for_location(round_start_to_play, false);
            self PlaySoundToPlayer(round_start_to_play, self); 
        }
        level waittill("end_of_round");
        if(isDefined(round_start_to_play)) 
            WAIT_SERVER_FRAME;
        round_end_to_play = self get_round_end_sound_for_location(round_end_to_play);
        self PlaySoundToPlayer(round_end_to_play, self);
        
    }
}


function get_round_start_sound_for_location(last_sound = undefined, short = false)
{

    if(short)
    {
        if(!isDefined(level.a_location_round_sound_begin_short) || !isDefined(level.a_location_round_sound_begin_short[self.zone_name]))
        {
            // Just try and get any
            if(!isDefined(level.a_location_round_sound_begin) && !isDefined(level.a_location_round_sound_begin[self.zone_name]))
                return "default_start_round_sound";

            else if(!IsArray(level.a_location_round_sound_begin[self.zone_name]))
                return level.a_location_round_sound_begin[self.zone_name];

            else if(IsArray(level.a_location_round_sound_begin[self.zone_name]))
                return array::randomize(level.a_location_round_sound_begin[self.zone_name])[0];
        }

        else if(!IsArray(level.a_location_round_sound_begin_short[self.zone_name]))
            return level.a_location_round_sound_begin_short[self.zone_name];

        else if(IsArray(level.a_location_round_sound_begin_short[self.zone_name]))
        {
            new_sound = array::randomize(level.a_location_round_sound_begin_short[self.zone_name])[0];

            if(!isDefined(last_sound)) return new_sound;

            while(new_sound == last_sound)
            {
                new_sound = array::randomize(level.a_location_round_sound_begin_short[self.zone_name])[0];
                WAIT_SERVER_FRAME;            
            }

            return new_sound;
        }
        
    }

    else
    {
        if(!isDefined(level.a_location_round_sound_begin) || !isDefined(level.a_location_round_sound_begin[self.zone_name]))
            return "default_start_round_sound";

        else if(!IsArray(level.a_location_round_sound_begin[self.zone_name]))
            return level.a_location_round_sound_begin[self.zone_name];
        
        else if(IsArray(level.a_location_round_sound_begin[self.zone_name]))
        {
            new_sound = array::randomize(level.a_location_round_sound_begin[self.zone_name])[0];

            if(!isDefined(last_sound)) return new_sound;

            while(new_sound == last_sound)
            {
                new_sound = array::randomize(level.a_location_round_sound_begin[self.zone_name])[0];
                WAIT_SERVER_FRAME;            
            }

            return new_sound;
        }
    }
        
}


function get_round_end_sound_for_location(last_sound = undefined)
{
    if(!isDefined(level.a_location_round_sound_end) || !isDefined(level.a_location_round_sound_end[self.zone_name]))
        return "default_end_round_sound";

    else if(!IsArray(level.a_location_round_sound_end[self.zone_name]))
        return level.a_location_round_sound_end[self.zone_name];
    
    else if(IsArray(level.a_location_round_sound_end[self.zone_name]))
    {
        new_sound = array::randomize(level.a_location_round_sound_end[self.zone_name])[0];
        
        if(!isDefined(last_sound)) return new_sound;

        while(new_sound == last_sound)
        {
            new_sound = array::randomize(level.a_location_round_sound_end[self.zone_name])[0];
            WAIT_SERVER_FRAME;
        }

        return new_sound;

    }


}

