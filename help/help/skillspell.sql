@Favorit ,---------------------------------------------------------.
@Favorit | Field       Type           Null   Key   Default   Extra |
@Favorit |---------------------------------------------------------|
@Favorit | spellId     int(11)        NO     PRI                   |
@Favorit | file_name   varchar(100)   YES          0               |
@Favorit | file_time   int(11)        YES          0               |
@Favorit | spellName   varchar(100)   YES          0               |
@Favorit | spellText   mediumtext     YES          0               |
@Favorit `---------------------------------------------------------'
@Favorit ,---------------------------------------------------------.
@Favorit | Field       Type           Null   Key   Default   Extra |
@Favorit |---------------------------------------------------------|
@Favorit | spellId     int(11)        YES          0               |
@Favorit | statName    varchar(100)   YES          0               |
@Favorit | statValue   mediumtext     YES          0               |
@Favorit `---------------------------------------------------------'
@Favorit ,----------------------------------------------------------------------------------
    ------------------.
@Favorit | spellId   file_name                file_time    spellName     spellText
                      |
@Favorit |----------------------------------------------------------------------------------
    ------------------|
@Favorit | 1         obj/spells/flame_fists   1075766349   flame fists   Surrounds caster's
    hands with flames |
@Favorit `----------------------------------------------------------------------------------
    ------------------'
@Favorit ,----------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------.
@Favorit | spellId   statName          statValue




                    |
@Favorit |----------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------|
@Favorit | 1         action_duration   2




                    |
@Favorit | 1         spell_category    fire




                    |
@Favorit | 1         aff_stat          wis




                    |
@Favorit | 1         spell_type        6




                    |
@Favorit | 1         extra_help        Ninjas have long been able to use their secret
    training and skills to
@Favorit their advantage. Not only are they superb masters of martial arts
@Favorit techniques, but they also employ some dark magic to assist them. Those who
@Favorit have trained in this discipline are able to conjure magical flames that
@Favorit surround their fists. This lets them also burn through their foes as they
@Favorit strike, a deadly combination of physical and magical strength.
@Favorit  |
@Favorit `----------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------
    ----------------'
