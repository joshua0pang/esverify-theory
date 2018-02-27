import .syntax .notations .evaluation .substitution .qi .vcgen

-- simple axioms for logical reasoning

axiom valid.tru:
  ⊨ value.true

axiom valid.not {P: vc}:
  ¬ (⊨ P)
  ↔
  ⊨ P.not

axiom valid.and {P Q: vc}:
  (⊨ P) ∧ (⊨ Q)
  ↔
  ⊨ P ⋀ Q

axiom valid.or {P Q: vc}:
  (⊨ P) ∨ (⊨ Q)
  ↔
  ⊨ P ⋁ Q

axiom valid.implies  {P Q: vc}:
  (⊨ P) → (⊨ Q)
  ↔
  ⊨ vc.implies P Q

axiom valid.univ {x: var} {P: vc}:
  (∀v, ⊨ vc.subst x v P)
  ↔
  ⊨ vc.univ x P

-- axioms for equality

-- a term is valid if it equals true
axiom valid.eq.true {t: term}:
  ⊨ t
  ↔
  ⊨ t ≡ value.true

-- unary and binary operators are decidable, so equalities with operators are decidable
axiom valid.eq.unop {op: unop} {vₓ v: value}:
  unop.apply op vₓ = some v
  ↔
  ⊨ term.unop op vₓ ≡ v

axiom valid.eq.binop {op: binop} {v₁ v₂ v: value}:
  binop.apply op v₁ v₂ = some v
  ↔
  ⊨ term.binop op v₁ v₂ ≡ v

-- The following equality axiom is non-standard and makes validity undecidable.
-- It is only used in the preservation proof of e-return and in no other lemmas.
-- The logic treats `f(x)` uninterpreted, so there is no way to derive it naturally.
-- However, given a complete evaluation derivation of a function call, we can add the
-- equality `f(x)=y` as new axiom for closed values f, x, y and the resulting set
-- of axioms is still sound due to deterministic evaluation.
axiom valid.eq.app {vₓ v: value} {σ σ': env} {H H': history} {f x y: var} {R S: spec} {e: exp}:
  (H, σ[x↦vₓ], e) ⟶* (H', σ', exp.return y) ∧
  (σ' y = some v)
  →
  ⊨ term.app (value.func f x R S e H σ) vₓ ≡ v

-- can write pre₁ and pre₂ to check domain of operators

axiom valid.pre₁ {vₓ: value} {op: unop}:
  option.is_some (unop.apply op vₓ)
  ↔
  ⊨ vc.pre₁ op vₓ

axiom valid.pre₂ {v₁ v₂: value} {op: binop}:
  option.is_some (binop.apply op v₁ v₂)
  ↔
  ⊨ vc.pre₂ op v₁ v₂

-- can write pre and post to extract pre- and postcondition of function values

axiom valid.pre {vₓ: value} {σ: env} {f x: var} {R S: spec} {e: exp} {H: history}:
  (σ[f↦value.func f x R S e H σ][x↦vₓ] ⊨ R.to_prop.instantiated_n)
  →
  ⊨ vc.pre (value.func f x R S e H σ) vₓ

axiom valid.post {vₓ: value} {σ: env} {Q: prop} {Q₂: propctx} {f x: var} {R S: spec} {e: exp} {H: history}:
  (⊢ σ : Q) →
  (H ⋀ Q ⋀ spec.func f x R S ⋀ R ⊢ e : Q₂) →
  (⊨ vc.post (value.func f x R S e H σ) vₓ)
  →
  (σ[f↦value.func f x R S e H σ][x↦vₓ] ⊨ (Q₂ (term.app f x) ⋀ S.to_prop).instantiated)

-- lemmas

lemma valid.neg_neg {P: vc}: (⊨ P.not.not) ↔ ⊨ P :=
  iff.intro (
    assume : ⊨ P.not.not,
    have h1: ¬ ⊨ P.not, from valid.not.mpr this,
    have h2: ¬ ¬ ⊨ P, from (
      assume : ¬ ⊨ P,
      have ⊨ P.not, from valid.not.mp this,
      show «false», from h1 this
    ),
    show ⊨ P, from classical.by_contradiction (
      assume : ¬ ⊨ P,
      show «false», from h2 this
    )
  ) (
    assume h1: ⊨ P,
    have h2: ¬ ⊨ P.not, from (
      assume : ⊨ P.not,
      have ¬ ⊨ P, from valid.not.mpr this,
      show «false», from this h1
    ),
    show ⊨ P.not.not, from valid.not.mp h2
  )

lemma valid.mt {P Q: vc}: (⊨ vc.implies P Q) → (⊨ Q.not) → ⊨ P.not :=
  assume h1: ⊨ vc.implies P Q,
  assume : ⊨ Q.not,
  have h2: ¬ ⊨ Q, from valid.not.mpr this,
  have ¬ ⊨ P, from (
    assume : ⊨ P,
    have ⊨ Q, from valid.implies.mpr h1 this,
    show «false», from h2 this
  ),
  show ⊨ P.not, from valid.not.mp this

lemma valid.refl {v: value}: ⊨ (v ≡ v) :=
  have binop.apply binop.eq v v = @ite (v = v)
                                  (classical.prop_decidable (v = v))
                                  value value.true value.false, by unfold binop.apply,
  have binop.apply binop.eq v v = value.true, by simp[this],
  have ⊨ ((v ≡ v) ≡ value.true), from valid.eq.binop.mp this,
  show ⊨ (v ≡ v), from valid.eq.true.mpr this

lemma valid.implies.trans {P₁ P₂ P₃: vc}:
      (⊨ vc.implies P₁ P₂) → (⊨ vc.implies P₂ P₃) → ⊨ vc.implies P₁ P₃ :=
  assume h1: ⊨ vc.implies P₁ P₂,
  assume h2: ⊨ vc.implies P₂ P₃,
  show ⊨ vc.implies P₁ P₃, from valid.implies.mp (
    assume : ⊨ P₁,
    have ⊨ P₂, from valid.implies.mpr h1 this,
    show ⊨ P₃, from valid.implies.mpr h2 this
  )

lemma valid_env.true {σ: env}: σ ⊨ value.true :=
  have h1: ⊨ value.true, from valid.tru,
  have term.subst_env σ value.true = value.true, from term.subst_env.value,
  have h2: ⊨ term.subst_env σ value.true, from this.symm ▸ h1,
  have vc.subst_env σ value.true = vc.term (term.subst_env σ value.true), from vc.subst_env.term,
  show σ ⊨ value.true, from this.symm ▸ h2

lemma valid_env.mt {σ: env} {P Q: vc}: (σ ⊨ vc.implies P Q) → (σ ⊨ Q.not) → σ ⊨ P.not :=
  assume h1: σ ⊨ vc.implies P Q,
  have vc.subst_env σ (vc.implies P Q) = vc.implies (vc.subst_env σ P) (vc.subst_env σ Q),
  from vc.subst_env.implies,
  have h2: ⊨ vc.implies (vc.subst_env σ P) (vc.subst_env σ Q), from this ▸ h1,
  assume h3: σ ⊨ Q.not,
  have vc.subst_env σ Q.not = (vc.subst_env σ Q).not, from vc.subst_env.not,
  have h4: ⊨ (vc.subst_env σ Q).not, from this ▸ h3,
  have h5: ⊨ (vc.subst_env σ P).not, from valid.mt h2 h4,
  have vc.subst_env σ P.not = (vc.subst_env σ P).not, from vc.subst_env.not,
  show σ ⊨ P.not, from this.symm ▸ h5

lemma valid_env.eq.true {σ: env} {t: term}: σ ⊨ t ↔ σ ⊨ (t ≡ value.true) :=
  iff.intro (
    assume t_valid: ⊨ vc.subst_env σ t,
    have vc.subst_env σ t = vc.term (term.subst_env σ t), from vc.subst_env.term,
    have ⊨ vc.term (term.subst_env σ t), from this ▸ t_valid,
    have h: ⊨ vc.term ((term.subst_env σ t) ≡ value.true), from valid.eq.true.mp this,
    have term.subst_env σ value.true = value.true, from term.subst_env.value,
    have h2: ⊨ vc.term ((term.subst_env σ t) ≡ (term.subst_env σ value.true)),
    from this.symm ▸ h,
    have (term.subst_env σ (t ≡ value.true)) = ((term.subst_env σ t) ≡ (term.subst_env σ value.true)),
    from term.subst_env.binop,
    have h3: ⊨ term.subst_env σ (t ≡ value.true),
    from this.symm ▸ h2,
    have vc.subst_env σ (t ≡ value.true) = vc.term (term.subst_env σ (t ≡ value.true)), from vc.subst_env.term,
    show σ ⊨ (t ≡ value.true), from this.symm ▸ h3
  ) (
    assume t_valid: ⊨ vc.subst_env σ (t ≡ value.true),
    have vc.subst_env σ (t ≡ value.true) = vc.term (term.subst_env σ (t ≡ value.true)), from vc.subst_env.term,
    have h: ⊨ vc.term (term.subst_env σ (t ≡ value.true)),
    from this ▸ t_valid,
    have (term.subst_env σ (t ≡ value.true)) = ((term.subst_env σ t) ≡ (term.subst_env σ value.true)),
    from term.subst_env.binop,
    have h2: ⊨ vc.term ((term.subst_env σ t) ≡ (term.subst_env σ value.true)),
    from this ▸ h,
    have term.subst_env σ value.true = value.true, from term.subst_env.value,
    have ⊨ vc.term ((term.subst_env σ t) ≡ value.true), from this ▸ h2,
    have h3: ⊨ vc.term (term.subst_env σ t), from valid.eq.true.mpr this,
    have vc.subst_env σ t = vc.term (term.subst_env σ t), from vc.subst_env.term,
    show ⊨ vc.subst_env σ t, from this.symm ▸ h3
  )

lemma valid_env.neg_neg {σ: env} {P: vc}: (σ ⊨ P.not.not) ↔ σ ⊨ P :=
  iff.intro (
    assume h1: σ ⊨ P.not.not,
    have vc.subst_env σ P.not.not = (vc.subst_env σ P.not).not, from vc.subst_env.not,
    have h2: ⊨ (vc.subst_env σ P.not).not, from this ▸ h1,
    have vc.subst_env σ P.not = (vc.subst_env σ P).not, from vc.subst_env.not,
    have  ⊨ (vc.subst_env σ P).not.not, from this ▸ h2,
    show σ ⊨ P, from valid.neg_neg.mp this
  ) (
    assume : σ ⊨ P,
    have h1: ⊨ (vc.subst_env σ P).not.not, from valid.neg_neg.mpr this,
    have vc.subst_env σ P.not = (vc.subst_env σ P).not, from vc.subst_env.not,
    have h2: ⊨ (vc.subst_env σ P.not).not, from this.symm ▸ h1,
    have vc.subst_env σ P.not.not = (vc.subst_env σ P.not).not, from vc.subst_env.not,
    show σ ⊨ P.not.not, from this.symm ▸ h2
  )

lemma valid_env.and {σ: env} {P Q: vc}: (σ ⊨ P) → (σ ⊨ Q) → σ ⊨ (P ⋀ Q) :=
  assume p_valid: ⊨ vc.subst_env σ P,
  assume q_valid: ⊨ vc.subst_env σ Q,
  have vc.subst_env σ (P ⋀ Q) = (vc.subst_env σ P ⋀ vc.subst_env σ Q), from vc.subst_env.and,
  show σ ⊨ (P ⋀ Q), from this.symm ▸ valid.and.mp ⟨p_valid, q_valid⟩

lemma valid_env.and.elim {σ: env} {P Q: vc}: (σ ⊨ P ⋀ Q) → (σ ⊨ P) ∧ σ ⊨ Q :=
  assume p_and_q_valid: ⊨ vc.subst_env σ (P ⋀ Q),
  have vc.subst_env σ (P ⋀ Q) = (vc.subst_env σ P ⋀ vc.subst_env σ Q), from vc.subst_env.and,
  have ⊨ (vc.subst_env σ P ⋀ vc.subst_env σ Q), from this ▸ p_and_q_valid,
  show (σ ⊨ P) ∧ (σ ⊨ Q), from valid.and.mpr this

lemma valid_env.or₁ {σ: env} {P Q: vc}: (σ ⊨ P) → σ ⊨ (P ⋁ Q) :=
  assume : ⊨ vc.subst_env σ P,
  have h: ⊨ vc.subst_env σ P ⋁ vc.subst_env σ Q, from valid.or.mp (or.inl this),
  have vc.subst_env σ (P ⋁ Q) = (vc.subst_env σ P ⋁ vc.subst_env σ Q), from vc.subst_env.or,
  show σ ⊨ (P ⋁ Q), from this.symm ▸ h

lemma valid_env.or₂ {σ: env} {P Q: vc}: (σ ⊨ Q) → σ ⊨ (P ⋁ Q) :=
  assume : ⊨ vc.subst_env σ Q,
  have h: ⊨ vc.subst_env σ P ⋁ vc.subst_env σ Q, from valid.or.mp (or.inr this),
  have vc.subst_env σ (P ⋁ Q) = (vc.subst_env σ P ⋁ vc.subst_env σ Q), from vc.subst_env.or,
  show σ ⊨ (P ⋁ Q), from this.symm ▸ h

lemma valid_env.or.elim {σ: env} {P Q: vc}: (σ ⊨ P ⋁ Q) → (σ ⊨ P) ∨ σ ⊨ Q :=
  assume p_or_q_valid: ⊨ vc.subst_env σ (P ⋁ Q),
  have vc.subst_env σ (P ⋁ Q) = (vc.subst_env σ P ⋁ vc.subst_env σ Q), from vc.subst_env.or,
  have ⊨ (vc.subst_env σ P ⋁ vc.subst_env σ Q), from this ▸ p_or_q_valid,
  show (σ ⊨ P) ∨ (σ ⊨ Q), from valid.or.mpr this

lemma valid_env.not {σ: env} {P: vc}: ¬ (σ ⊨ P) ↔ (σ ⊨ P.not) :=
  iff.intro (
    assume h1: ¬ (σ ⊨ P),
    have h2: vc.subst_env σ P.not = (vc.subst_env σ P).not, from vc.subst_env.not,
    have ¬ ⊨ (vc.subst_env σ P), from h2 ▸ h1,
    have ⊨ (vc.subst_env σ P).not, from valid.not.mp this,
    show σ ⊨ P.not, from h2.symm ▸ this
  ) (
    assume h1: σ ⊨ P.not,
    have h2: vc.subst_env σ P.not = (vc.subst_env σ P).not, from vc.subst_env.not,
    have ⊨ (vc.subst_env σ P).not, from h2 ▸ h1,
    have ¬ ⊨ (vc.subst_env σ P), from valid.not.mpr this,
    show ¬ (σ ⊨ P), from h2.symm ▸ this
  )

lemma valid_env.mp {σ: env} {P Q: vc}: (σ ⊨ vc.implies P Q) → (σ ⊨ P) → σ ⊨ Q :=
  assume impl: σ ⊨ (vc.implies P Q),
  assume p: σ ⊨ P,
  have vc.subst_env σ (vc.implies P Q) = (vc.subst_env σ P.not ⋁ vc.subst_env σ Q), from vc.subst_env.or,
  have h: ⊨ (vc.subst_env σ P.not ⋁ vc.subst_env σ Q), from this ▸ impl,
  have vc.subst_env σ P.not = (vc.subst_env σ P).not, from vc.subst_env.not,
  have ⊨ ((vc.subst_env σ P).not ⋁ vc.subst_env σ Q), from this ▸ h,
  have ⊨ vc.implies (vc.subst_env σ P) (vc.subst_env σ Q), from this,
  show σ ⊨ Q, from valid.implies.mpr this p

lemma valid_env.mpr {σ: env} {P Q: vc}: ((σ ⊨ P) → σ ⊨ Q) → σ ⊨ vc.implies P Q :=
  assume : ((σ ⊨ P) → σ ⊨ Q),
  have ⊨ vc.implies (vc.subst_env σ P) (vc.subst_env σ Q), from valid.implies.mp this,
  have h1: ⊨ vc.or (vc.subst_env σ P).not (vc.subst_env σ Q), from this,
  have vc.subst_env σ P.not = (vc.subst_env σ P).not, from vc.subst_env.not,
  have h2: ⊨ vc.or (vc.subst_env σ P.not) (vc.subst_env σ Q), from this.symm ▸ h1,
  have vc.subst_env σ (P.not ⋁ Q) = (vc.subst_env σ P.not ⋁ vc.subst_env σ Q),
  from vc.subst_env.or,
  have ⊨ vc.subst_env σ (P.not ⋁ Q), from this.symm ▸ h2,
  show σ ⊨ vc.implies P Q, from this

lemma valid_env.implies.trans {σ: env} {P₁ P₂ P₃: vc}:
      (σ ⊨ vc.implies P₁ P₂) → (σ ⊨ vc.implies P₂ P₃) → σ ⊨ vc.implies P₁ P₃ :=
  assume h1: σ ⊨ vc.implies P₁ P₂,
  assume h2: σ ⊨ vc.implies P₂ P₃,
  show σ ⊨ vc.implies P₁ P₃, from valid_env.mpr (
    assume : σ ⊨ P₁,
    have σ ⊨ P₂, from valid_env.mp h1 this,
    show σ ⊨ P₃, from valid_env.mp h2 this
  )

lemma history_valid {H: history}: ⟪calls_to_prop H⟫ :=
  assume σ: env,
  begin
    induction H with H₁ f y R S e H₂ σ₂ v ih₁ ih₂,

    show σ ⊨ (calls_to_prop history.empty).instantiated, from (
      have h1: σ ⊨ value.true, from valid_env.true,
      have (prop.term value.true).erased = vc.term value.true, by unfold prop.erased,
      have σ ⊨ (prop.term value.true).erased, from this ▸ h1,
      have h2: σ ⊨ (prop.term value.true).instantiated, from valid_env.instantiated_of_erased this,
      have calls_to_prop history.empty = value.true, by unfold calls_to_prop,
      show σ ⊨ (calls_to_prop history.empty).instantiated, from this ▸ h2
    ),

    show σ ⊨ prop.instantiated (calls_to_prop (H₁ · call f y R S e H₂ σ₂ v)), from (
      have h1: σ ⊨ (calls_to_prop H₁).instantiated, from ih₁,
      have h2: σ ⊨ value.true, from valid_env.true,
      have (prop.call (value.func f y R S e H₂ σ₂) v).erased = vc.term value.true, by unfold prop.erased,
      have σ ⊨ (prop.call (value.func f y R S e H₂ σ₂) v).erased, from this ▸ h2,
      have h3: σ ⊨ (prop.call (value.func f y R S e H₂ σ₂) v).instantiated, from valid_env.instantiated_of_erased this,
      have σ ⊨ ((calls_to_prop H₁).instantiated ⋀ (prop.call (value.func f y R S e H₂ σ₂) v).instantiated),
      from valid_env.and h1 h3,
      have h4: σ ⊨ (calls_to_prop H₁ ⋀ prop.call (value.func f y R S e H₂ σ₂) v).instantiated,
      from valid_env.instantiated_and this,
      have calls_to_prop (H₁ · call f y R S e H₂ σ₂ v)
        = (calls_to_prop H₁ ⋀ prop.call (value.func f y R S e H₂ σ₂) v),
      by unfold calls_to_prop,
      show σ ⊨ (calls_to_prop (H₁ · call f y R S e H₂ σ₂ v)).instantiated, from this ▸ h4
    )
  end
