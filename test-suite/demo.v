From seal Require Import seal TC.

Definition one_def := 1.
Run TemplateProgram (seal one_def).

Section in_section.
  Definition inside_def := 2.
  Run TemplateProgram (seal inside_def).
End in_section.

Definition cannot := 3.
Fail Run TemplateProgram (seal cannot).
