(module
  (global $width (import "js" "width") i32)
  (global $height (import "js" "height") i32)
  (global $bytecolordepth (import "js" "bCD") i32)

  (import "js" "mem_pages" (memory $mem 1))

  ;;(memory (export "screenbuf") $mem_pages) Not needed we now define liner memory in JS to size with canvas

  (table 9 anyfunc)
  (elem (i32.const 0)
    $solidcolorred
    $solidcolorblue
    $mapcolorXOR
    $mapcolorRND
    $mapnoiseredshift
    $mapsmoothnoisecolorX
    $mapsmoothnoisecolorXY
    $fractalzoom  
    $coloroverlay  
  )

  (global $step (mut i32) i32.const 0)
  (global $movementstep (mut i32) i32.const 0)
  (global $xorshiftstate (mut i32) i32.const 0xFA1922DC) ;; State of sudo random gen. Here we initialize with seed value as well.
  
  (func $add (param $lhs i32) (param $rhs i32) (result i32)
    get_local $lhs
    get_local $rhs
    i32.add)
  (export "add" (func $add))
  
  (func $increment (param $lhs i32) (result i32)
    get_local $lhs
    i32.const 1
    i32.add
  )

  
  (func $clamp (param $val i32) (param $min i32) (param $max i32) (result i32)  

    (if (result i32)
      (i32.gt_s
        (get_local $val)
        (get_local $max)
      )
      (then
        (get_local $max)
      )
      (else
    
        (if (result i32)
          (i32.lt_s
            (get_local $val)
            (get_local $min)
          )
          (then
            (get_local $min)
          )
          (else
            (get_local $val) 
          )
        )
      )    
    ) 
  )

;;  uint32_t xorshift32(struct xorshift32_state *state)
;;{
;;	/* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
;;	uint32_t x = state->a;
;;	x ^= x << 13;
;;	x ^= x >> 17;
;;	x ^= x << 5;
;;	return state->a = x;
;;}

(func $xorshift32 (result i32)
  get_global $xorshiftstate
  get_global $xorshiftstate
  i32.const 13
  i32.shl
  i32.xor
  set_global $xorshiftstate
  
  get_global $xorshiftstate
  get_global $xorshiftstate
  i32.const 17
  i32.shr_u
  i32.xor
  set_global $xorshiftstate

  get_global $xorshiftstate
  get_global $xorshiftstate
  i32.const 5
  i32.shl
  i32.xor
  set_global $xorshiftstate

  get_global $xorshiftstate
)


  (func $setpix (param $x i32) (param $y i32) (param $color i32)
    get_global $width
    get_local $y
    i32.mul
    get_local $x
    i32.add
    get_global $bytecolordepth
    i32.mul
    get_local $color
    i32.store
  )

  (func $getpix (param $x i32) (param $y i32) (result i32)
    get_global $width
    get_local $y
    i32.mul
    get_local $x
    i32.add
    get_global $bytecolordepth
    i32.mul
    i32.load
  )

  (func $mapcolorXOR (param $x i32) (param $y i32) (result i32)
    (i32.or (i32.shl (i32.xor (get_local $x) (get_local $y)) (get_global $step)) (i32.const 0xff000000))
  )

  (func $mapcolorRND (param $x i32) (param $y i32) (result i32)
    (i32.or (call $xorshift32) (i32.const 0xff000000))
    ;;(call $xorshift32)
  )


  (func $mapnoiseredshift (param $x i32) (param $y i32) (result i32)
    (call $xorshift32)
    i32.const 18
    i32.shr_u
    i32.const 0x00000088
    i32.add
    i32.const 0xff000000
    i32.or
  )

  (func $mapsmoothnoisecolorX (param $x i32) (param $y i32) (result i32)
    (call $xorshift32)
    i32.const 26
    i32.shr_u
  
    (if (result i32)(i32.gt_s (get_local $x) (i32.const 0)) 
      (then 
        get_local $x
        i32.const 1
        i32.sub
        get_local $y
        (call $getpix)
        ;;i32.const 1
        ;;i32.shr_u
      )
      (else i32.const 0)
    )

    i32.add
    i32.const 0xff000000
    i32.or
  )

    (func $mapsmoothnoisecolorXY (param $x i32) (param $y i32) (result i32)
    (call $xorshift32)
    i32.const 26
    i32.shr_u
  
    (if (result i32)(i32.gt_s (get_local $x) (i32.const 0)) 
      (then 
        get_local $x
        i32.const 1
        i32.sub
        get_local $y
        (call $getpix)
        i32.const 4
        ;;get_global $step
        i32.shr_u
      )
      (else i32.const 0)
    )

    (if (result i32)(i32.gt_s (get_local $y) (i32.const 0)) 
      (then 
        get_local $x
        get_local $y
        i32.const 1
        i32.sub
        (call $getpix)
        i32.const 4
        ;;get_global $step
        i32.shr_u
      )
      (else i32.const 0)
    )
    i32.add
    i32.add
    i32.const 0xff000000
    i32.or
  )

  (func $coloroverlay  (param $x i32) (param $y i32) (result i32)
    (call $getpix (get_local $x) (get_local $y))
    i32.const 5
    i32.shr_u
    i32.const 0xff000000
    i32.or
  )

  (func $fractalzoom  (param $x i32) (param $y i32) (result i32)

    (get_local $x)
    f32.reinterpret/i32
    f32.const 0.75
    f32.mul
    i32.reinterpret/f32

    (get_local $y)
    f32.reinterpret/i32
    f32.const 0.75
    f32.mul
    i32.reinterpret/f32    

    (call $getpix)
  )

  (func $solidcolorred  (param $x i32) (param $y i32) (result i32)
   i32.const 0xFF0000FF
  )

  (func $solidcolorblue  (param $x i32) (param $y i32) (result i32)
    i32.const 0xFFFF0000
  )

 
  (func $loopcol (param $y i32) (param $mf i32)(param $width i32) (param $xoffset i32)
    (local $x i32)
    (set_local $x (get_local $xoffset))

    
    (block 
      (loop
         
        (call $setpix (get_local $x) (get_local $y) (call_indirect (param i32) (param i32) (result i32) (get_local $x) (get_local $y) (get_local $mf)))

        (set_local $x (call $increment (get_local $x)))
        (br_if 1 (i32.eq (get_local $x) (get_local $width)))
        (br 0)
      )
    )
  )

  (func $looprow (param $mf i32) (param $width i32) (param $height i32) (param $xoffset i32) (param $yoffset i32) 
    (local $y i32)
    (set_local $y (get_local $yoffset))

    (block 
      (loop
         
        (call $loopcol (get_local $y) (get_local $mf) (get_local $width)(get_local $xoffset))
        (set_local $y (call $increment (get_local $y)))
      
        (br_if 1 (i32.eq (get_local $y) (get_local $height)))
        (br 0)
      )
    )
  )


  (func $main (param $mapfunc i32) (result i32)
    (local $xoffset i32)

    i32.const 50
    set_local $xoffset

    ;;get_global $step
    ;;set_global $xorshiftstate

    ;; Background layer
    (call $looprow (get_local $mapfunc) (get_global $width) (get_global $height) (i32.const 0) (i32.const 0))
    
    ;; Foreground layer 1
    (call $looprow (i32.const 7) (i32.add (i32.mul (get_global $step) (i32.const 8)) (i32.const 400)) (i32.add (i32.mul (get_global $step) (i32.const 8)) (i32.const 400)) (get_local $xoffset) (i32.const 50))

    ;; Scroll layer
    (call $looprow (i32.const 8) (i32.add (get_global $movementstep) (i32.const 400)) (i32.const 400) (i32.add (get_global $movementstep)(get_local $xoffset)) (i32.const 50))
    
    ;; step is used to produce different frames for an animation sequence by some image generator functions 
    (set_global $step (call $increment (get_global $step)))
    (if 
      (i32.gt_u
        (get_global $step)
        (i32.const 16)
      )
      (then
        (set_global $step (i32.const 0))
      )
    ) 

    ;; step is used to produce different frames for an animation sequence by some image generator functions 
    (set_global $movementstep (call $add (get_global $movementstep)(i32.const 40)))
    (if 
      (i32.gt_u
        (get_global $movementstep)
        (get_global $width)
      )
      (then
        (set_global $movementstep (i32.const 0))
      )
    ) 

    ;; manual testing calls
    (call $setpix (i32.const 5) (i32.const 0) (i32.const 0xffff0000))
    i32.const 0
    i32.const 0xff0000ff
    i32.store
    i32.const 0
    i32.load
  )
  (export "main" (func $main))

)