/-
Copyright (c) 2015 Nathaniel Thomas. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Nathaniel Thomas, Jeremy Avigad, Johannes Hölzl

Modules over a ring.
-/

import algebra.ring algebra.big_operators data.set.basic

universes u v w
variables {α : Type u} {β : Type v} {γ : Type w}

class has_scalar (α : inout Type u) (γ : Type v) := (smul : α → γ → γ)

infixr ` • `:73 := has_scalar.smul

class module (α : inout Type u) (β : Type v) [inout ring α]
  extends has_scalar α β, add_comm_group β :=
(smul_add : ∀r (x y : β), r • (x + y) = r • x + r • y)
(add_smul : ∀r s (x : β), (r + s) • x = r • x + s • x)
(mul_smul : ∀r s (x : β), (r * s) • x = r • s • x)
(one_smul : ∀x : β, (1 : α) • x = x)

section module
variables [ring α] [module α β] {r s : α} {x y : β}

theorem smul_add : r • (x + y) = r • x + r • y := module.smul_add r x y
theorem add_smul : (r + s) • x = r • x + s • x := module.add_smul r s x
theorem mul_smul : (r * s) • x = r • s • x :=  module.mul_smul r s x
@[simp] theorem one_smul : (1 : α) • x = x := module.one_smul _ x

@[simp] theorem zero_smul : (0 : α) • x = 0 :=
have (0 : α) • x + 0 • x = 0 • x + 0, by rw ← add_smul; simp,
add_left_cancel this

@[simp] theorem smul_zero : r • (0 : β) = 0 :=
have r • (0:β) + r • 0 = r • 0 + 0, by rw ← smul_add; simp,
add_left_cancel this

@[simp] theorem neg_smul : -r • x = - (r • x) :=
eq_neg_of_add_eq_zero (by rw [← add_smul, add_left_neg, zero_smul])

theorem neg_one_smul (x : β) : (-1 : α) • x = -x := by simp

@[simp] theorem smul_neg : r • (-x) = -(r • x) :=
by rw [← neg_one_smul x, ← mul_smul, mul_neg_one, neg_smul]

theorem smul_sub (r : α) (x y : β) : r • (x - y) = r • x - r • y :=
by simp [smul_add]

theorem sub_smul (r s : α) (y : β) : (r - s) • y = r • y - s • y :=
by simp [add_smul]

lemma smul_smul : r • s • x = (r * s) • x := mul_smul.symm

end module

instance ring.to_module [r : ring α] : module α α :=
{ smul := (*),
  smul_add := mul_add,
  add_smul := add_mul,
  mul_smul := mul_assoc,
  one_smul := one_mul, ..r }

class is_submodule {α : Type u} {β : Type v} [ring α] [module α β] (p : set β) : Prop :=
(zero_ : (0:β) ∈ p)
(add_  : ∀ {x y}, x ∈ p → y ∈ p → x + y ∈ p)
(smul  : ∀ c {x}, x ∈ p → c • x ∈ p)

namespace is_submodule
variables [ring α] [module α β]
variables {p : set β} [is_submodule p]
variables {r : α}
include α

section
variables {x y : β}

lemma zero : (0 : β) ∈ p := is_submodule.zero_ α p

lemma add : x ∈ p → y ∈ p → x + y ∈ p := is_submodule.add_ α

lemma neg (hx : x ∈ p) : -x ∈ p := by rw ← neg_one_smul x; exact smul _ hx

lemma sub (hx : x ∈ p) (hy : y ∈ p) : x - y ∈ p := add hx (neg hy)

lemma sum {ι : Type w} [decidable_eq ι] {t : finset ι} {f : ι → β} :
  (∀c∈t, f c ∈ p) → t.sum f ∈ p :=
finset.induction_on t (by simp [zero]) (by simp [add] {contextual := tt})

end

section subtype
variables  {x y : {x : β // x ∈ p}}

instance : has_add {x : β // x ∈ p} := ⟨λ ⟨x, px⟩ ⟨y, py⟩, ⟨x + y, add px py⟩⟩
instance : has_zero {x : β // x ∈ p} := ⟨⟨0, zero⟩⟩
instance : has_neg {x : β // x ∈ p} := ⟨λ ⟨x, hx⟩, ⟨-x, neg hx⟩⟩
instance : has_scalar α {x : β // x ∈ p} := ⟨λ c ⟨x, hx⟩, ⟨c • x, smul c hx⟩⟩

@[simp] lemma add_val  : (x + y).val = x.val + y.val := by cases x; cases y; refl
@[simp] lemma zero_val : (0 : {x : β // x ∈ p}).val = 0 := rfl
@[simp] lemma neg_val  : (-x).val = -x.val := by cases x; refl
@[simp] lemma smul_val : (r • x).val = r • x.val := by cases x; refl

instance : module α {x : β // x ∈ p} :=
by refine {add := (+), zero := 0, neg := has_neg.neg, smul := (•), ..};
  { intros, apply subtype.eq,
    simp [smul_add, add_smul, mul_smul] }

lemma sub_val  : (x - y).val = x.val - y.val := by simp

end subtype

end is_submodule

structure linear_map (α : Type u) (β : Type v) (γ : Type w) [ring α] [module α β] [module α γ] :=
(T : β → γ)
(map_add : ∀ x y, T (x + y) = T x + T y)
(map_smul : ∀ (c:α) x, T (c • x) = c • T x)

namespace linear_map

variables [ring α] [module α β] [module α γ]
variables {r : α} {A B C : linear_map α β γ} {x y : β}

instance : has_coe_to_fun (linear_map α β γ) := ⟨_, T⟩

@[simp] lemma map_add_app : A (x + y) = A x + A y := A.map_add x y
@[simp] lemma map_smul_app : A (r • x) = r • A x := A.map_smul r x

theorem ext : ∀ {A B : linear_map α β γ}, (∀ x, A x = B x) → A = B
| ⟨TA, _, _⟩ ⟨TB, _, _⟩ h := by congr; exact funext h

@[simp] lemma map_zero : A 0 = 0 :=
by have := (map_add A 0 0).symm;
   rwa [add_zero, add_self_iff_eq_zero] at this

@[simp] lemma map_neg : A (-x) = -A x :=
eq_neg_of_add_eq_zero (by rw ← map_add_app; simp)

@[simp] lemma map_sub : A (x - y) = A x - A y := by simp

/- kernel -/

def ker (A : linear_map α β γ) : set β := {y | A y = 0}

section ker

@[simp] lemma mem_ker : x ∈ A.ker ↔ A x = 0 := iff.rfl

theorem ker_of_map_eq_map (h : A x = A y) : x - y ∈ A.ker :=
by rw [mem_ker, map_sub]; exact sub_eq_zero_of_eq h

theorem inj_of_trivial_ker (H : A.ker ⊆ {0}) (h : A x = A y) : x = y :=
eq_of_sub_eq_zero $ set.eq_of_mem_singleton $ H $ ker_of_map_eq_map h

variables (α A)

instance ker.is_submodule : is_submodule A.ker :=
{ zero_ := map_zero,
  add_ := λ x y HU HV, by rw mem_ker at *; simp [HU, HV, mem_ker],
  smul := λ r x HV, by rw mem_ker at *; simp [HV] }

theorem sub_ker (HU : x ∈ A.ker) (HV : y ∈ A.ker) : x - y ∈ A.ker :=
is_submodule.sub HU HV

end ker

/- image -/

def im (A : linear_map α β γ) : set γ := {x | ∃ y, A y = x}

@[simp] lemma mem_im {A : linear_map α β γ} {z : γ} :
  z ∈ A.im ↔ ∃ y, A y = z := iff.rfl

instance im.is_submodule : is_submodule A.im :=
{ zero_ := ⟨0, map_zero⟩,
  add_ := λ a b ⟨x, hx⟩ ⟨y, hy⟩, ⟨x + y, by simp [hx, hy]⟩,
  smul := λ r a ⟨x, hx⟩, ⟨r • x, by simp [hx]⟩ }

section add_comm_group

instance : has_add (linear_map α β γ) :=
⟨λ ⟨T₁, a₁, s₁⟩ ⟨T₂, a₂, s₂⟩,
  ⟨λ y, T₁ y + T₂ y, by simp [a₁, a₂], by simp [smul_add, s₁, s₂]⟩⟩

instance : has_zero (linear_map α β γ) := ⟨⟨λ_, 0, by simp, by simp⟩⟩

instance : has_neg (linear_map α β γ) :=
⟨λ ⟨T, a, s⟩,
  ⟨λ y, -T y, by simp [a], by simp [s]⟩⟩

@[simp] lemma add_app : (A + B) x = A x + B x := by cases A; cases B; refl
@[simp] lemma zero_app : (0 : linear_map α β γ) x = 0 := rfl
@[simp] lemma neg_app : (-A) x = -A x := by cases A; refl

instance : add_comm_group (linear_map α β γ) :=
by refine {add := (+), zero := 0, neg := has_neg.neg, ..};
  { intros, apply ext, simp }

end add_comm_group

end linear_map

namespace linear_map

section Hom

variables [comm_ring α] [module α β] [module α γ]
variables {r : α} {A B C : linear_map α β γ} {x y : β}

protected def smul : α → linear_map α β γ → linear_map α β γ
| r ⟨T, a, s⟩ := ⟨λ x, r • T x,
  by simp [smul_add, a], by simp [smul_smul, s, mul_comm]⟩

instance : has_scalar α (linear_map α β γ) := ⟨linear_map.smul⟩

@[simp] lemma smul_app : (r • A) x = r • (A x) := by cases A; refl

variables (α β γ)

instance : module α (linear_map α β γ) :=
by refine {smul := (•), ..linear_map.add_comm_group, ..};
  { intros, apply ext,
    simp [smul_add, add_smul, mul_smul] }

end Hom

end linear_map


namespace module

variables [ring α] [module α β]

instance : has_one (linear_map α β β) := ⟨⟨id, λ x y, rfl, λ x y, rfl⟩⟩

protected def mul : linear_map α β β → linear_map α β β → linear_map α β β
| ⟨T₁, a₁, s₁⟩ ⟨T₂, a₂, s₂⟩ := ⟨T₁ ∘ T₂, by simp [(∘), a₂, a₁], by simp [(∘), s₂, s₁]⟩

instance : has_mul (linear_map α β β) := ⟨module.mul⟩

@[simp] lemma one_app (x : β) : (1 : linear_map α β β) x = x := rfl
@[simp] lemma mul_app (A B : linear_map α β β) (x : β) : (A * B) x = A (B x) :=
by cases A; cases B; refl

variables (α β)

def endomorphism_ring : ring (linear_map α β β) :=
by refine {mul := (*), one := 1, ..linear_map.add_comm_group, ..};
  { intros, apply linear_map.ext, simp }

def general_linear_group [ring α] [module α β] :=
by have := endomorphism_ring α β; exact units (linear_map α β β)

end module

class vector_space (α : inout Type u) (β : Type v) [field α] extends module α β

@[reducible] def subspace {α : Type u} {β : Type v} [field α] [vector_space α β] (p : set β) :
  Prop :=
is_submodule p
