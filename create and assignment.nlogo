

globals [
  ;==============input/output/goal related===================
  time
  csv
  fileList ;
  width      ; the width of the patches
  height     ; the height of the patches
  color-list ; a list of color for agents
  goal       ; the goal pattern


  ;==============drawing related attributes==============
  drawing-type; the drawing effect of one action by the agent


  ;==============buttons related attributes==============
  ;assign;the type of drawings assign to an agent.
;  noise ; the randomly set points in each button that belongs to solution.
;  buttons; a list of buttons, each button is a pair setting some patches to green and some to black
;  button-chosen; the (index of the) button choosen to be pressed in current hour. For day 0, hour 0, it is randomly choosen
;  buttons-chosen-before; all the buttons chosen before

  ;==============time related attributes==================
;  num-hours  ; the length of solution
;  day        ; the day
;  hour       ; the hour
;  ticks-per-hour; totoal number of ticks per day. It may vary from hour to hour
;  succeed-initialise-game; an attribute to indicate the beginning of the game

  ;==============status and planning=======================
  trying ;a sign of status if the agents are trying or bidding
;  bidding ; for each action, we record a value
;  bidding-day; total amount of days where buttons are chosen by bidding

  ;==============other attributes==================
;  can-walk ; if the agent can move around. In this game, the agents are assumed to be able to
  ]




turtles-own[
  ;======================beliefs===================================================================
  own-color; color set to the agent
  drawing-type-assigned;the type of drawing an agent will act for one action.

;  buttons-assigned; the order of buttons it owns, relating to the matrix buttons
;  observation ; the agent's observation
;  action-knowledge; knowledge about the actions. each action is a pair: (know-true, know-false).
  ; know-true consists of the propositions the agent is sure about.
  ; know false consists of the propositions the agent knows not going to be the case.
;  personal-plan;
;  button-owners;agents' belief about the owner of each buttons
;  pattern-and-plan; when the learning for this pattern finishes, the agent store the pattern and the corresponding personal plan
  ;======================desire====================================================================
  ; the agent has the desire to maximise the knowledge of the buttons it is in charge of
  ; to stop itself when informed
  desire; the agent is aiming at a stop when the pattern was reached (and the agent will be informed)
  ;======================intention=================================================================
  ; to move to a location and to bid
  ; and to bid for an action (not necessarily to press its buttons)
  intention
  ; and the following are related variables
  best-node ;a data structure containing the best action and the bidding value (as well as the plan)
  target-patch
  know-buttons-in-charge; the percentage of the knownledge each agent acuired for the button(s) it in charge of.
  ;
]


patches-own[
  potential-infor;if the agent is at that patch, with its set vision, the amount of information it at most may get.
  ]
;==========================================================================================
; to load the goal pattern

to open-file

  file-open pattern-name
  set goal list [] []
  let delim ","

  set csv file-read-line
  let tmp split csv delim

  set width read-from-string item 0 tmp

  set height read-from-string item 1 tmp
  set-patch-size 400 / width
  resize-world 0 (width - 1) 0 ( height - 1)

  let x 0
  let y height - 1
  output-print "Goal:"
  while [not file-at-end?]
  [
    set csv file-read-line

    output-print csv
    set tmp split csv delim
    foreach tmp
    [
      let positive first goal
      let negative last goal

      ifelse (? = "1")
      [
        ; ask patch x y [set pcolor green]
        ; positive
        set goal (list (fput (x + y * width + 1 ) positive) negative)
        set x x + 1
        if (x = width)
        [
          set x 0
          set y y - 1
        ]
      ]
      [if (? = "0")
        [
          ; negative
          set goal (list positive (fput (x + y * width + 1 ) negative))
          set x x + 1
          if (x = width)
          [
            set x 0
            set y y - 1
          ]
        ]
      ]
    ]
  ]
  output-print "============================"
  file-close
end

to-report split [ string delim ]
  report reduce [
    ifelse-value (?2 = delim)
      [ lput "" ?1 ]
      [ lput word last ?1 ?2 but-last ?1 ]
  ] fput [""] n-values (length string) [ substring string ? (? + 1) ]
end

; to load and display the goal
to load-and-display-goal
  clear-all
  open-file
  foreach (first goal) [
    let x getx ?
    let y gety ?
    ask patch x y [set pcolor green]
    ]
end
; =================================================================
; ========================== The Setup part =======================
; =================================================================

breed [drawings drawing]
breed [erasers eraser]

to setup-patches
  ask patches[
    set pcolor black
;    set pcolor one-of [green brown];just for debugging

    ]


end

to locate
;  setxy ((random (width - 2)) + 1 ) ((random (width - 2)) + 1 )
  setxy random-xcor random-ycor
  face patch-here
  move-to patch-here
  ;always set the agents faceing up
  ifelse( (gety abs(get-patch-index patch-here )) != width - 1 );if agents not reside on the upper boundary.
  [face patch getx (abs(get-patch-index patch-here )+ width) gety (abs(get-patch-index patch-here) + width)];face up
  [face patch getx (abs(get-patch-index patch-here )- width) gety (abs(get-patch-index patch-here) - width)
   right 180
    ];face down, and then up.

end

to setup-agents
  create-drawings num-drawings [

  setxy random-xcor random-ycor
;  set shape "circle"
  locate
  ]
  create-erasers num-erasers [
    set color white
    set shape "square"
    set size 1
    locate

  ]


end


to setup-ticks
  reset-ticks
;  set ticks-per-hour 0
;  if (can-walk) [set ticks-per-hour (ticks-per-hour + 1)]

;  set ticks-per-hour (ticks-per-hour + 1); to locate to a patch on the first hour of a day
;  set ticks-per-hour (ticks-per-hour + 4); 4 sticks corresponding to: bid, observe, execute, learn
end
to setup

  ;set noise 12; the randomly set points in each button that belongs to solution.
  ; set noise-dis 8; the randomly set points in each button that not belongs to solution.

  set color-list n-of num-drawings [yellow magenta blue red pink brown grey];just for the sake of telling each agent apart
;  set succeed-initialise-game false
;  set can-walk true
  setup-ticks
;  open-file; set up the goal pattern.
;  setup-time
;  setup-button
  setup-agents
;  assign-buttons
;  show-vision;show the agents' vision by * mark.
;  setup-bidding
  setup-patches
;  setup-drawings
  assign-drawings
;  set trying true
;  set time 0
  reset-timer
end



to setup-drawings

  ask turtles[

  ifelse(drawing-type-assigned = 0)
  [ask patch-here [set pcolor black]];eraser
  [
    ifelse( drawing-type-assigned = 1)
;  ask drawings[
;    ask patch-ahead 1 [set pcolor green]
    [ask patches in-cone-nowrap 1 360[set pcolor green];type 1
    ]
    [ifelse( drawing-type-assigned = 2)
      [ask patches in-cone-nowrap 1 360[set pcolor green];type 2
        if(patch-right-and-ahead 135 1.5 != nobody)
        [ask patch-right-and-ahead 135 1.5 [ set pcolor green ]]
        if(patch-right-and-ahead 135 2.8 != nobody)
        [ask patch-right-and-ahead 135 2.8 [ set pcolor green ]]
        if(patch-right-and-ahead 45 1.5 != nobody)
        [ask patch-left-and-ahead 45 1.5 [ set pcolor green ]]
      ]
      [ask patches in-cone-nowrap 1.5 360[set pcolor green];type 3
      ]

    ]
  ]

  ]
end

to assign-drawings; to assign different types of drawing to agents randomly.
  ask erasers[set  drawing-type-assigned 0]
  ask drawings[ set drawing-type-assigned ( 1 + random 3 )]
end


to perform-action
  ask drawings[setup-drawings]
  ask erasers[setup-drawings]

end



;=============================================================================================
; check if the goal is reached. If reached, the game will terminates.
; The goal should not be reached when the agents are trying
to-report check-goal ; check if the current situation is the same as the goal
  let sign true
  foreach (first goal)[
    let x getx ?
    let y gety ?
    if (not (([pcolor] of (patch x y)) = green))[set sign false]
    ]
  foreach (last goal)[
    let x getx ?
    let y gety ?
    if (([pcolor] of (patch x y)) = green)[set sign false]
    ]
  if (trying) [report false]
  report sign
end

; two helping function to get the xcor and ycor of the patch according to its index
to-report getx [n]

   report (remainder (n - 1) width)
end

to-report gety [n]
  report ( floor ((n - 1) / width))
end

to-report get-patch-index [p]
  ifelse ([pcolor] of p = green) [report ([pycor] of p * width + [pxcor] of p) + 1]
  [report ([pycor] of p * width + [pxcor] of p + 1 ) * -1]
end
@#$#@#$#@
GRAPHICS-WINDOW
285
21
695
452
-1
-1
33.333333333333336
1
10
1
1
1
0
0
0
1
0
11
0
11
0
0
1
ticks
30.0

CHOOSER
48
42
186
87
pattern-name
pattern-name
"test1.txt" "test2.txt" "smile.txt" "sad.txt" "pi.txt"
2

BUTTON
0
97
225
130
load-and-display-goal
load-and-display-goal
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
6
152
167
185
clear displace
ask patches [set pcolor black]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1
194
251
227
improvement-parameter
improvement-parameter
0
5
3
1
1
NIL
HORIZONTAL

SLIDER
24
300
196
333
num-erasers
num-erasers
1
1
1
1
1
NIL
HORIZONTAL

BUTTON
808
56
886
89
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

SLIDER
28
360
223
393
num-drawing-types
num-drawing-types
1
4
3
1
1
NIL
HORIZONTAL

BUTTON
764
97
925
130
NIL
setup-drawings
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
31
241
203
274
num-drawings
num-drawings
1
4
2
1
1
NIL
HORIZONTAL

SLIDER
23
435
218
468
drawing-paramer
drawing-paramer
1
3
1
1
1
NIL
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
NetLogo 5.3
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
