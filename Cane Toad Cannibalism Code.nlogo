globals [
  run-num                ;; The current simulation run number
  egg-release-days       ;; A list of numbers of length num-times-eggs-laid with digits from {1,...,365} to indicate which day each batch of eggs are laid for each year
  ;; The rest of these global variables are just used for plotting graphs
  num-population
  num-toads
  num-tadpoles
  num-eggs
  num-cannibal-deaths
  num-cannibal-deaths-eggs
  num-cannibal-deaths-tadpoles
  num-cannibal-deaths-toads
  num-starving-deaths
  num-old-age-deaths
  total-food-source
  total-hunger-level
]

patches-own [
  chemical-level         ;; Patches can have chemical levels from the range {0,...,max-chemical-level} (from chemicals in eggs satchels when they are eaten)
  max-chemical-limit
]

;; Four types of breeds/turtles: Food, Toads, Tadpoles, and Eggs
breed [ foods food ]
breed [ toads toad ]
breed [ tadpoles tadpole ]
breed [ eggs egg ]

foods-own [
  food-level             ;; The amount of food this food source currently has
]

toads-own [
  days-alive             ;; The number of days/ticks the cane toad has been alive for
  life-span              ;; The maximum age the toads can live before dying naturally
  max-size               ;; The maximum size the cane toad can grow to
  toad-size              ;; The current size of the cane toad in centimetres
  hunger-level           ;; The current hunger level of a cane toad (0.0 - 1.0)
]

tadpoles-own [
  num-alive              ;; Number of tadpoles alive in tadpole cluster (each tadpole turtle is initially set to 100, decreases as they get eaten)
  days-alive             ;; The number of days/ticks the cane toad has been alive for
  tadpole-to-toad-days   ;; The number of days of being alive the cane toads transform from a tadpole into a toad
  hunger-level           ;; The current hunger level of a cane toad (0.0 - 1.0)
]

eggs-own [
  num-alive              ;; Number of tadpoles alive in tadpole cluster (each tadpole turtle is initially set to 100, decreases as they get eaten)
  days-alive             ;; The number of days/ticks the cane toad has been alive for
]


;;;
;;; SETUP PROCEDURES
;;;

to setup
  if clear [
    clear-all
    clear-globals
   set clear false
  ]
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing

  set num-cannibal-deaths 0
  set num-cannibal-deaths-eggs 0
  set num-cannibal-deaths-tadpoles 0
  set num-cannibal-deaths-toads 0
  set num-starving-deaths 0
  set num-old-age-deaths 0

  set run-num run-num + 1
  let mycolor one-of base-colors
  let legend-name (word "Run: " run-num)
  set-current-plot "Total Population"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Toad Population"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Tadpole Population"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Egg Population"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Number of Cannibalistic Deaths"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Number of Cannibalistic Egg Deaths"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Number of Cannibalistic Tadpole Deaths"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Number of Cannibalistic Toad Deaths"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Number of Deaths from Hunger"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Number of Deaths from Old Age"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Food Availability Percentage"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  set-current-plot "Hunger Percentage"
  create-temporary-plot-pen legend-name
  set-plot-pen-color mycolor
  set-plot-pen-mode 0

  setup-landscape
  setup-toads
  reset-ticks
end


to setup-landscape
  ;; initialise all patches to have chemical levels of 0
  ask patches [
    set chemical-level 0
    set max-chemical-limit 0
    set pcolor black
  ]

  ;; setting up the food source to the centre of random patches
  let counter 1
  while [ counter <= num-food-patches ] [
    create-foods 1 [
      move-to one-of patches
      ;; initialise the food levels of all food sources to 50%
      set food-level max-food / 2

      set shape "plant"
      set size 1.5
      assign-color-food
    ]
    set counter counter + 1
  ]
end


;; initialise the starting toads, no tadpoles or eggs are initialised
to setup-toads
  create-toads initial-toads [
    setxy random-xcor random-ycor
    set days-alive int random-normal 3650 2
    set life-span random-normal 6000 400
    set max-size random-normal 12.5 1
    set toad-size random-normal (max-size - 3) 1
    set hunger-level 0.8
    set shape "frog top"
    set size 1
    assign-color-toad
  ]

  create-tadpoles (initial-tadpoles / 100) [
    setxy random-xcor random-ycor
    set num-alive 100
    set days-alive random-normal 12.5 2
    set tadpole-to-toad-days random-normal 42 10
    set hunger-level 0.8
    set shape "exclamation"
    set size 1
    assign-color-toad
  ]
end


;; The cane toads are colored according to their hunger levels for easier visualisation
;; Low Hunger / Full (Green): 0.8 - 1
;; Medium Hunger (Yellow): 0.5 - 0.8
;; High Hunger (Orange): 0.3 - 0.5
;; Very High Hunger / Starving (Red): 0 - 0.3
to assign-color-toad
  if (hunger-level >= 0.8)
  [ set color green ]
  if (hunger-level >= 0.5) and (hunger-level < 0.8)
  [ set color yellow ]
  if (hunger-level >= 0.3) and (hunger-level < 0.5)
  [ set color orange ]
  if (hunger-level < 0.3)
  [ set color red ]
end

;; Similar to assign-color-toad as above but for the current food levels of food sources
to assign-color-food
  if (food-level >= (0.8 * max-food))
  [ set color green ]
  if (food-level >= (0.5 * max-food)) and (food-level < (0.8 * max-food))
  [ set color yellow ]
  if (food-level >= (0.3 * max-food)) and (food-level < (0.5 * max-food))
  [ set color orange ]
  if (food-level < (0.3 * max-food))
  [ set color red ]
  if (food-level = 0)
  [ set color black ]
end


;;;
;;; GO PROCEDURES
;;;

to go
  set num-toads count toads
  set num-tadpoles 0
  ask tadpoles [ set num-tadpoles (num-tadpoles + num-alive) ]
  set num-eggs 0
  ask eggs [ set num-eggs (num-eggs + num-alive) ]
  set num-population (num-toads + num-tadpoles + num-eggs)
  set total-food-source ((sum [food-level] of foods) / (count foods))
  ifelse ((count toads + count tadpoles) = 0)
  [ set total-hunger-level 0 ]
  [ set total-hunger-level (((sum [hunger-level] of toads) + (sum [hunger-level] of tadpoles)) / (count toads + count tadpoles)) ]

  set-current-plot "Total Population"
  set-plot-pen-mode 0
  plot num-population

  set-current-plot "Toad Population"
  set-plot-pen-mode 0
  plot num-toads

  set-current-plot "Tadpole Population"
  set-plot-pen-mode 0
  plot num-tadpoles

  set-current-plot "Egg Population"
  set-plot-pen-mode 0
  plot num-eggs

  set-current-plot "Number of Cannibalistic Deaths"
  set-plot-pen-mode 0
  plot num-cannibal-deaths

  set-current-plot "Number of Cannibalistic Egg Deaths"
  set-plot-pen-mode 0
  plot num-cannibal-deaths-eggs

  set-current-plot "Number of Cannibalistic Tadpole Deaths"
  set-plot-pen-mode 0
  plot num-cannibal-deaths-tadpoles

  set-current-plot "Number of Cannibalistic Toad Deaths"
  set-plot-pen-mode 0
  plot num-cannibal-deaths-toads

  set-current-plot "Number of Deaths from Hunger"
  set-plot-pen-mode 0
  plot num-starving-deaths

  set-current-plot "Number of Deaths from Old Age"
  set-plot-pen-mode 0
  plot num-old-age-deaths

  set-current-plot "Food Availability Percentage"
  set-plot-pen-mode 0
  plot total-food-source

  set-current-plot "Hunger Percentage"
  set-plot-pen-mode 0
  plot total-hunger-level

  if ((num-population = 0) or (ticks >= (24 * max-iterations))) [ stop ]

  let toads-tadpoles (turtle-set toads tadpoles)

  ;;
  ;; HOURLY PROCEDURES
  ;;

  ask toads-tadpoles [
    ;; check on toads and tadpoles if they will die of a natural death (old age / starvation)
    death
    ;; movement for toads and tadpoles
    move
    set hunger-level hunger-level - hunger-deduction-rate
  ]

  ;; reduce the amount chemical levels of patches each day if not already at 0
  ask patches with [ chemical-level > 0 ] [ reduce-chemical-level ]

  ;;
  ;; DAILY PROCEDURES
  ;;

  if ((ticks mod 24) = 0) [

    ;; food replenishment check
    ask foods [ replenish-food ]

    ;; grow egg, tadpole, and toad turtles in size and age
    grow

    let counter 0
    while [ counter <= (int (num-toads / 4)) ] [
      if (random-float 1 <= reproduction-prob) [ reproduce ]
      set counter counter + 1
    ]
  ]

  ;;
  ;; MISCELLANEOUS PROCEDURES (HOURLY)
  ;;

  ;; assign colors to toads and tadpoles turtles according to their hunger level, and food turtles according to their food level
  ask toads-tadpoles [ assign-color-toad ]
  ask foods [ assign-color-food ]
  ask patches with [ chemical-level > 0 ] [
    ;; change water color's shade of blue according to the chemical level
    set pcolor scale-color blue chemical-level 0 5
  ]

  tick
end


to move
  ;; if the toad/tadpole is currently on a patch with any chemical level > 0, go towards a patch with higher concentration
  ifelse (([ chemical-level ] of patch-here) > 0)
  [
    uphill chemical-level
    ifelse (hunger-level <= 0.05)
    [ eat-toad ]
    [ if (any? eggs-here) [ eat-toad ] ]
  ]
  [
    ;; else, move in a random direction if it's not too hungry or...
    ifelse (hunger-level >= 0.7) [
      rt random-float 360
      forward 1
      eat-food
    ]
    ;; seek for a target to eat and move towards it
    [
      turn-to-target
    ]
  ]
end


to turn-to-target
  ;; finds a potential target (a food/toad/tadpole/egg turtle) to eat within given a "sensing range" around the turtle
  let target-food min-one-of (foods in-radius food-radius with [ food-level > 5 ]) [ distance myself ]
  let target-egg min-one-of (eggs in-radius food-radius with [ num-alive > 5 ]) [ distance myself ]                 ;; removed num alive threshold
  let target-tadpole min-one-of (tadpoles in-radius food-radius with [ num-alive > 5 ]) [ distance myself ]
  let target-toad nobody
  ;; only toads can target other toads, even so toads can only target other toads that are at most half their size
  if (breed = toads) [
    set target-toad min-one-of (toads in-radius food-radius with [ toad-size <= [ toad-size ] of myself ]) [ distance myself ]
  ]

  ;; set up cannibal probability

  let cannibal-prob 0
  let chemical-level-here [ chemical-level ] of patch-here

  ;; if turtles are starving they will start to have the urge to eat each other if it means surviving
  if (hunger-level <= 0.3) [ set cannibal-prob min list (((1 - hunger-level)) + ((chemical-level-here / 5))) 1 ]

  ;; whether it is cannibal
  ifelse (random-float 1 < cannibal-prob)
  ; when it is cannibal
  [
    ;; still ignoring most of the toads
    if (random-float 1 < 0.9) [ set target-toad nobody ]
    ;; still ignoring some tadpoles if no chemical present
    if [ chemical-level ] of patch-here = 0 [
      if (random-float 1 < 0.5) [ set target-tadpole nobody ]
    ]
    if ((target-toad != nobody) or (target-tadpole != nobody) or (target-egg != nobody)) [ set target-food nobody ]

  ]
  ;; if they are not cannibals, ignore everything other than food
  [
    set target-toad nobody
    set target-tadpole nobody
    set target-egg nobody
  ]

  ;; determine actual target
  ifelse ((target-food = nobody) and (target-toad = nobody) and (target-tadpole = nobody) and (target-egg = nobody))
  ;; if there are no targets found within the range
  [ rt random-float 360
    forward 1
    ;; so there there is notghing around so nothing can be eaten in this step for sure
  ]
  ;; if there are some targets
  [
    ;; initialize distance to large number
    let to-closest-food 999
    let to-closest-egg 999
    let to-closest-tadpole 999
    let to-closest-toad 999

    ;; get the distance towards the potential target if it exists
    if target-food != nobody [ set to-closest-food distance target-food ]
    if target-egg != nobody [ set to-closest-egg distance target-egg ]
    if target-tadpole != nobody [ set to-closest-tadpole distance target-tadpole ]
    if target-toad != nobody [ set to-closest-toad distance target-toad ]

    ;; face the closest target so that the turtle can move towards it
    ifelse (min (list to-closest-food to-closest-egg to-closest-tadpole to-closest-toad) = to-closest-food)
    ;; if food is the target, face food and eat food
    [
      face target-food
      forward 1
      eat-food
    ]
    ;; if they are not both nobody and the toad is closet, set toad to be the target
    [ ifelse (min (list to-closest-food to-closest-egg to-closest-tadpole to-closest-toad) = to-closest-egg)
      [
        if (to-closest-egg != 0)
        [
          face target-egg
          forward 1
        ]
        eat-toad
      ]
      [ ifelse (min (list to-closest-food to-closest-egg to-closest-tadpole to-closest-toad) = to-closest-tadpole)
        [
          face target-tadpole
          forward 3
          eat-toad
        ]
        [
          face target-toad
          forward 3
          eat-toad
        ]
      ]
    ]
  ]
end


to grow
  ;; the turtle set for all toads, tadpoles, and eggs
  let cane-toads (turtle-set toads tadpoles eggs)
  ;; variables for if eggs are going to hatch
  let to-eggs-hatch? false
  let eggs-list []
  ;; variables for if tadpoles are going to transition into their toad stage
  let to-tadpoles-become-toads? false
  let tadpoles-list []

  ask cane-toads [
    ;; eggs do not grow in size, they only 'grow' by hatching into tadpoles
    if (breed = eggs) [
      if (days-alive = 3) [
        set to-eggs-hatch? true
        set eggs-list lput days-alive eggs-list
        set eggs-list lput num-alive eggs-list
        set eggs-list lput xcor eggs-list
        set eggs-list lput ycor eggs-list

        ;; once hatched, the egg turtle will be removed as tadpole turtles are created in their place
        die
      ]
    ]

    ;; tadpoles' size are not considered in this simulation, only their 'growth' when transforming into toads
    if (breed = tadpoles) [
      ;; tadpole transitions into a toad
      if (days-alive = tadpole-to-toad-days) [
        set to-tadpoles-become-toads? true

        set tadpoles-list lput days-alive tadpoles-list
        set tadpoles-list lput num-alive tadpoles-list
        set tadpoles-list lput xcor tadpoles-list
        set tadpoles-list lput ycor tadpoles-list

        ;; once hatched, the tadpole turtle will be removed as toad turtles are created in their place
        die
      ]
    ]

    if (breed = toads) [
      ;; toads only grow if they aren't at their maximum size
      if (toad-size < max-size) [
        let new-size toad-size + (random-normal 0.035 0.005)
        ;; makes sure the toad's size does not go over the limit after growing
        set toad-size min list max-size new-size
      ]
    ]
    set days-alive days-alive + 1
  ]

  if (to-eggs-hatch? = true) [
    let counter 0
    while [ counter < (int (length eggs-list) / 4) ] [
      let curr-days-alive (item (counter * 4) eggs-list)
      let curr-num-alive (item ((counter * 4) + 1) eggs-list)
      let curr-xcor (item ((counter * 4) + 2) eggs-list)
      let curr-ycor (item ((counter * 4) + 3) eggs-list)

      ;; create tadpole turtles where each one represents 100 tadpoles from the same amount and coordinates as the removed egg turtle
      create-tadpoles (int (curr-num-alive / 100)) [
        setxy curr-xcor curr-ycor
        set num-alive 100
        set days-alive curr-days-alive
        set tadpole-to-toad-days int random-normal 42 10
        set hunger-level 0.8

        set shape "exclamation"
        assign-color-toad
      ]
      set counter counter + 1
    ]
  ]

  if (to-tadpoles-become-toads? = true) [
    let counter 0
    while [ counter < (int (length tadpoles-list) / 4) ] [
      let curr-days-alive (item (counter * 4) tadpoles-list)
      let curr-num-alive (item ((counter * 4) + 1) tadpoles-list)
      let curr-xcor (item ((counter * 4) + 2) tadpoles-list)
      let curr-ycor (item ((counter * 4) + 3) tadpoles-list)

      ;; create num-alive number of toads (max is 100 if none of the tadpoles are eaten) from the same amount and coordinates as the removed tadpole turtle
      create-toads curr-num-alive [
        setxy curr-xcor curr-ycor
        set days-alive curr-days-alive
        set life-span random-normal 6000 400
        set max-size random-normal 12.5 1
        set toad-size random-normal 0.75 0.05
        set hunger-level 0.5

        set shape "frog top"
        assign-color-toad
      ]
      set counter counter + 1
    ]
  ]
end


to reproduce
  let x 0
  let y 0
  ;; get the x and y coordinate of a patch to lay the eggs at
  ask one-of patches [
    set x pxcor
    set y pycor
  ]
  create-eggs 1 [
    setxy x y
    set num-alive int random-normal mean-eggs-laid 2000
    set days-alive 1

    set shape "egg"
    set size 1
    set color white
  ]
end


to replenish-food
  ;; all food patches have the same maximum amount of food, only replenish when food level is not capped
  if (food-level < max-food) [
    let replenish food-level + replenishment-rate
    ;; makes sure the food level does not go over the limit after replenishing
    set food-level min list replenish max-food
  ]
end


to death
  ;; death by old age
  if (breed = toads) [
    if (days-alive > life-span) [
      set num-old-age-deaths (num-old-age-deaths + 1)
      die
    ]
  ]

  ;; death by starvation
  if (hunger-level <= 0) [
    set num-starving-deaths (num-starving-deaths + 1)
    die
  ]
end


to reduce-chemical-level
  ;; chemical levels will decrease every tick by a specified rate
  set chemical-level chemical-level - chemical-level-deduction-rate
  ;; makes sure the chemical level does not go below zero
  set chemical-level max list chemical-level 0

  ;; if chemical level returns to normal change patch color back to blue
  if (chemical-level = 0) [
    set max-chemical-limit 0
    set pcolor black
  ]
end


;; will eat its own kind if there is one (egg/tadpole/toad), if there are none of its kind, only then check for food sources
to eat-toad
  let increase-hunger-level 0
  let release-chemical? false
  let release-chemical-patch one-of patches

  if (breed = toads) [
    ;; prioritise eggs as they are the least likely food source to run out
    ifelse (any? eggs-here) [
      let num-eggs-left 0
      let num-eggs-eaten 0

      let eaten-egg one-of eggs-here
      ask eaten-egg [
        set num-eggs-left num-alive
      ]

      set num-eggs-eaten min list (int toad-size * 2.5) num-eggs-left
      set increase-hunger-level (num-eggs-eaten * 0.2 / toad-size)

      ask eaten-egg [
        set num-alive max list (num-alive - num-eggs-eaten) 0
        if (num-alive = 0) [ die ]
      ]

      set release-chemical? true
      set release-chemical-patch patch-here
      set num-cannibal-deaths (num-cannibal-deaths + num-eggs-eaten)
      set num-cannibal-deaths-eggs (num-cannibal-deaths-eggs + num-eggs-eaten)
    ]
    ;; then tadpoles, as they are still easier to eat than other toads
    [ ifelse (any? tadpoles-here) [
        let num-tadpoles-left 0
        let num-tadpoles-eaten 0

        let eaten-tadpole one-of tadpoles-here
        ask eaten-tadpole [ set num-tadpoles-left num-alive ]

        set num-tadpoles-eaten min list (int toad-size * 1.25) num-tadpoles-left
        set increase-hunger-level (num-tadpoles-eaten * 0.8 / (toad-size / 0.5))

        ask eaten-tadpole [
          set num-alive max list (num-alive - num-tadpoles-eaten) 0
          if (num-alive = 0) [ die ]
        ]

        set num-cannibal-deaths (num-cannibal-deaths + num-tadpoles-eaten)
        set num-cannibal-deaths-tadpoles (num-cannibal-deaths-tadpoles + num-tadpoles-eaten)
      ]
      [ let eating-toad-size toad-size
        ;; again, check if the potential target toad is at most a fifth the size of the eating toad
        if (any? toads-here with [ toad-size <= (eating-toad-size / 5) ]) [
          let eaten-toad one-of toads-here with [ toad-size <= (eating-toad-size / 5) ]
          set increase-hunger-level (([ toad-size ] of eaten-toad) / eating-toad-size)
          ask eaten-toad [ die ]

          set num-cannibal-deaths (num-cannibal-deaths + 1)
          set num-cannibal-deaths-toads (num-cannibal-deaths-toads + 1)
        ]
      ]
    ]
  ]

  ;; tadpoles can only eat eggs and other tadpoles
  if (breed = tadpoles) [
    ifelse (any? eggs-here) [
      let num-eggs-left 0
      let num-eggs-eaten 0

      let eaten-egg one-of eggs-here
      ask eaten-egg [
        set num-eggs-left num-alive
      ]

      ;; each tadpole (num-alive) in the tadpole turtle will eat 1.25-2 eggs, or share the remaining amount of eggs from an egg turtle
      set num-eggs-eaten min list (int num-alive * (1.25 + random-float 1)) num-eggs-left
      set increase-hunger-level (num-eggs-eaten * 0.2 / (num-alive / 3.25))

      ask eaten-egg [
        set num-alive max list (num-alive - num-eggs-eaten) 0
        if (num-alive = 0) [ die ]
      ]

      set release-chemical? true
      set release-chemical-patch patch-here
      set num-cannibal-deaths (num-cannibal-deaths + num-eggs-eaten)
      set num-cannibal-deaths-eggs (num-cannibal-deaths-eggs + num-eggs-eaten)
    ]
    ;; when it comes to eating other tadpoles size is not compared
    [
      let tadpole-num-alive num-alive
      let eating-tadpole self
      let num-tadpoles-eaten (tadpole-num-alive - num-alive)

      ;; only eat each other if there are no food sources in the patch with enough food for each tadpole (1 each)
      ifelse (any? tadpoles-here with [ self != eating-tadpole ])
      [
        let eaten-tadpoles one-of tadpoles-here with [ self != eating-tadpole ]
        set num-tadpoles-eaten int ((1.25 + random-float 0.75) * tadpole-num-alive)
        set num-tadpoles-eaten min list num-tadpoles-eaten ([ num-alive ] of eaten-tadpoles)
        set increase-hunger-level (num-tadpoles-eaten / tadpole-num-alive) / 8

        ask eaten-tadpoles [
          set num-alive num-alive - num-tadpoles-eaten
          if (num-alive = 0) [ die ]
        ]
      ]
      [
        if (num-alive > 2) [
          set increase-hunger-level ((max list hunger-level 0.5) / 4)
          set num-alive int (num-alive * (max list hunger-level 0.5))
          set num-tadpoles-eaten (tadpole-num-alive - num-alive)
        ]
      ]

      set num-cannibal-deaths (num-cannibal-deaths + num-tadpoles-eaten)
      set num-cannibal-deaths-tadpoles (num-cannibal-deaths-tadpoles + num-tadpoles-eaten)
    ]
  ]

  if (release-chemical? = true)
  [
    ;; increase chemical level of this patch by 1
    set chemical-level chemical-level + 1
    set chemical-level min list chemical-level 5
    let origin-patch release-chemical-patch

    ;; diffuse chemical levels to other nearby water patches within a radius
    ask origin-patch [
      ask patches in-radius 6 [
        ifelse (self != origin-patch)
        [
          if ((5 * (1 / distance myself)) > max-chemical-limit) [ set max-chemical-limit (5 * (1 / (distance myself + 1))) ]
          set chemical-level chemical-level + (2 * (1 / (distance myself + 1)))
          set chemical-level min list chemical-level max-chemical-limit
        ]
        [
          set max-chemical-limit 5
          set chemical-level chemical-level + (2 * 1)
          set chemical-level min list chemical-level max-chemical-limit
        ]
      ]
    ]
  ]

  ;; increase hunger would only remain as 0 if there are no potential egg/tadpole/toad targets to eat, will move on to target food
  ifelse (increase-hunger-level != 0) [
    set hunger-level hunger-level + increase-hunger-level
    set hunger-level min list hunger-level 1
  ]
  [ eat-food ]
end


to eat-food
  ;; check if there is a food source in this patch with food
  if any? foods-here with [ food-level > 0 ] [
    let curr-food one-of foods-here
    ifelse (breed = toads) [
      let decrease-food-level min list (toad-size * 2) ([ food-level ] of curr-food)
      ask curr-food [ set food-level food-level - decrease-food-level ]

      set hunger-level hunger-level + (decrease-food-level / (toad-size / 0.05))
      set hunger-level min list hunger-level 1
    ]
    [ if (breed = tadpoles) [
        let decrease-food-level min list (num-alive * 0.25) ([ food-level ] of curr-food)
        ask curr-food [ set food-level food-level - decrease-food-level ]

        set hunger-level hunger-level + (decrease-food-level / (num-alive / 0.4))
        set hunger-level min list hunger-level 1
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
283
56
854
628
-1
-1
11.04
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks
30.0

BUTTON
993
72
1059
105
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1069
72
1150
105
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1161
72
1224
105
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
877
72
980
105
clear
clear
1
1
-1000

SLIDER
22
81
269
114
initial-toads
initial-toads
0
250
250.0
50
1
toads
HORIZONTAL

SLIDER
22
153
267
186
num-food-patches
num-food-patches
0
250
250.0
50
1
patches
HORIZONTAL

SLIDER
24
258
270
291
max-food
max-food
0
5000
1000.0
50
1
units
HORIZONTAL

SLIDER
23
413
269
446
food-radius
food-radius
0
50
15.0
1
1
pixels
HORIZONTAL

TEXTBOX
23
64
173
82
Initialisation\n
11
0.0
1

TEXTBOX
29
200
179
218
Variables
11
0.0
1

SLIDER
23
218
271
251
max-iterations
max-iterations
0
366
183.0
183
1
days
HORIZONTAL

SLIDER
23
298
270
331
replenishment-rate
replenishment-rate
0
50
50.0
5
1
units
HORIZONTAL

SLIDER
24
374
269
407
mean-eggs-laid
mean-eggs-laid
2500
30000
12500.0
500
1
NIL
HORIZONTAL

SLIDER
23
336
270
369
reproduction-prob
reproduction-prob
0
0.05
0.01
0.005
1
batches / year
HORIZONTAL

SLIDER
22
451
270
484
hunger-deduction-rate
hunger-deduction-rate
0
0.01
0.01
0.0005
1
/ hour
HORIZONTAL

SLIDER
23
490
269
523
chemical-level-deduction-rate
chemical-level-deduction-rate
0
1
0.7
0.05
1
/ hour
HORIZONTAL

PLOT
19
645
367
800
Total Population
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
20
968
366
1121
Number of Cannibalistic Deaths
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
995
804
1279
963
Number of Deaths from Hunger
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
995
967
1279
1121
Number of Deaths from Old Age
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
371
645
708
801
Number of Cannibalistic Egg Deaths
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
371
804
708
964
Number of Cannibalistic Tadpole Deaths
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
371
968
707
1121
Number of Cannibalistic Toad Deaths
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
876
128
1259
340
Food Source vs Cannibal Death
time
value
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"total food" 1.0 0 -16777216 true "" "plot total-food-source / 100"
"cannibal deaths ratio" 1.0 0 -13345367 true "" "plot (num-cannibal-deaths / ( num-starving-deaths + num-old-age-deaths + num-cannibal-deaths + 0.00001)) * 1000"
"population size" 1.0 0 -2674135 true "" "plot num-population / 100"
"total hunger level" 1.0 0 -15302303 true "" "plot total-hunger-level "

MONITOR
876
354
989
399
NIL
num-old-age-deaths
17
1
11

MONITOR
879
524
1043
569
NIL
num-cannibal-deaths / ticks
17
1
11

MONITOR
880
573
978
618
NIL
num-population
17
1
11

MONITOR
877
409
1052
454
no of toads looking for target
(count (toads with [hunger-level < 0.7])) + (count (tadpoles with [hunger-level < 0.7]))
17
1
11

MONITOR
994
354
1064
399
egg death
num-cannibal-deaths-eggs
17
1
11

MONITOR
1068
354
1137
399
eggs alive
sum [num-alive] of eggs
17
1
11

MONITOR
1057
409
1157
454
starving deaths
num-starving-deaths
17
1
11

MONITOR
878
459
1030
504
no of toads may be cannibal
(count (toads with [hunger-level < 0.3])) + (count (tadpoles with [hunger-level < 0.3]))
17
1
11

MONITOR
1035
459
1102
504
total food
total-food-source
17
1
11

MONITOR
1115
459
1196
504
total hunger
total-hunger-level
17
1
11

MONITOR
1051
523
1192
568
cannibal ratio
((count (toads with [hunger-level < 0.3])) + (count (tadpoles with [hunger-level < 0.3])))/ num-population
17
1
11

PLOT
994
644
1278
800
Hunger Percentage
time
%
0.0
1.0
0.0
1.0
true
true
"" ""
PENS

PLOT
20
804
367
964
Food Availability Percentage
time
%
0.0
1.0
0.0
1.0
true
true
"" ""
PENS

PLOT
713
967
990
1121
Toad Population
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
712
804
989
964
Tadpole Population
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
712
644
988
800
Egg Population
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

SLIDER
22
117
268
150
initial-tadpoles
initial-tadpoles
0
25000
25000.0
5000
1
tadpoles
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

egg
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148

exclamation
false
0
Circle -7500403 true true 103 198 95
Polygon -7500403 true true 135 180 165 180 210 30 180 0 120 0 90 30

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

frog top
true
0
Polygon -7500403 true true 146 18 135 30 119 42 105 90 90 150 105 195 135 225 165 225 195 195 210 150 195 90 180 41 165 30 155 18
Polygon -7500403 true true 91 176 67 148 70 121 66 119 61 133 59 111 53 111 52 131 47 115 42 120 46 146 55 187 80 237 106 269 116 268 114 214 131 222
Polygon -7500403 true true 185 62 234 84 223 51 226 48 234 61 235 38 240 38 243 60 252 46 255 49 244 95 188 92
Polygon -7500403 true true 115 62 66 84 77 51 74 48 66 61 65 38 60 38 57 60 48 46 45 49 56 95 112 92
Polygon -7500403 true true 200 186 233 148 230 121 234 119 239 133 241 111 247 111 248 131 253 115 258 120 254 146 245 187 220 237 194 269 184 268 186 214 169 222
Circle -16777216 true false 157 38 18
Circle -16777216 true false 125 38 18

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
