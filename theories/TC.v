Require Import Coq.Lists.List.
Require Import Coq.Strings.Ascii.
Require Import Coq.Strings.String.
Require Import MetaCoq.Template.TemplateMonad.Extractable.
Require Import MetaCoq.Template.Loader.
Require Import MetaCoq.Template.Ast.
Require Import ExtLib.Structures.Monad.
Import MonadNotation.
Local Open Scope string_scope.

Require Import seal.seal.

Module __seal.

  Local Notation "<% x %>" := (ltac:(let p y := exact y in quote_term x p))
                                (only parsing).

  Local Definition q_eq := <% @eq %>.
  Local Definition q_eq_refl := <% @eq_refl %>.
  Local Definition q_opaque := <% @_opaque %>.
  Local Definition q_seal := <% @_seal %>.
  Local Definition q_opaque_ind : inductive :=
    ltac:(lazymatch eval red in q_opaque with
          | tInd ?t _ => exact t
          | _ => fail "_opaque is not an inductive?"
          end).

  Local Fixpoint string_rev (pre s : string) : string :=
    match s with
    | EmptyString => pre
    | String s ss => string_rev (String s pre) ss
    end.

  Local Fixpoint get_base (pre nm : string) : TM string :=
    match nm with
    | EmptyString => tmFail "the name must end with _def"
    | "_def" => tmReturn (string_rev "" pre)
    | String "."%char ss => get_base "" ss
    | String "#"%char ss => get_base "" ss
    | String s ss => get_base (String s pre) ss
    end.

  Instance Monad_TM : Monad TM :=
    { ret := @tmReturn
    ; bind := @tmBind }.

  Local Definition mk_sealed (name : string) (type def : Ast.term) : TM kername :=
    tmDefinition name
                 None
                 (tApp q_seal (type :: def :: def :: tApp q_eq_refl (type :: def :: nil) :: nil)).

  Local Definition mk_eq (name base_kn : string) (type def sealed : Ast.term) : TM kername :=
    tmDefinition name
                 (Some (tApp q_eq (type :: def :: tConst base_kn nil :: nil)))
                 (tProj ((q_opaque_ind, 2), 1) sealed).

  Definition generate (def : Ast.term) : TM _ :=
    match def with
    | tConst kn ui =>
      base <- get_base "" kn ;;
      cnst <- tmQuoteConstant kn false ;;
      match cnst with
      | ParameterEntry p => tmFail "parameter, already opaque"
      | DefinitionEntry d =>
        let body := d.(definition_entry_body) in
        let type := d.(definition_entry_type) in
        sealed_kn <- mk_sealed (base ++ "_seal")%string type body ;;
        let sealed := tConst sealed_kn nil in
        base_kn <- tmDefinition base None (tProj ((q_opaque_ind, 2), 0) sealed) ;;
        mk_eq (base ++ "_eq")%string base_kn type def sealed ;;
        tmMsg ("sealed [" ++ base ++ "] as [" ++ base ++ "_seal] with equation [" ++ base ++ "_eq]")%string
      end
    | _ => tmFail "not a constant"
    end%monad.

End __seal.

Definition seal' := __seal.generate.

Notation "'seal' x" := ltac:(let p y := exact (seal' y) in quote_term x p)
   (at level 200, x at level 0, only parsing).
