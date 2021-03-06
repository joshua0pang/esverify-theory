-- auxiliary lemmas unrelated to verifier

import data.set

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

lemma lt_of_x_s_y {x s y: ℕ}: s < x + (s + (y + 1)) :=
  begin
    rw[←add_assoc],
    rw[←add_comm s x],
    rw[add_assoc],
    apply lt_add_of_pos_right s,
    change 0 < x + (y + 1),
    rw[←add_assoc],
    apply lt_add_of_le_of_pos nonneg_of_nat,
    from zero_lt_one
  end

lemma nat.succ.inj.inv {n m: ℕ}: n = m → (nat.succ n = nat.succ m) :=
  assume : n = m,
  by simp [this]

lemma eq_add_right_of_eq {n m k: ℕ}: n = m → n + k = m + k :=
  begin
    assume h,
    induction k,
    simp,
    from h,

    change (n + (a + 1) = m + (a + 1)),
    rw[←add_assoc n a 1],
    rw[←add_assoc m a 1],
    change (nat.succ (n + a) = nat.succ (m + a)),
    apply nat.succ.inj.inv,
    from ih_1
  end

lemma eq_add_left_of_eq {n m k: ℕ}: n = m → k + n = k + m :=
  begin
    assume h,
    rw[←add_comm n k],
    rw[←add_comm m k],
    from eq_add_right_of_eq h
  end

-- auxiliary lemmas for option

lemma some.inj.inv {α: Type} {a b: α}: a = b → (some a = some b) :=
  assume : a = b,
  by simp [this]

lemma option.some_iff_not_none {α: Type} {a: option α}: option.is_some a ↔ ¬ option.is_none a :=
  begin
    cases a,
    split,
    intro h,
    contradiction,
    intro h2,
    unfold option.is_none at h2,
    have h3: ↑tt = false, from eq_false_intro h2,
    have h4: ↑tt = true, by simp,
    have h5: false = true, from eq.trans h3.symm h4,
    have h6: true, from trivial,
    have h7: false, from h5.symm ▸ h6,
    contradiction,
    split,
    intro h8,
    intro h9,
    contradiction,
    intro h10,
    unfold option.is_some,
    change tt = tt,
    refl
  end

lemma option.none_iff_not_some {α: Type} {a: option α}: option.is_none a ↔ ¬ option.is_some a :=
  begin
    cases a,
    split,
    intro h,
    contradiction,
    intro h2,
    unfold option.is_none,
    change tt = tt,
    refl,
    split,
    intro h3,
    intro h4,
    unfold option.is_none at h3,
    change ff = tt at h3,
    contradiction,
    intro h5,
    unfold option.is_some at h5,
    have h6: ↑tt = false, from eq_false_intro h5,
    have h7: ↑tt = true, by simp,
    have h8: false = true, from eq.trans h6.symm h7,
    have h9: true, from trivial,
    have : false, from h8.symm ▸ h9,
    contradiction
  end

lemma option.is_none.inv {α: Type} {a: option α}: (a = none) ↔ option.is_none a :=
  begin
    cases a,
    case option.some v {
      split,
      assume is_none_some,
      contradiction,
      assume is_none_some,
      contradiction,
    },
    case option.none {
      split,
      assume is_none_none,
      exact rfl,
      assume is_none_none,
      exact rfl
    }
  end

lemma option.is_none.ninv {α: Type} {a: option α}: (a ≠ none) ↔ ¬ option.is_none a :=
  begin
    split,
    intro h,
    cases a,
    contradiction,
    unfold option.is_none,
    intro h2,
    change ff = tt at h2,
    contradiction,
    intro h3,
    intro h4,
    rw[h4] at h3,
    unfold option.is_none at h3,
    have h5: ↑tt = false, from eq_false_intro h3,
    have h6: ↑tt = true, by simp,
    have h7: false = true, from eq.trans h5.symm h6,
    have h8: true, from trivial,
    have r9: false, from h7.symm ▸ h8,
    contradiction
  end

lemma option.is_some_iff_exists {α: Type} {a: option α}: option.is_some a ↔ (∃b, a = some b) :=
  begin
    split,
    cases a,
    assume c,
    cases c,
    intro h,
    existsi a,
    refl,
    intro h2,
    cases h2,
    rw[a_2],
    unfold option.is_some,
    change tt = tt,
    refl
  end

def option.is_none_prop {α: Type} (a: option α): Prop := option.is_none a

instance {α: Type} {a: option α} : decidable (option.is_none_prop a) :=
  let r := a in
  have h: r = a, from rfl,
  @option.rec_on α (λv, (r = v) → decidable (option.is_none_prop a)) r
  (
    assume : r = none,
    have a = none, from eq.trans h this,
    have option.is_none a, from option.is_none.inv.mp this,
    have option.is_none_prop a, from this,
    is_true this
  ) (
    assume v: α,
    assume : r = some v,
    have a = some v, from eq.trans h this,
    have ∃v, a = some v, from exists.intro v this,
    have option.is_some a, from option.is_some_iff_exists.mpr this,
    have ¬ option.is_none a, from option.some_iff_not_none.mp this,
    is_false this
  ) rfl

lemma eq_from_map_result_some {α: Type} {a: option α} {b: α} {f: α → α}: f <$> a = some b → ∃c: α, a=some c ∧ b=f c :=
  begin
    assume h1,
    unfold has_map.map at h1,
    cases a with c,

    unfold option.map at h1,
    unfold option.bind at h1,
    contradiction,

    unfold option.map at h1,
    unfold option.bind at h1,
    unfold function.comp at h1,
    have h2, from option.some.inj h1,
    existsi c,
    split,
    from rfl,
    from h2.symm
  end

-- auxiliary lemmas for sets

lemma set.two_elems_mem {α: Type} {a b c: α}:
  a ∈ ({b, c}: set α) → (a = b) ∨ (a = c) :=
  assume a_in_bc: a ∈ {b, c},
  have a_in_bc: a ∈ insert b (insert c (∅: set α)), by { simp at a_in_bc, simp[a_in_bc] },
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

lemma set.two_elems_mem.inv {α: Type} {a b c: α}: (a = b) ∨ (a = c) → a ∈ ({b, c}: set α) :=
  assume : (a = b) ∨ (a = c),
  or.elim this (
    assume : a = b,
    show a ∈ ({b, c}: set α), { simp, left, from this }
  ) (
    assume : a = c,
    show a ∈ ({b, c}: set α), { simp, right, from this }
  )

lemma set.three_elems_mem {α: Type} {a b c d: α}:
  a ∈ ({b, c, d}: set α) → (a = b) ∨ (a = c) ∨ (a = d) :=
  assume a_in_bcd: a ∈ {b, c, d},
  have a_in_bcd: a ∈ insert b (insert c (insert d (∅: set α))),
  by { simp at a_in_bcd, simp[a_in_bcd] },
  have a = b ∨ a ∈ insert c (insert d (∅: set α)), from set.eq_or_mem_of_mem_insert a_in_bcd,
  or.elim this (
    assume : a = b,
    show (a = b) ∨ (a = c) ∨ (a = d), from or.inl this
  ) (
    assume : a ∈ insert c (insert d (∅: set α)),
    have a = c ∨ a ∈ insert d (∅: set α), from set.eq_or_mem_of_mem_insert this,
    or.elim this (
      assume : a = c,
      show (a = b) ∨ (a = c) ∨ (a = d), from or.inr (or.inl this)
    ) (
      assume : a ∈ insert d (∅: set α),
      have a = d ∨ a ∈ ∅, from set.eq_or_mem_of_mem_insert this,
      or.elim this (
        assume : a = d,
        show (a = b) ∨ (a = c) ∨ (a = d), from or.inr (or.inr this)
      ) (
        assume : a ∈ ∅,
        show (a = b) ∨ (a = c) ∨ (a = d), from absurd this (set.not_mem_empty a)
      )
    )
  )

lemma set.three_elems_mem₁ {α: Type} {a b c d: α}: (a = b) → a ∈ ({b, c, d}: set α) := by { intro ab, rw[ab], simp }
lemma set.three_elems_mem₂ {α: Type} {a b c d: α}: (a = c) → a ∈ ({b, c, d}: set α) := by { intro ac, rw[ac], simp }
lemma set.three_elems_mem₃ {α: Type} {a b c d: α}: (a = d) → a ∈ ({b, c, d}: set α) := by { intro ad, rw[ad], simp }

lemma set.forall_not_mem_of_eq_empty {α: Type} {s: set α}: s = ∅ → ∀ x, x ∉ s :=
  by simp[set.set_eq_def]

lemma set.two_elems_of_insert {α: Type} {a b: α}: set.insert a ∅ ∪ set.insert b ∅ = {a, b} :=
  set.eq_of_subset_of_subset (
    assume x: α,
    assume : x ∈ set.insert a ∅ ∪ set.insert b ∅,
    or.elim (set.mem_or_mem_of_mem_union this) (
      assume : x ∈ set.insert a ∅,
      have x ∈ {a}, from @eq.subst (set α) (λc, x ∈ c) (set.insert a ∅) {a} (set.singleton_def a).symm this,
      show x ∈ {a, b}, by { simp, left, simp at this, from this }
    ) (
      assume : x ∈ set.insert b ∅,
      have x ∈ {b}, from @eq.subst (set α) (λc, x ∈ c) (set.insert b ∅) {b} (set.singleton_def b).symm this,
      show x ∈ {a, b}, by { simp, right, simp at this, from this }
    )
  ) (
    assume x: α,
    assume : x ∈ {a, b},
    or.elim (set.two_elems_mem this) (
      assume : x = a,
      have x ∈ set.insert a ∅, from (set.mem_singleton_iff x a).mpr this,
      show x ∈ set.insert a ∅ ∪ set.insert b ∅, from set.mem_union_left (set.insert b ∅) this
    ) (
      assume : x = b,
      have x ∈ set.insert b ∅, from (set.mem_singleton_iff x b).mpr this,
      show x ∈ set.insert a ∅ ∪ set.insert b ∅, from set.mem_union_right (set.insert a ∅) this
    )
  )

lemma set.subset_of_eq {α: Type} {a b: set α}: (a = b) → (a ⊆ b) :=
  assume a_eq_b: a = b,
  assume x: α,
  assume : x ∈ a,
  show x ∈ b, from a_eq_b ▸ this

lemma set.not_mem_or_mem_of_not_mem_diff {α: Type} {a: α} {b c: set α}: a ∉ b \ c → (a ∉ b ∨ a ∈ c) :=
  begin
    assume h1,
    rw[set.diff_eq] at h1,
    rw[←set.compl_compl b] at h1,
    rw[←set.compl_union] at h1,
    rw[←set.mem_compl_eq] at h1,
    rw[set.compl_compl] at h1,
    have h2, from set.mem_or_mem_of_mem_union h1,
    rw[set.mem_compl_eq] at h2,
    from h2
  end

lemma set.diff_self {α: Type} {a: set α}: a - a = ∅ :=
  begin
    apply set.eq_of_subset_of_subset,

    assume x: α,
    assume h1: x ∈ a - a,
    have h2, from set.mem_of_mem_diff h1,
    have h3, from set.not_mem_of_mem_diff h1,
    contradiction,

    assume x: α,
    assume h1: x ∈ ∅,
    have h2: x ∉ ∅, from set.forall_not_mem_of_eq_empty rfl x,
    contradiction
  end

-- lemmas about if then else

lemma ite.if_true {a: Prop} {b: Type} {c d: b} [decidable a]: a → (ite a c d = c) :=
  begin
    assume ha,
    simp[ha]
  end

lemma ite.if_false {a: Prop} {b: Type} {c d: b} [decidable a]: ¬a → (ite a c d = d) :=
  begin
    assume ha,
    simp[ha]
  end
