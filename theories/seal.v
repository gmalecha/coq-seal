Set Primitive Projections.

Record _opaque {T : Type} {a : T} : Type := _seal
  { _unseal : T
  ; _value_eq : a = _unseal }.
  (* note: the orientation of the equality is set up to support efficient
   * [destruct _value_eq].
   *)
Arguments _opaque {_} _.
