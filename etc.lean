import .syntax
import data.set data.finset data.list

-- p → q: prop

@[reducible]
def prop.implies(p q: prop): prop := prop.or (prop.not p) q

@[reducible]
def propctx.implies(p q: propctx): propctx := propctx.or (propctx.not p) q

@[reducible]
def qfprop.implies(p q: qfprop): qfprop := qfprop.or (qfprop.not p) q

-- P && Q
class has_and (α : Type) := (and : α → α → α) 
instance : has_and spec := ⟨spec.and⟩
instance : has_and prop := ⟨prop.and⟩
instance : has_and propctx := ⟨propctx.and⟩
instance : has_and qfprop := ⟨qfprop.and⟩
infix `&&` := has_and.and

-- P || Q
class has_or (α : Type) := (or : α → α → α) 
instance : has_or spec := ⟨spec.or⟩
instance : has_or prop := ⟨prop.or⟩
instance : has_or propctx := ⟨propctx.or⟩
instance : has_or qfprop := ⟨qfprop.or⟩
infix `||` := has_or.or

-- use • as hole
notation `•` := termctx.hole

-- simple coercions
instance value_to_term : has_coe value term := ⟨term.value⟩
instance var_to_term : has_coe var term := ⟨term.var⟩
instance term_to_prop : has_coe term prop := ⟨prop.term⟩
instance termctx_to_propctx : has_coe termctx propctx := ⟨propctx.term⟩
instance term_to_qfprop : has_coe term qfprop := ⟨qfprop.term⟩

-- qfprop to prop coercion
def qfprop.to_prop: qfprop → prop
| (qfprop.term t)        := prop.term t
| (qfprop.not P)         := prop.not P.to_prop
| (qfprop.and P Q)       := P.to_prop && Q.to_prop
| (qfprop.or P Q)        := P.to_prop || Q.to_prop
| (qfprop.pre t₁ t₂)     := prop.pre t₁ t₂ 
| (qfprop.pre₁ op t)     := prop.pre₁ op t
| (qfprop.pre₂ op t₁ t₂) := prop.pre₂ op t₁ t₂
| (qfprop.post t₁ t₂)    := prop.post t₁ t₂

instance qfprop_to_prop : has_coe qfprop prop := ⟨qfprop.to_prop⟩

-- use (t ≡ t)/(t ≣ t) to construct equality comparison
infix ≡ := term.binop binop.eq
infix `≣`:50 := termctx.binop binop.eq

-- syntax for let expressions
notation `lett` x `=`:1 `true` `in` e := exp.true x e
notation `letf` x `=`:1 `false` `in` e := exp.false x e
notation `letn` x `=`:1 n`in` e := exp.num x n e
notation `letf` f `[`:1 x `]` `req` R `ens` S `{`:1 e `}`:1 `in` e' := exp.func f x R S e e'
notation `letop` y `=`:1 op `[`:1 x `]`:1 `in` e := exp.unop y op x e
notation `letop2` z `=`:1 op `[`:1 x `,` y `]`:1 `in` e := exp.binop z op x y e
notation `letapp` y `=`:1 f `[`:1 x `]`:1 `in` e := exp.app y f x e

-- σ[x ↦ v]
notation e `[` x `↦` v `]` := env.cons x v e

-- κ · [σ, let y = f [ x ] in e]
notation st `·` `[` env `,` `let` y `=`:1 f `[` x `]` `in` e `]` := stack.cons st env y f x e

-- (σ, e) : stack
instance : has_coe (env × exp) stack := ⟨λe, stack.top e.1 e.2⟩

-- auxiliary lemmas for nat

lemma nonneg_of_nat {n: ℕ}: 0 ≤ n := nat.rec_on n
  (show 0 ≤ 0, by refl)
  (λn zero_lt_n, show 0 ≤ n + 1, from le_add_of_le_of_nonneg zero_lt_n zero_le_one)

lemma lt_of_add_one {n: ℕ}: n < n + 1 :=
  have n ≤ n, by refl,
  show n < n + 1, from lt_add_of_le_of_pos this zero_lt_one

lemma lt_of_add {n m: ℕ}: n < n + m + 1 ∧ m < n + m + 1 :=
  have n_nonneg: 0 ≤ n, from nonneg_of_nat,
  have m_nonneg: 0 ≤ m, from nonneg_of_nat,
  have n ≤ n, by refl,
  have n ≤ n + m, from le_add_of_le_of_nonneg this m_nonneg,
  have h₁: n < n + m + 1, from lt_add_of_le_of_pos this zero_lt_one,
  have m ≤ m, by refl,
  have m ≤ m + n, from le_add_of_le_of_nonneg this n_nonneg,
  have m ≤ n + m, by { rw[add_comm], assumption },
  have h₂: m < n + m + 1, from lt_add_of_le_of_pos this zero_lt_one,
  ⟨h₁, h₂⟩

-- other auxiliary lemmas

lemma neq_symm {α: Type} {a b: α}: a ≠ b → b ≠ a :=
  assume a_neq_b: ¬ (a = b),
  assume b_eq_a: b = a,
  by simp * at *

-- lemma mem_of_2set {α: Type} [h: decidable_eq α] [set_mem: has_mem (set α) α] {a b c: α}:
--   (@has_mem.mem (set α) α set_mem {b,c} a) → (a = b) ∨ (a = c) :=
--   let d: list α := {b,c} in
--   list_of_set

--   assume a_in_d: a ∈ d,
--   have a = b ∨ a ∈ [c], from list.eq_or_mem_of_mem_insert a_in_d,

lemma mem_of_2set {α: Type} {a b c: α}:
  a ∈ ({b, c}: set α) -> (a = b) ∨ (a = c) :=
  assume a_in_bc: a ∈ {b, c},
  have a_in_bc: a ∈ insert b (insert c (∅: set α)), by { simp * at * },
  have a = b ∨ a ∈ insert c ∅, from set.eq_or_mem_of_mem_insert a_in_bc,
  or.elim this (
    assume : a = b,
    show (a = b) ∨ (a = c), from or.inl this
  ) (
    assume : a ∈ insert c ∅,
    have a = c ∨ a ∈ ∅, from set.eq_or_mem_of_mem_insert this,
    or.elim this (
      assume : a = c,
      show (a = b) ∨ (a = c), from or.inr this
    ) (
      assume : a ∈ ∅,
      show (a = b) ∨ (a = c), from absurd this (set.not_mem_empty a)
    )
  )

-- env lookup as function application

@[reducible]
def env.size: env → ℕ := env.rec (λ_, ℕ) 0 (λ_ _ _ n, n + 1)
instance : has_sizeof env := ⟨env.size⟩

def env.apply: env → var → option value
| env.empty _ := none
| (σ[x↦v]) y :=
  have σ.size < (σ[x ↦ v].size), from lt_of_add_one,
  if x = y then v else σ.apply y

instance : has_coe_to_fun env := ⟨λ _, var → option value, env.apply⟩

inductive env.contains: env → var → Prop
| same {e: env} {x: var} {v: value} : env.contains (e[x↦v]) x 
| rest {e: env} {x y: var} {v: value} : env.contains e x → env.contains (e[y↦v]) x

instance : has_mem var env := ⟨λx σ, σ.contains x⟩ 

-- spec to prop coercion

@[reducible]
def spec.size: spec → ℕ := spec.rec (λ_, ℕ)
  (λ_, 0)
  (λ_ n, n + 1)
  (λ_ _ n m , n + m + 1)
  (λ_ _ n m , n + m + 1)
  (λ_ _ _ _ n m , n + m + 1)

instance : has_sizeof spec := ⟨spec.size⟩

def spec.to_prop : spec → prop
| (spec.term t)       := prop.term t
| (spec.not S)        :=
    have S.size < S.not.size, from lt_of_add_one,
    prop.not S.to_prop
| (spec.and R S)      :=
    have R.size < (R && S).size, from lt_of_add.left,
    have S.size < (R && S).size, from lt_of_add.right,
    R.to_prop && S.to_prop
| (spec.or R S)       :=
    have R.size < (R || S).size, from lt_of_add.left,
    have S.size < (R || S).size, from lt_of_add.right,
    R.to_prop || S.to_prop
| (spec.func f x R S) :=
    have R.size < (R && S).size, from lt_of_add.left,
    have S.size < (R && S).size, from lt_of_add.right,
    (term.unop unop.isFunc f) &&
    (prop.forallc x f (prop.implies R.to_prop (prop.pre f x)
                    && prop.implies (R.to_prop && prop.post f x) S.to_prop))

instance spec_to_prop : has_coe spec prop := ⟨spec.to_prop⟩

-- term to termctx coercion

def term.to_termctx : term → termctx
| (term.value v)        := termctx.value v
| (term.var x)          := termctx.var x
| (term.unop op t)      := termctx.unop op t.to_termctx
| (term.binop op t₁ t₂) := termctx.binop op t₁.to_termctx t₂.to_termctx
| (term.app t₁ t₂)      := termctx.app t₁.to_termctx t₂.to_termctx

instance term_to_termctx : has_coe term termctx := ⟨term.to_termctx⟩

-- term to termctx coercion

def prop.to_propctx : prop → propctx
| (prop.term t)        := propctx.term t
| (prop.not P)         := propctx.not P.to_propctx
| (prop.and P₁ P₂)     := P₁.to_propctx && P₂.to_propctx
| (prop.or P₁ P₂)      := P₁.to_propctx || P₂.to_propctx
| (prop.pre t₁ t₂)     := propctx.pre t₁ t₂
| (prop.pre₁ op t)     := propctx.pre₁ op t
| (prop.pre₂ op t₁ t₂) := propctx.pre₂ op t₁ t₂
| (prop.post t₁ t₂)    := propctx.post t₁ t₂
| (prop.call t₁ t₂)    := propctx.call t₁ t₂
| (prop.forallc x t P) := propctx.forallc x t P.to_propctx
| (prop.exist x P)     := propctx.exist x P.to_propctx

instance prop_to_propctx : has_coe prop propctx := ⟨prop.to_propctx⟩

-- termctx substituttion as function application

def termctx.apply: termctx → term → term
| •                           t := t
| (termctx.value v)           _ := term.value v
| (termctx.var x)             _ := term.var x
| (termctx.unop op t₁)        t := term.unop op (t₁.apply t)
| (termctx.binop op t₁ t₂)    t := term.binop op (t₁.apply t) (t₂.apply t)
| (termctx.app t₁ t₂)         t := term.app (t₁.apply t) (t₂.apply t)

instance : has_coe_to_fun termctx := ⟨λ _, term → term, termctx.apply⟩

-- propctx substituttion as function application

def propctx.apply: propctx → term → prop
| (propctx.term t₁) t        := t₁ t
| (propctx.not P) t          := prop.not (P.apply t)
| (propctx.and P₁ P₂) t      := P₁.apply t && P₂.apply t
| (propctx.or P₁ P₂) t       := P₁.apply t || P₂.apply t
| (propctx.pre t₁ t₂) t      := prop.or (t₁ t) (t₂ t)
| (propctx.pre₁ op t₁) t     := prop.pre₁ op (t₁ t)
| (propctx.pre₂ op t₁ t₂) t  := prop.pre₂ op (t₁ t) (t₂ t)
| (propctx.post t₁ t₂) t     := prop.post (t₁ t) (t₂ t)
| (propctx.call t₁ t₂) t     := prop.call (t₁ t) (t₂ t)
| (propctx.forallc x t₁ P) t := prop.forallc x (t₁ t) (P.apply t)
| (propctx.exist x P) t      := prop.exist x (P.apply t)

instance : has_coe_to_fun propctx := ⟨λ _, term → prop, propctx.apply⟩

-- call history to prop coercion

def calls_to_prop: list call → prop
| list.nil := value.true
| (⟨f, x, R, S, e, σ, vₓ, v⟩ :: rest) :=
    prop.call (value.func f x R S e σ) vₓ &&
    prop.post (value.func f x R S e σ) vₓ &&
    (term.app (value.func f x R S e σ) vₓ ≡ v) &&
    calls_to_prop rest

instance call_to_prop: has_coe (list call) prop := ⟨calls_to_prop⟩