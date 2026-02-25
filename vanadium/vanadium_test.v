module vanadium

fn test_ranged_create_valid() {
	r := RangedInt.create(1, 12, 6) or { panic(err.str()) }
	assert r.value() == 6
	assert r.min == 1
	assert r.max == 12
}

fn test_ranged_create_at_bounds() {
	r1 := RangedInt.create(0, 100, 0) or { panic(err.str()) }
	assert r1.value() == 0
	r2 := RangedInt.create(0, 100, 100) or { panic(err.str()) }
	assert r2.value() == 100
}

fn test_ranged_create_invalid_range() {
	if _ := RangedInt.create(10, 5, 7) {
		assert false
	}
}

fn test_ranged_create_out_of_range() {
	if _ := RangedInt.create(1, 12, 13) {
		assert false
	}
	if _ := RangedInt.create(1, 12, 0) {
		assert false
	}
}

fn test_ranged_assign_valid() {
	mut r := RangedInt.create(1, 12, 1) or { panic(err.str()) }
	r.assign(12) or { panic(err.str()) }
	assert r.value() == 12
	r.assign(1) or { panic(err.str()) }
	assert r.value() == 1
}

fn test_ranged_assign_invalid() {
	mut r := RangedInt.create(1, 12, 6) or { panic(err.str()) }
	if _ := r.assign(13) {
		assert false
	}
	if _ := r.assign(0) {
		assert false
	}
	assert r.value() == 6
}

fn test_ranged_checked_add() {
	r := RangedInt.create(-10, 10, 5) or { panic(err.str()) }
	r2 := r.checked_add(3) or { panic(err.str()) }
	assert r2.value() == 8
	r3 := r.checked_add(-10) or { panic(err.str()) }
	assert r3.value() == -5
}

fn test_ranged_checked_add_overflow() {
	r := RangedInt.create(-10, 10, 8) or { panic(err.str()) }
	if _ := r.checked_add(5) {
		assert false
	}
}

fn test_ranged_checked_sub() {
	r := RangedInt.create(0, 100, 50) or { panic(err.str()) }
	r2 := r.checked_sub(30) or { panic(err.str()) }
	assert r2.value() == 20
}

fn test_ranged_checked_sub_underflow() {
	r := RangedInt.create(0, 100, 10) or { panic(err.str()) }
	if _ := r.checked_sub(20) {
		assert false
	}
}

fn test_ranged_checked_mul() {
	r := RangedInt.create(-100, 100, 7) or { panic(err.str()) }
	r2 := r.checked_mul(10) or { panic(err.str()) }
	assert r2.value() == 70
}

fn test_ranged_checked_mul_overflow() {
	r := RangedInt.create(-100, 100, 50) or { panic(err.str()) }
	if _ := r.checked_mul(3) {
		assert false
	}
}

fn test_ranged_checked_div() {
	r := RangedInt.create(-100, 100, 84) or { panic(err.str()) }
	r2 := r.checked_div(4) or { panic(err.str()) }
	assert r2.value() == 21
}

fn test_ranged_checked_div_by_zero() {
	r := RangedInt.create(-100, 100, 50) or { panic(err.str()) }
	if _ := r.checked_div(0) {
		assert false
	}
}

fn test_ranged_in_range() {
	r := RangedInt.create(1, 12, 6) or { panic(err.str()) }
	assert r.in_range(1) == true
	assert r.in_range(12) == true
	assert r.in_range(6) == true
	assert r.in_range(0) == false
	assert r.in_range(13) == false
}

fn test_ranged_negative_range() {
	r := RangedInt.create(-40, 85, -20) or { panic(err.str()) }
	assert r.value() == -20
	r2 := r.checked_add(100) or { panic(err.str()) }
	assert r2.value() == 80
}

fn test_ranged_str() {
	r := RangedInt.create(1, 12, 6) or { panic(err.str()) }
	assert r.str() == '6 in [1..12]'
}

fn test_safelist_create() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	assert s.len() == 0
	assert s.capacity == 5
	assert s.is_empty() == true
}

fn test_safelist_create_invalid() {
	if _ := new_safe_list[int](0) {
		assert false
	}
	if _ := new_safe_list[int](-1) {
		assert false
	}
}

fn test_safelist_append_and_at() {
	mut s := new_safe_list[int](3) or { panic(err.str()) }
	s.append(10) or { panic(err.str()) }
	s.append(20) or { panic(err.str()) }
	s.append(30) or { panic(err.str()) }
	assert s.at(1) or { panic(err.str()) } == 10
	assert s.at(2) or { panic(err.str()) } == 20
	assert s.at(3) or { panic(err.str()) } == 30
	assert s.len() == 3
	assert s.is_full() == true
}

fn test_safelist_append_overflow() {
	mut s := new_safe_list[int](2) or { panic(err.str()) }
	s.append(1) or { panic(err.str()) }
	s.append(2) or { panic(err.str()) }
	if _ := s.append(3) {
		assert false
	}
}

fn test_safelist_at_out_of_bounds() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	s.append(10) or { panic(err.str()) }
	s.append(20) or { panic(err.str()) }
	if _ := s.at(0) {
		assert false
	}
	if _ := s.at(3) {
		assert false
	}
	if _ := s.at(-1) {
		assert false
	}
}

fn test_safelist_at_empty() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	if _ := s.at(1) {
		assert false
	}
}

fn test_safelist_set_at() {
	mut s := new_safe_list[int](3) or { panic(err.str()) }
	s.append(10) or { panic(err.str()) }
	s.append(20) or { panic(err.str()) }
	s.set_at(1, 99) or { panic(err.str()) }
	assert s.at(1) or { panic(err.str()) } == 99
	assert s.at(2) or { panic(err.str()) } == 20
}

fn test_safelist_set_at_invalid() {
	mut s := new_safe_list[int](3) or { panic(err.str()) }
	s.append(10) or { panic(err.str()) }
	if _ := s.set_at(5, 99) {
		assert false
	}
}

fn test_safelist_remove_at() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	s.append(10) or { panic(err.str()) }
	s.append(20) or { panic(err.str()) }
	s.append(30) or { panic(err.str()) }
	val := s.remove_at(2) or { panic(err.str()) }
	assert val == 20
	assert s.len() == 2
	assert s.at(1) or { panic(err.str()) } == 10
	assert s.at(2) or { panic(err.str()) } == 30
}

fn test_safelist_first_last() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	s.append(10) or { panic(err.str()) }
	s.append(20) or { panic(err.str()) }
	s.append(30) or { panic(err.str()) }
	assert s.first() or { panic(err.str()) } == 10
	assert s.last() or { panic(err.str()) } == 30
}

fn test_safelist_first_last_empty() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	if _ := s.first() {
		assert false
	}
	if _ := s.last() {
		assert false
	}
}

fn test_safelist_pop() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	s.append(10) or { panic(err.str()) }
	s.append(20) or { panic(err.str()) }
	val := s.pop() or { panic(err.str()) }
	assert val == 20
	assert s.len() == 1
}

fn test_safelist_pop_empty() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	if _ := s.pop() {
		assert false
	}
}

fn test_safelist_append_many() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	s.append_many([1, 2, 3]) or { panic(err.str()) }
	assert s.len() == 3
	if _ := s.append_many([4, 5, 6]) {
		assert false
	}
	s.append_many([4, 5]) or { panic(err.str()) }
	assert s.len() == 5
	assert s.is_full() == true
}

fn test_safelist_bounded() {
	mut s := new_bounded_list[int](3, 5) or { panic(err.str()) }
	s.append(100) or { panic(err.str()) }
	s.append(200) or { panic(err.str()) }
	s.append(300) or { panic(err.str()) }
	assert s.at(5) or { panic(err.str()) } == 100
	assert s.at(6) or { panic(err.str()) } == 200
	assert s.at(7) or { panic(err.str()) } == 300
	if _ := s.at(4) {
		assert false
	}
	if _ := s.at(8) {
		assert false
	}
}

fn test_safelist_find() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	s.append(10) or { panic(err.str()) }
	s.append(20) or { panic(err.str()) }
	s.append(30) or { panic(err.str()) }
	assert s.find(20) or { -1 } == 2
	assert s.find(99) == none
}

fn test_safelist_contains() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	s.append(10) or { panic(err.str()) }
	s.append(20) or { panic(err.str()) }
	assert s.contains(10) == true
	assert s.contains(99) == false
}

fn test_safelist_remaining_capacity() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	assert s.remaining_capacity() == 5
	s.append(1) or { panic(err.str()) }
	assert s.remaining_capacity() == 4
	s.append(2) or { panic(err.str()) }
	s.append(3) or { panic(err.str()) }
	assert s.remaining_capacity() == 2
}

fn test_safelist_slice() {
	mut s := new_safe_list[int](10) or { panic(err.str()) }
	s.append_many([10, 20, 30, 40, 50]) or { panic(err.str()) }
	mut sl := s.safe_slice(2, 4) or { panic(err.str()) }
	assert sl.len() == 3
	assert sl.at(2) or { panic(err.str()) } == 20
	assert sl.at(3) or { panic(err.str()) } == 30
	assert sl.at(4) or { panic(err.str()) } == 40
}

fn test_safelist_slice_invalid() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	s.append_many([10, 20, 30]) or { panic(err.str()) }
	if _ := s.safe_slice(3, 1) {
		assert false
	}
	if _ := s.safe_slice(0, 2) {
		assert false
	}
	if _ := s.safe_slice(1, 5) {
		assert false
	}
}

fn test_safelist_string_type() {
	mut s := new_safe_list[string](3) or { panic(err.str()) }
	s.append('hello') or { panic(err.str()) }
	s.append('world') or { panic(err.str()) }
	assert s.at(1) or { panic(err.str()) } == 'hello'
	assert s.at(2) or { panic(err.str()) } == 'world'
	assert s.contains('hello') == true
	assert s.contains('foo') == false
}

fn test_safelist_each() {
	mut s := new_safe_list[int](5) or { panic(err.str()) }
	s.append_many([10, 20, 30]) or { panic(err.str()) }
	s.each(fn (idx int, val int) {
		if idx == 1 {
			assert val == 10
		}
		if idx == 2 {
			assert val == 20
		}
		if idx == 3 {
			assert val == 30
		}
		assert idx >= 1 && idx <= 3
	})
}

fn test_safevar_uninitialized() {
	mut v := new_safe_var[int]('x')
	assert v.is_initialized() == false
	if _ := v.get() {
		assert false
	}
}

fn test_safevar_set_get() {
	mut v := new_safe_var[int]('x')
	v.set(42) or { panic(err.str()) }
	assert v.is_initialized() == true
	assert v.get() or { panic(err.str()) } == 42
}

fn test_safevar_init() {
	mut v := new_safe_var_init[string]('name', 'test')
	assert v.is_initialized() == true
	assert v.get() or { panic(err.str()) } == 'test'
}

fn test_safevar_freeze() {
	mut v := new_safe_var_init[int]('const_val', 100)
	v.freeze() or { panic(err.str()) }
	assert v.is_frozen() == true
	if _ := v.set(200) {
		assert false
	}
	assert v.get() or { panic(err.str()) } == 100
}

fn test_safevar_freeze_uninitialized() {
	mut v := new_safe_var[int]('x')
	if _ := v.freeze() {
		assert false
	}
}

fn test_validated_var() {
	mut age := new_validated_var[int]('age', fn (v int) bool {
		return v >= 0 && v <= 150
	}, 'must be 0..150')
	age.set(25) or { panic(err.str()) }
	assert age.get() or { panic(err.str()) } == 25
	if _ := age.set(-1) {
		assert false
	}
	if _ := age.set(200) {
		assert false
	}
	assert age.get() or { panic(err.str()) } == 25
}

fn test_validated_var_uninitialized() {
	mut v := new_validated_var[int]('x', fn (v int) bool {
		return true
	}, '')
	if _ := v.get() {
		assert false
	}
}

fn test_require() {
	require(true, 'ok') or { panic(err.str()) }
	if _ := require(false, 'should fail') {
		assert false
	}
}

fn test_ensure() {
	ensure(true, 'ok') or { panic(err.str()) }
	if _ := ensure(false, 'should fail') {
		assert false
	}
}

fn test_check_invariant() {
	check_invariant(true, 'ok') or { panic(err.str()) }
	if _ := check_invariant(false, 'broken') {
		assert false
	}
}

fn test_require_all() {
	require_all([true, true, true], ['a', 'b', 'c']) or { panic(err.str()) }
	if _ := require_all([true, false, true], ['a', 'b', 'c']) {
		assert false
	}
}

fn test_safe_assert() {
	safe_assert(true, 'test', 'ok') or { panic(err.str()) }
	if _ := safe_assert(false, 'test', 'fail') {
		assert false
	}
}

fn test_safe_add_i64() {
	assert (safe_add_i64(1, 2) or { panic(err.str()) }) == 3
	assert (safe_add_i64(-5, 3) or { panic(err.str()) }) == -2
	assert (safe_add_i64(0, 0) or { panic(err.str()) }) == 0
	if _ := safe_add_i64(max_i64_val, 1) {
		assert false
	}
	if _ := safe_add_i64(min_i64_val, -1) {
		assert false
	}
}

fn test_safe_sub_i64() {
	assert (safe_sub_i64(10, 3) or { panic(err.str()) }) == 7
	assert (safe_sub_i64(-5, -3) or { panic(err.str()) }) == -2
	if _ := safe_sub_i64(min_i64_val, 1) {
		assert false
	}
}

fn test_safe_mul_i64() {
	assert (safe_mul_i64(6, 7) or { panic(err.str()) }) == 42
	assert (safe_mul_i64(0, 999) or { panic(err.str()) }) == 0
	assert (safe_mul_i64(-3, 4) or { panic(err.str()) }) == -12
	if _ := safe_mul_i64(max_i64_val, 2) {
		assert false
	}
}

fn test_safe_div_i64() {
	assert (safe_div_i64(10, 3) or { panic(err.str()) }) == 3
	assert (safe_div_i64(-10, 2) or { panic(err.str()) }) == -5
	if _ := safe_div_i64(10, 0) {
		assert false
	}
	if _ := safe_div_i64(min_i64_val, -1) {
		assert false
	}
}

fn test_safe_mod_i64() {
	assert (safe_mod_i64(10, 3) or { panic(err.str()) }) == 1
	if _ := safe_mod_i64(10, 0) {
		assert false
	}
}

fn test_safe_add_i32() {
	assert (safe_add_i32(100, 200) or { panic(err.str()) }) == 300
	if _ := safe_add_i32(2000000000, 1000000000) {
		assert false
	}
}

fn test_safe_sub_i32() {
	assert (safe_sub_i32(100, 50) or { panic(err.str()) }) == 50
	if _ := safe_sub_i32(-2000000000, 1000000000) {
		assert false
	}
}

fn test_safe_mul_i32() {
	assert (safe_mul_i32(100, 200) or { panic(err.str()) }) == 20000
	if _ := safe_mul_i32(100000, 100000) {
		assert false
	}
}

fn test_safe_div_i32() {
	assert (safe_div_i32(10, 3) or { panic(err.str()) }) == 3
	if _ := safe_div_i32(10, 0) {
		assert false
	}
}

fn test_safe_pow() {
	assert (safe_pow(2, 10) or { panic(err.str()) }) == 1024
	assert (safe_pow(2, 0) or { panic(err.str()) }) == 1
	assert (safe_pow(3, 3) or { panic(err.str()) }) == 27
	assert (safe_pow(1, 100) or { panic(err.str()) }) == 1
	assert (safe_pow(0, 5) or { panic(err.str()) }) == 0
	if _ := safe_pow(2, 63) {
		assert false
	}
}

fn test_safe_negate_i64() {
	assert (safe_negate_i64(5) or { panic(err.str()) }) == -5
	assert (safe_negate_i64(-5) or { panic(err.str()) }) == 5
	assert (safe_negate_i64(0) or { panic(err.str()) }) == 0
	if _ := safe_negate_i64(min_i64_val) {
		assert false
	}
}

fn test_safe_abs_i64() {
	assert (safe_abs_i64(5) or { panic(err.str()) }) == 5
	assert (safe_abs_i64(-5) or { panic(err.str()) }) == 5
	assert (safe_abs_i64(0) or { panic(err.str()) }) == 0
	if _ := safe_abs_i64(min_i64_val) {
		assert false
	}
}

fn test_clamp_i64() {
	assert clamp_i64(5, 0, 10) == 5
	assert clamp_i64(-5, 0, 10) == 0
	assert clamp_i64(15, 0, 10) == 10
	assert clamp_i64(0, 0, 10) == 0
	assert clamp_i64(10, 0, 10) == 10
}

fn test_full_workflow() {
	mut balance := RangedInt.create(0, 1000000, 5000) or { panic(err.str()) }
	mut history := new_safe_list[string](100) or { panic(err.str()) }

	balance = balance.checked_add(1500) or { panic(err.str()) }
	history.append('deposit 1500') or { panic(err.str()) }
	assert balance.value() == 6500

	balance = balance.checked_sub(2000) or { panic(err.str()) }
	history.append('withdraw 2000') or { panic(err.str()) }
	assert balance.value() == 4500

	if _ := balance.checked_sub(5000) {
		assert false
	}

	assert history.len() == 2
	assert history.at(1) or { panic(err.str()) } == 'deposit 1500'
	assert history.at(2) or { panic(err.str()) } == 'withdraw 2000'
}