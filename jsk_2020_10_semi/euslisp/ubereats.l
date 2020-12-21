#!/usr/bin/env roseus

;; load robot and scene model
(require "package://fetcheus/fetch-utils.l")
(require "package://fetcheus/fetch-interface.l")
(require "package://jsk_maps/src/eng2-scene.l")

(load "utils.l")
(load "add-co.l")

(unless (boundp '*scene*)
  (setq *scene* (make-eng2-7f-scene)))
(unless (boundp '*ri*)
  (fetch-init)) ;; fetch-init instantiate *fetch* and *ri*

;; show in irtviewer
(objects (list *fetch* *scene*))
;; show in "fetch Kinematics Simulator"
(send *ri* :objects (send *scene* :objects))


;; check 20201026-soft3-model, the code to focus on the robot model
(send *irtviewer* :look-all
      (send (geo::make-bounding-box
             (flatten (send-all (send *fetch* :bodies) :vertices)))
            :grow 2.0))

;; reset-pose
(reset-pose)

;; move to in front of 73A3
(move-to-place "/eng2/7f/room73A3-front")
(send *ri* :wait-interpolation)

; door knob recognition
(setq *door-knob* (send (send (send (send (send (send (send *scene* :object "/eng2/7f/73a3") :object "room73a3-door-right") 
  :handle-rear-knob) :copy-worldcoords) :locate #f(200 0 0)) :rotate pi :z) :rotate -pi/2 :y))
; (send *door-knob* :draw-on :flush t :size 1000 :color #f(0 1 0)))
(setq *door-knob-base* 
  (send (send (send (send *door-knob* :copy-worldcoords) :rotate pi/2 :x) :rotate -pi/2 :z) :locate (float-vector -600 -200 ( - (elt (send *door-knob* :worldpos) 2 )))))
; (send *door-knob-base* :draw-on :flush t :size 1000 :color #f(1 0 0)))
; (objects (list *fetch* *scene* *door-knob* *door-knob-base*))
; (send *ri* :objects (send *scene* :objects))

;; move to in front of door knob
(move-to-coord *door-knob-base*)

; right of the fetch
(setq *box* (send (send (send (send *fetch* :copy-worldcoords) :locate #f(-100 -500 900)) :rotate pi/2 :z) :rotate pi/2 :y))
(setq *bento* (send (send *box* :copy-worldcoords) :locate #f(700 0 0)))
(if (boundp '*co*)
  (add-box -100 -540 0))

;; set coords
(setq *door-knob2-right* 
  (send (send (send (send *fetch* :copy-worldcoords) 
    :transform (make-coords :pos (float-vector 500 0 (elt (send *door-knob* :worldpos) 2)))) :rotate pi/2 :z) :rotate -pi/2 :x))
(setq *door-knob3-right* (send (send 
    (send *door-knob2-right* :copy-worldcoords) :locate #f(0 0 -100)) :rotate (/ pi 6) :y))
(setq *door-knob3* (send (send 
    (send *door-knob2-right* :copy-worldcoords) :locate #f(200 0 -100)) :rotate (/ pi 6) :y))
(if (boundp '*co*)
  (add-door (+ (- (elt (send *door-knob3* :worldpos) 0) (elt (send *fetch* :worldpos) 0)) 50)))

; grasp bento
(look-at-coord *bento* 5000 t)
(ik-coord *box* 5000)
(ik-coord *bento* 3000)
(send *ri* :start-grasp :effort 60)
(unix:sleep 1)
(ik-coord *box* 3000)

; hang on the knob
(look-at-coord *door-knob3* 3000 t)
(ik-coord *door-knob3-right* 5000)
(unix:sleep 1)
(ik-coord *door-knob3* 3000)
(send *ri* :stop-grasp :effort 60)
(unix:sleep 3)
(look-at-coord *door-knob3-right* 3000 t)
(ik-coord *door-knob3-right* 2000)
(ik-coord *door-knob2-right* 1000)

(move-waist 100.0)
(reset-pose 7000)
(if (boundp '*co*)
  (progn (del-door)
      (del-box)))