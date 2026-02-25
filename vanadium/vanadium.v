module vanadium

import sync

pub const max_i64_val = i64(9223372036854775807)
pub const min_i64_val = i64(-9223372036854775807 - 1)
pub const max_i32_val = i64(2147483647)
pub const min_i32_val = i64(-2147483648)

@[packed; minify]
pub struct RangedInt {
pub:
	min i64
	max i64
mut:
	val i64
}

@[inline; _hot]
pub fn (r RangedInt) in_range(v i64) bool {
	return v >= r.min && v <= r.max
}

@[inline; _hot]
pub fn RangedInt.create(min_v i64, max_v i64, initial i64) !RangedInt {
	if _unlikely_(min_v > max_v) {
		return error('Range_Error: min > max')
	}
	if _unlikely_(initial < min_v || initial > max_v) {
		return error('Constraint_Error: ${initial} not in ${min_v}..${max_v}')
	}
	return RangedInt{ min: min_v, max: max_v, val: initial }
}

@[inline; _hot]
pub fn (r RangedInt) value() i64 {
	return r.val
}

@[inline; _hot]
pub fn (mut r RangedInt) assign(v i64) ! {
	if _unlikely_(v < r.min || v > r.max) {
		return error('Constraint_Error: ${v} not in ${r.min}..${r.max}')
	}
	r.val = v
}

@[inline; _hot]
pub fn (r RangedInt) str() string {
	return '${r.val} in [${r.min}..${r.max}]'
}

@[inline; _hot]
pub fn (r RangedInt) checked_add(other i64) !RangedInt {
	if _unlikely_((other > 0 && r.val > vanadium.max_i64_val - other) || (other < 0 && r.val < vanadium.min_i64_val - other)) {
		return error('Overflow_Error: ${r.val} + ${other}')
	}
	result := r.val + other
	if _unlikely_(result < r.min || result > r.max) {
		return error('Constraint_Error: ${r.val} + ${other} = ${result} not in ${r.min}..${r.max}')
	}
	return RangedInt{ min: r.min, max: r.max, val: result }
}

@[inline; _hot]
pub fn (r RangedInt) checked_sub(other i64) !RangedInt {
	if _unlikely_((other > 0 && r.val < vanadium.min_i64_val + other) || (other < 0 && r.val > vanadium.max_i64_val + other)) {
		return error('Overflow_Error: ${r.val} - ${other}')
	}
	result := r.val - other
	if _unlikely_(result < r.min || result > r.max) {
		return error('Constraint_Error: ${r.val} - ${other} = ${result} not in ${r.min}..${r.max}')
	}
	return RangedInt{ min: r.min, max: r.max, val: result }
}

@[inline; _hot]
pub fn (r RangedInt) checked_mul(other i64) !RangedInt {
	if r.val != 0 && other != 0 {
		if _unlikely_((r.val > 0 && other > 0 && r.val > vanadium.max_i64_val / other) || (r.val < 0 && other < 0 && r.val < vanadium.max_i64_val / other) || (r.val > 0 && other < 0 && other < vanadium.min_i64_val / r.val) || (r.val < 0 && other > 0 && r.val < vanadium.min_i64_val / other)) {
			return error('Overflow_Error: ${r.val} * ${other}')
		}
	}
	result := r.val * other
	if _unlikely_(result < r.min || result > r.max) {
		return error('Constraint_Error: ${r.val} * ${other} = ${result} not in ${r.min}..${r.max}')
	}
	return RangedInt{ min: r.min, max: r.max, val: result }
}

@[inline; _hot]
pub fn (r RangedInt) checked_div(other i64) !RangedInt {
	if _unlikely_(other == 0) {
		return error('Division_Error: division by zero')
	}
	if _unlikely_(r.val == vanadium.min_i64_val && other == -1) {
		return error('Overflow_Error: ${r.val} / ${other}')
	}
	result := r.val / other
	if _unlikely_(result < r.min || result > r.max) {
		return error('Constraint_Error: ${r.val} / ${other} = ${result} not in ${r.min}..${r.max}')
	}
	return RangedInt{ min: r.min, max: r.max, val: result }
}

@[packed; minify]
pub struct SafeList[T] {
pub:
	capacity    int
	lower_bound int
mut:
	data []T
	mtx  &sync.RwMutex = sync.new_rwmutex()
}

@[inline; _hot]
pub fn new_safe_list[T](capacity int) !SafeList[T] {
	if _unlikely_(capacity <= 0) {
		return error('Capacity_Error: capacity must be > 0')
	}
	return SafeList[T]{ capacity: capacity, lower_bound: 1, data: []T{cap: capacity} }
}

@[inline; _hot]
pub fn new_bounded_list[T](capacity int, lower_bound int) !SafeList[T] {
	if _unlikely_(capacity <= 0) {
		return error('Capacity_Error: capacity must be > 0')
	}
	return SafeList[T]{ capacity: capacity, lower_bound: lower_bound, data: []T{cap: capacity} }
}

@[inline; _hot]
fn (s SafeList[T]) upper_bound_unlocked() int {
	return s.lower_bound + s.data.len - 1
}

@[inline; _hot]
pub fn (mut s SafeList[T]) upper_bound() int {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	return s.upper_bound_unlocked()
}

@[inline; _hot]
pub fn (mut s SafeList[T]) at(index int) !T {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	if _unlikely_(s.data.len == 0) {
		return error('Index_Error: list is empty')
	}
	real := index - s.lower_bound
	if _unlikely_(real < 0 || real >= s.data.len) {
		return error('Index_Error: ${index} not in ${s.lower_bound}..${s.upper_bound_unlocked()}')
	}
	return s.data[real]
}

@[inline; _hot]
pub fn (mut s SafeList[T]) set_at(index int, val T) ! {
	s.mtx.lock()
	defer { s.mtx.unlock() }
	real := index - s.lower_bound
	if _unlikely_(real < 0 || real >= s.data.len) {
		return error('Index_Error: ${index} not in ${s.lower_bound}..${s.upper_bound_unlocked()}')
	}
	s.data[real] = val
}

@[inline; _hot]
pub fn (mut s SafeList[T]) append(val T) ! {
	s.mtx.lock()
	defer { s.mtx.unlock() }
	if _unlikely_(s.data.len >= s.capacity) {
		return error('Capacity_Error: list full (max: ${s.capacity})')
	}
	s.data << val
}

@[inline; _hot]
pub fn (mut s SafeList[T]) append_many(vals []T) ! {
	s.mtx.lock()
	defer { s.mtx.unlock() }
	if _unlikely_(s.data.len + vals.len > s.capacity) {
		return error('Capacity_Error: need ${vals.len} slots, only ${s.capacity - s.data.len} available')
	}
	for v in vals {
		s.data << v
	}
}

@[inline; _hot]
pub fn (mut s SafeList[T]) remove_at(index int) !T {
	s.mtx.lock()
	defer { s.mtx.unlock() }
	real := index - s.lower_bound
	if _unlikely_(real < 0 || real >= s.data.len) {
		return error('Index_Error: ${index} not in ${s.lower_bound}..${s.upper_bound_unlocked()}')
	}
	val := s.data[real]
	s.data.delete(real)
	return val
}

@[inline; _hot]
pub fn (mut s SafeList[T]) first() !T {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	if _unlikely_(s.data.len == 0) {
		return error('Empty_Error: list is empty')
	}
	return s.data[0]
}

@[inline; _hot]
pub fn (mut s SafeList[T]) last() !T {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	if _unlikely_(s.data.len == 0) {
		return error('Empty_Error: list is empty')
	}
	return s.data[s.data.len - 1]
}

@[inline; _hot]
pub fn (mut s SafeList[T]) pop() !T {
	s.mtx.lock()
	defer { s.mtx.unlock() }
	if _unlikely_(s.data.len == 0) {
		return error('Empty_Error: cannot pop from empty list')
	}
	return s.data.pop()
}

@[inline; _hot]
pub fn (mut s SafeList[T]) safe_slice(from int, to int) !SafeList[T] {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	if _unlikely_(from > to) {
		return error('Range_Error: from > to')
	}
	real_from := from - s.lower_bound
	real_to := to - s.lower_bound
	if _unlikely_(real_from < 0 || real_to >= s.data.len) {
		return error('Index_Error: slice [${from}..${to}] out of bounds')
	}
	mut result := new_bounded_list[T](real_to - real_from + 1, from)!
	for i in real_from .. real_to + 1 {
		result.data << s.data[i]
	}
	return result
}

@[inline; _hot]
pub fn (mut s SafeList[T]) each(callback fn (int, T)) {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	for i, v in s.data {
		callback(i + s.lower_bound, v)
	}
}

@[inline; _hot]
pub fn (mut s SafeList[T]) len() int {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	return s.data.len
}

@[inline; _hot]
pub fn (mut s SafeList[T]) is_empty() bool {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	return s.data.len == 0
}

@[inline; _hot]
pub fn (mut s SafeList[T]) is_full() bool {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	return s.data.len >= s.capacity
}

@[inline; _hot]
pub fn (mut s SafeList[T]) remaining_capacity() int {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	return s.capacity - s.data.len
}

@[inline; _hot]
pub fn (mut s SafeList[T]) find(val T) ?int {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	for i, v in s.data {
		if v == val {
			return i + s.lower_bound
		}
	}
	return none
}

@[inline; _hot]
pub fn (mut s SafeList[T]) contains(val T) bool {
	s.mtx.rlock()
	defer { s.mtx.runlock() }
	for v in s.data {
		if v == val {
			return true
		}
	}
	return false
}

@[packed; minify]
pub struct SafeVar[T] {
	name string
mut:
	val         T
	initialized bool
	frozen      bool
	mtx         &sync.RwMutex = sync.new_rwmutex()
}

@[inline; _hot]
pub fn new_safe_var[T](name string) SafeVar[T] {
	return SafeVar[T]{ name: name }
}

@[inline; _hot]
pub fn new_safe_var_init[T](name string, val T) SafeVar[T] {
	return SafeVar[T]{ name: name, val: val, initialized: true }
}

@[inline; _hot]
pub fn (mut v SafeVar[T]) get() !T {
	v.mtx.rlock()
	defer { v.mtx.runlock() }
	if _unlikely_(!v.initialized) {
		return error('Access_Error: "${v.name}" used before initialization')
	}
	return v.val
}

@[inline; _hot]
pub fn (mut v SafeVar[T]) set(val T) ! {
	v.mtx.lock()
	defer { v.mtx.unlock() }
	if _unlikely_(v.frozen) {
		return error('Frozen_Error: "${v.name}" is frozen')
	}
	v.val = val
	v.initialized = true
}

@[inline; _hot]
pub fn (mut v SafeVar[T]) freeze() ! {
	v.mtx.lock()
	defer { v.mtx.unlock() }
	if _unlikely_(!v.initialized) {
		return error('Freeze_Error: cannot freeze uninitialized "${v.name}"')
	}
	v.frozen = true
}

@[inline; _hot]
pub fn (mut v SafeVar[T]) is_initialized() bool {
	v.mtx.rlock()
	defer { v.mtx.runlock() }
	return v.initialized
}

@[inline; _hot]
pub fn (mut v SafeVar[T]) is_frozen() bool {
	v.mtx.rlock()
	defer { v.mtx.runlock() }
	return v.frozen
}

@[packed; minify]
pub struct ValidatedVar[T] {
	name      string
	validator ?fn (T) bool
	err_msg   string
mut:
	val         T
	initialized bool
	mtx         &sync.RwMutex = sync.new_rwmutex()
}

@[inline; _hot]
pub fn new_validated_var[T](name string, validator fn (T) bool, err_msg string) ValidatedVar[T] {
	return ValidatedVar[T]{ name: name, validator: validator, err_msg: err_msg }
}

@[inline; _hot]
pub fn (mut v ValidatedVar[T]) set(val T) ! {
	v.mtx.lock()
	defer { v.mtx.unlock() }
	validate := v.validator or {
		return error('Validation_Error: "${v.name}" has no validator')
	}
	if _unlikely_(!validate(val)) {
		return error('Validation_Error: "${v.name}" - ${v.err_msg}')
	}
	v.val = val
	v.initialized = true
}

@[inline; _hot]
pub fn (mut v ValidatedVar[T]) get() !T {
	v.mtx.rlock()
	defer { v.mtx.runlock() }
	if _unlikely_(!v.initialized) {
		return error('Access_Error: "${v.name}" not initialized')
	}
	return v.val
}

@[inline; _hot]
pub fn (mut v ValidatedVar[T]) is_initialized() bool {
	v.mtx.rlock()
	defer { v.mtx.runlock() }
	return v.initialized
}

@[inline; _hot]
pub fn require(condition bool, msg string) ! {
	if _unlikely_(!condition) {
		return error('Precondition_Failed: ${msg}')
	}
}

@[inline; _hot]
pub fn ensure(condition bool, msg string) ! {
	if _unlikely_(!condition) {
		return error('Postcondition_Failed: ${msg}')
	}
}

@[inline; _hot]
pub fn check_invariant(condition bool, msg string) ! {
	if _unlikely_(!condition) {
		return error('Invariant_Violated: ${msg}')
	}
}

@[inline; _hot]
pub fn require_all(conditions []bool, messages []string) ! {
	for i, cond in conditions {
		if _unlikely_(!cond) {
			msg := if i < messages.len { messages[i] } else { 'condition ${i}' }
			return error('Precondition_Failed: ${msg}')
		}
	}
}

@[inline; _hot]
pub fn safe_assert(condition bool, context string, detail string) ! {
	if _unlikely_(!condition) {
		return error('Assertion_Error [${context}]: ${detail}')
	}
}

@[inline; _hot]
pub fn safe_add_i64(a i64, b i64) !i64 {
	if _unlikely_(b > 0 && a > vanadium.max_i64_val - b) {
		return error('Overflow_Error: ${a} + ${b}')
	}
	if _unlikely_(b < 0 && a < vanadium.min_i64_val - b) {
		return error('Underflow_Error: ${a} + ${b}')
	}
	return a + b
}

@[inline; _hot]
pub fn safe_sub_i64(a i64, b i64) !i64 {
	if _unlikely_(b > 0 && a < vanadium.min_i64_val + b) {
		return error('Underflow_Error: ${a} - ${b}')
	}
	if _unlikely_(b < 0 && a > vanadium.max_i64_val + b) {
		return error('Overflow_Error: ${a} - ${b}')
	}
	return a - b
}

@[inline; _hot]
pub fn safe_mul_i64(a i64, b i64) !i64 {
	if a == 0 || b == 0 {
		return i64(0)
	}
	if _unlikely_((a > 0 && b > 0 && a > vanadium.max_i64_val / b) || (a < 0 && b < 0 && a < vanadium.max_i64_val / b) || (a > 0 && b < 0 && b < vanadium.min_i64_val / a) || (a < 0 && b > 0 && a < vanadium.min_i64_val / b)) {
		return error('Overflow_Error: ${a} * ${b}')
	}
	return a * b
}

@[inline; _hot]
pub fn safe_div_i64(a i64, b i64) !i64 {
	if _unlikely_(b == 0) {
		return error('Division_Error: ${a} / 0')
	}
	if _unlikely_(a == vanadium.min_i64_val && b == -1) {
		return error('Overflow_Error: ${a} / ${b}')
	}
	return a / b
}

@[inline; _hot]
pub fn safe_mod_i64(a i64, b i64) !i64 {
	if _unlikely_(b == 0) {
		return error('Division_Error: ${a} % 0')
	}
	return a % b
}

@[inline; _hot]
pub fn safe_add_i32(a int, b int) !int {
	result := i64(a) + i64(b)
	if _unlikely_(result > vanadium.max_i32_val || result < vanadium.min_i32_val) {
		return error('Overflow_Error: ${a} + ${b}')
	}
	return int(result)
}

@[inline; _hot]
pub fn safe_sub_i32(a int, b int) !int {
	result := i64(a) - i64(b)
	if _unlikely_(result > vanadium.max_i32_val || result < vanadium.min_i32_val) {
		return error('Overflow_Error: ${a} - ${b}')
	}
	return int(result)
}

@[inline; _hot]
pub fn safe_mul_i32(a int, b int) !int {
	result := i64(a) * i64(b)
	if _unlikely_(result > vanadium.max_i32_val || result < vanadium.min_i32_val) {
		return error('Overflow_Error: ${a} * ${b}')
	}
	return int(result)
}

@[inline; _hot]
pub fn safe_div_i32(a int, b int) !int {
	if _unlikely_(b == 0) {
		return error('Division_Error: ${a} / 0')
	}
	return a / b
}

@[inline; _hot]
pub fn safe_pow(base i64, exp u32) !i64 {
	mut result := i64(1)
	mut b := base
	mut e := exp
	for e > 0 {
		if e & 1 == 1 {
			result = safe_mul_i64(result, b)!
		}
		if e > 1 {
			b = safe_mul_i64(b, b)!
		}
		e >>= 1
	}
	return result
}

@[inline; _hot]
pub fn safe_negate_i64(a i64) !i64 {
	if _unlikely_(a == vanadium.min_i64_val) {
		return error('Overflow_Error: negate ${a}')
	}
	return -a
}

@[inline; _hot]
pub fn safe_abs_i64(a i64) !i64 {
	if _unlikely_(a == vanadium.min_i64_val) {
		return error('Overflow_Error: abs ${a}')
	}
	if a < 0 {
		return -a
	}
	return a
}

@[inline; _hot]
pub fn clamp_i64(val i64, min_v i64, max_v i64) i64 {
	if _unlikely_(val < min_v) {
		return min_v
	}
	if _unlikely_(val > max_v) {
		return max_v
	}
	return val
}