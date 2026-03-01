module main

import time
import vanadium

struct Product {
	id    int
	name  string
	price i64
mut:
	stock vanadium.RangedInt
}

struct Customer {
	id   int
	name string
mut:
	email   vanadium.ValidatedVar[string]
	age     vanadium.ValidatedVar[int]
	balance vanadium.RangedInt
	loyalty vanadium.RangedInt
}

struct OrderItem {
	product_name string
	quantity     int
	unit_price   i64
	total        i64
}

struct Transaction {
	description string
	amount      i64
	balance     i64
}

fn create_product(id int, name string, price i64, stock int) !Product {
	vanadium.require(price > 0, 'price must be positive')!
	vanadium.require(stock >= 0, 'stock cannot be negative')!
	
	stk := vanadium.RangedInt.create(0, 10000, stock)!

	return Product{
		id:    id
		name:  name
		price: price
		stock: stk
	}
}

fn create_customer(id int, name string, email string, age int, initial_balance i64) !Customer {
	vanadium.require(name.len > 0, 'name cannot be empty')!
	vanadium.require(initial_balance >= 0, 'balance cannot be negative')!
	bal := vanadium.RangedInt.create(0, 99999999, initial_balance)!
	loy := vanadium.RangedInt.create(0, 100000, 0)!

	mut c := Customer{
		id:      id
		name:    name
		email:   vanadium.new_validated_var[string]('email', fn (v string) bool {
			return v.contains('@') && v.contains('.') && v.len >= 5
		}, 'invalid email format')
		age:     vanadium.new_validated_var[int]('age', fn (v int) bool {
			return v >= 13 && v <= 120
		}, 'age must be 13..120')
		balance: bal
		loyalty: loy
	}

	c.email.set(email)!
	c.age.set(age)!
	return c
}

fn calculate_discount(loyalty_points i64, item_total i64) !i64 {
	rate := vanadium.clamp_i64(loyalty_points / 1000, 0, 20)
	discount := vanadium.safe_mul_i64(item_total, rate)!
	return vanadium.safe_div_i64(discount, 100)!
}

fn calculate_tax(amount i64) !i64 {
	tax_amount := vanadium.safe_mul_i64(amount, 9)!
	return vanadium.safe_div_i64(tax_amount, 100)!
}

fn print_separator() {
	println('${'─'.repeat(60)}')
}

fn print_header(title string) {
	print_separator()
	println('  ${title}')
	print_separator()
}

fn main() {
	print_header('ADMIN AUTHENTICATION (ANTI-TIMING ATTACK)')
	
	mut login_guard := vanadium.new_timing_guard_ms(500) or { panic(err.str()) }
	
	real_admin_token := 'secure_admin_hash_12345'
	user_input := 'secure_admin_hash_99999'
	
	println('  Checking admin credentials...')
	
	is_admin := vanadium.constant_time_eq_strings(user_input, real_admin_token)
	
	time.sleep(120 * time.millisecond) // database checking time
	
	report := login_guard.pad_report()
	
	if is_admin {
		println('  [✓] Login Successful')
	} else {
		println('  [✗] Login Failed (Invalid Token)')
	}
	println('  [i] Auth Timing: ${report}')


	print_header('STORE MANAGEMENT SYSTEM')

	mut store_name := vanadium.new_safe_var_init[string]('store_name', 'TechVault Electronics')
	store_name.freeze() or { panic(err.str()) }

	println('  Store: ${store_name.get() or { panic(err.str()) }}')

	mut max_daily_sales := vanadium.new_safe_var_init[int]('max_daily_sales', 500)
	max_daily_sales.freeze() or { panic(err.str()) }

	mut daily_revenue := vanadium.RangedInt.create(0, 99999999, 0) or { panic(err.str()) }
	mut total_orders := vanadium.RangedInt.create(0, 10000, 0) or { panic(err.str()) }

	print_header('PRODUCT CATALOG')

	mut products := vanadium.new_safe_list[Product](50) or { panic(err.str()) }

	p1 := create_product(1, 'Mechanical Keyboard', 8999, 45) or { panic(err.str()) }
	p2 := create_product(2, 'Wireless Mouse', 3499, 120) or { panic(err.str()) }
	p3 := create_product(3, 'USB-C Hub', 4599, 30) or { panic(err.str()) }
	p4 := create_product(4, '27" Monitor', 29999, 15) or { panic(err.str()) }
	p5 := create_product(5, 'Webcam HD', 5999, 60) or { panic(err.str()) }
	p6 := create_product(6, 'Desk Lamp LED', 2499, 80) or { panic(err.str()) }
	p7 := create_product(7, 'Laptop Stand', 3999, 55) or { panic(err.str()) }
	p8 := create_product(8, 'Noise Cancel Headphones', 15999, 25) or { panic(err.str()) }

	products.append(p1) or { panic(err.str()) }
	products.append(p2) or { panic(err.str()) }
	products.append(p3) or { panic(err.str()) }
	products.append(p4) or { panic(err.str()) }
	products.append(p5) or { panic(err.str()) }
	products.append(p6) or { panic(err.str()) }
	products.append(p7) or { panic(err.str()) }
	products.append(p8) or { panic(err.str()) }

	println('  Loaded ${products.len()} products')
	println('')

	for i in 1 .. products.len() + 1 {
		mut p := products.at(i) or { continue }
		price_dollars := vanadium.safe_div_i64(p.price, 100) or { continue }
		price_cents := vanadium.safe_mod_i64(p.price, 100) or { continue }
		println('  [${p.id}] ${p.name:-30s} \$${price_dollars}.${price_cents:02} | Stock: ${p.stock.value()}')
	}

	print_header('CUSTOMER REGISTRATION')

	mut customers := vanadium.new_safe_list[Customer](100) or { panic(err.str()) }

	c1 := create_customer(1, 'Alex Thompson', 'alex.t@email.com', 28, 5000000) or {
		panic(err.str())
	}
	c2 := create_customer(2, 'Maria Garcia', 'maria.g@email.com', 34, 2500000) or {
		panic(err.str())
	}
	c3 := create_customer(3, 'James Wilson', 'james.w@email.com', 45, 8000000) or {
		panic(err.str())
	}
	c4 := create_customer(4, 'Sophie Chen', 'sophie.c@email.com', 22, 1500000) or {
		panic(err.str())
	}

	customers.append(c1) or { panic(err.str()) }
	customers.append(c2) or { panic(err.str()) }
	customers.append(c3) or { panic(err.str()) }
	customers.append(c4) or { panic(err.str()) }

	println('  Registered ${customers.len()} customers')
	println('')

	for i in 1 .. customers.len() + 1 {
		mut c := customers.at(i) or { continue }
		email := c.email.get() or { 'N/A' }
		age := c.age.get() or { 0 }
		bal_dollars := vanadium.safe_div_i64(c.balance.value(), 100) or { continue }
		bal_cents := vanadium.safe_mod_i64(c.balance.value(), 100) or { continue }
		println('  [${c.id}] ${c.name:-20s} | ${email:-25s} | Age: ${age} | Balance: \$${bal_dollars}.${bal_cents:02}')
	}

	print_header('INVALID REGISTRATION ATTEMPTS')

	if _ := create_customer(99, 'Young Kid', 'kid@test.com', 10, 100000) {
		println('  ERROR: should have rejected age 10')
	} else {
		println('  Rejected: age 10 (must be 13..120)')
	}

	mut bad_customer := create_customer(98, 'Bad Email', 'valid@test.com', 20, 100000) or {
		panic(err.str())
	}
	if _ := bad_customer.email.set('not-an-email') {
		println('  ERROR: should have rejected bad email')
	} else {
		println('  Rejected: invalid email "not-an-email"')
	}

	if _ := create_product(99, 'Bad Product', -100, 10) {
		println('  ERROR: should have rejected negative price')
	} else {
		println('  Rejected: negative price')
	}

	print_header('ORDER PROCESSING - Alex Thompson')

	mut order_items := vanadium.new_safe_list[OrderItem](20) or { panic(err.str()) }
	mut order_subtotal := vanadium.RangedInt.create(0, 99999999, 0) or { panic(err.str()) }

	mut alex := customers.at(1) or { panic(err.str()) }
	println('  Customer: ${alex.name}')
	bal_d := vanadium.safe_div_i64(alex.balance.value(), 100) or { panic(err.str()) }
	bal_c := vanadium.safe_mod_i64(alex.balance.value(), 100) or { panic(err.str()) }
	println('  Balance: \$${bal_d}.${bal_c:02}')
	println('')

	keyboard := products.at(1) or { panic(err.str()) }
	kb_qty := 2
	vanadium.require(keyboard.stock.in_range(keyboard.stock.value()), 'stock corrupted')!
	kb_total := vanadium.safe_mul_i64(keyboard.price, kb_qty)!

	order_items.append(OrderItem{
		product_name: keyboard.name
		quantity:     kb_qty
		unit_price:   keyboard.price
		total:        kb_total
	}) or { panic(err.str()) }
	order_subtotal = order_subtotal.checked_add(kb_total)!

	mouse := products.at(2) or { panic(err.str()) }
	ms_qty := 3
	ms_total := vanadium.safe_mul_i64(mouse.price, ms_qty)!

	order_items.append(OrderItem{
		product_name: mouse.name
		quantity:     ms_qty
		unit_price:   mouse.price
		total:        ms_total
	}) or { panic(err.str()) }
	order_subtotal = order_subtotal.checked_add(ms_total)!

	println('  Order Items:')
	for i in 1 .. order_items.len() + 1 {
		item := order_items.at(i) or { continue }
		up_d := vanadium.safe_div_i64(item.unit_price, 100) or { continue }
		up_c := vanadium.safe_mod_i64(item.unit_price, 100) or { continue }
		t_d := vanadium.safe_div_i64(item.total, 100) or { continue }
		t_c := vanadium.safe_mod_i64(item.total, 100) or { continue }
		println('    ${i}. ${item.product_name:-30s} x${item.quantity}  @\$${up_d}.${up_c:02}  = \$${t_d}.${t_c:02}')
	}

	println('')
	sub_d := vanadium.safe_div_i64(order_subtotal.value(), 100) or { panic(err.str()) }
	sub_c := vanadium.safe_mod_i64(order_subtotal.value(), 100) or { panic(err.str()) }
	println('  Subtotal:      \$${sub_d}.${sub_c:02}')

	loyalty_discount := calculate_discount(alex.loyalty.value(), order_subtotal.value()) or {
		panic(err.str())
	}
	disc_d := vanadium.safe_div_i64(loyalty_discount, 100) or { panic(err.str()) }
	disc_c := vanadium.safe_mod_i64(loyalty_discount, 100) or { panic(err.str()) }
	println('  Loyalty Disc:  -\$${disc_d}.${disc_c:02} (${alex.loyalty.value()} pts)')

		println('  Checking Promo Code...')
	mut promo_state := map[string]bool{}
	promo_state['valid'] = false
	vanadium.timed_call_ms(200, fn [mut promo_state] () {
		user_promo := 'BLACKFRIDAY'
		db_promo := 'WINTERSALE2024'
		promo_state['valid'] = vanadium.constant_time_eq_strings(user_promo, db_promo)
		time.sleep(30 * time.millisecond)
	}) or { panic(err.str()) }

	if !promo_state['valid'] {
		println('  [i] Promo code rejected (Time safely padded to 200ms)')
	} else {
		println('  [i] Promo code accepted!')
	}

	after_discount := vanadium.safe_sub_i64(order_subtotal.value(), loyalty_discount)!
	tax := calculate_tax(after_discount) or { panic(err.str()) }
	tax_d := vanadium.safe_div_i64(tax, 100) or { panic(err.str()) }
	tax_c := vanadium.safe_mod_i64(tax, 100) or { panic(err.str()) }
	println('  Tax (9%%):      \$${tax_d}.${tax_c:02}')

	grand_total := vanadium.safe_add_i64(after_discount, tax)!
	gt_d := vanadium.safe_div_i64(grand_total, 100) or { panic(err.str()) }
	gt_c := vanadium.safe_mod_i64(grand_total, 100) or { panic(err.str()) }
	println('  Grand Total:   \$${gt_d}.${gt_c:02}')

	print_header('PAYMENT PROCESSING (TIMING PROTECTED GATEWAY)')
	
	mut gateway_guard := vanadium.new_timing_guard_ms(800) or { panic(err.str()) }
	
	println('  Connecting to secure bank gateway...')
	time.sleep(250 * time.millisecond) // pinging time

	if alex.balance.value() >= grand_total {
		alex.balance = alex.balance.checked_sub(grand_total) or { panic(err.str()) }
		new_bal_d := vanadium.safe_div_i64(alex.balance.value(), 100) or { panic(err.str()) }
		new_bal_c := vanadium.safe_mod_i64(alex.balance.value(), 100) or { panic(err.str()) }
		println('  [✓] Payment successful!')
		println('  Charged: \$${gt_d}.${gt_c:02}')
		println('  Remaining balance: \$${new_bal_d}.${new_bal_c:02}')

		loyalty_earned := vanadium.safe_div_i64(grand_total, 100) or { panic(err.str()) }
		alex.loyalty = alex.loyalty.checked_add(loyalty_earned) or { panic(err.str()) }
		println('  Loyalty points earned: +${loyalty_earned} (total: ${alex.loyalty.value()})')

		daily_revenue = daily_revenue.checked_add(grand_total) or { panic(err.str()) }
		total_orders = total_orders.checked_add(1) or { panic(err.str()) }
	} else {
		println('  [✗] Payment FAILED: insufficient funds')
	}
	
	gateway_guard.pad()
	println('  [i] Payment process completed securely in ${gateway_guard.target.milliseconds()}ms')

	vanadium.ensure(alex.balance.value() >= 0, 'balance must never be negative') or {
		panic(err.str())
	}

	print_header('STOCK UPDATE')

	mut kb_product := products.at(1) or { panic(err.str()) }
	old_stock := kb_product.stock.value()
	kb_product.stock = kb_product.stock.checked_sub(kb_qty) or { panic(err.str()) }
	println('  ${kb_product.name}: ${old_stock} -> ${kb_product.stock.value()}')
	products.set_at(1, kb_product) or { panic(err.str()) }

	mut ms_product := products.at(2) or { panic(err.str()) }
	old_stock2 := ms_product.stock.value()
	ms_product.stock = ms_product.stock.checked_sub(ms_qty) or { panic(err.str()) }
	println('  ${ms_product.name}: ${old_stock2} -> ${ms_product.stock.value()}')
	products.set_at(2, ms_product) or { panic(err.str()) }

	print_header('TRANSACTION HISTORY')

	mut transactions := vanadium.new_safe_list[Transaction](1000) or { panic(err.str()) }

	transactions.append(Transaction{
		description: 'Order #1 - Alex Thompson (2 items)'
		amount:      grand_total
		balance:     alex.balance.value()
	}) or { panic(err.str()) }

	print_header('FAILED ORDER - Sophie Chen')

	mut sophie := customers.at(4) or { panic(err.str()) }
	sb_d := vanadium.safe_div_i64(sophie.balance.value(), 100) or { panic(err.str()) }
	sb_c := vanadium.safe_mod_i64(sophie.balance.value(), 100) or { panic(err.str()) }
	println('  Customer: ${sophie.name}')
	println('  Balance: \$${sb_d}.${sb_c:02}')
	println('')

	huge_order := vanadium.safe_mul_i64(p4.price, 10)!
	ho_d := vanadium.safe_div_i64(huge_order, 100) or { panic(err.str()) }
	ho_c := vanadium.safe_mod_i64(huge_order, 100) or { panic(err.str()) }
	println('  Trying to buy 10x monitors = \$${ho_d}.${ho_c:02}')

	if sophie.balance.value() < huge_order {
		shortfall := vanadium.safe_sub_i64(huge_order, sophie.balance.value())!
		sf_d := vanadium.safe_div_i64(shortfall, 100) or { panic(err.str()) }
		sf_c := vanadium.safe_mod_i64(shortfall, 100) or { panic(err.str()) }
		println('  DECLINED: insufficient funds (short by \$${sf_d}.${sf_c:02})')
	}

	print_header('SAFE ARITHMETIC DEMOS')

	println('  Power: 2^20 = ${vanadium.safe_pow(2, 20) or { panic(err.str()) }}')
	println('  Power: 3^10 = ${vanadium.safe_pow(3, 10) or { panic(err.str()) }}')

	if _ := vanadium.safe_pow(2, 63) {
		println('  ERROR: should overflow')
	} else {
		println('  2^63 correctly detected as overflow')
	}

	println('  Abs(-999) = ${vanadium.safe_abs_i64(-999) or { panic(err.str()) }}')
	println('  Negate(42) = ${vanadium.safe_negate_i64(42) or { panic(err.str()) }}')
	println('  Clamp(150, 0, 100) = ${vanadium.clamp_i64(150, 0, 100)}')

	print_header('CONTRACT VERIFICATION')

	vanadium.require_all(
		[
			daily_revenue.value() >= 0,
			total_orders.value() >= 0,
			products.len() > 0,
			customers.len() > 0,
		],
		[
			'revenue must be non-negative',
			'orders must be non-negative',
			'must have products',
			'must have customers',
		]
	) or { panic(err.str()) }
	println('  All preconditions passed')

	vanadium.check_invariant(daily_revenue.value() >= 0, 'revenue invariant') or {
		panic(err.str())
	}
	vanadium.check_invariant(total_orders.value() <= max_daily_sales.get() or { 500 },
		'daily sales limit invariant') or { panic(err.str()) }
	println('  All invariants hold')

	print_header('DAILY SUMMARY')

	rev_d := vanadium.safe_div_i64(daily_revenue.value(), 100) or { panic(err.str()) }
	rev_c := vanadium.safe_mod_i64(daily_revenue.value(), 100) or { panic(err.str()) }
	println('  Total Orders:  ${total_orders.value()}')
	println('  Total Revenue: \$${rev_d}.${rev_c:02}')
	println('  Transactions:  ${transactions.len()}')
	println('  Products:      ${products.len()}')
	println('  Customers:     ${customers.len()}')

	print_separator()
	println('  All operations completed safely!')
	print_separator()
	
	print_header('HARDWARE ATTACK PROTECTION DEMO')
	println('  [Anti-Rowhammer] Hardened Boolean (is_admin):')

	mut is_admin_2 := vanadium.new_hardened_bool(false)
	admin_check := is_admin_2.get() or { panic(err.str()) }
	println('    is_admin = ${admin_check} (integrity: ${is_admin_2.verify()})')
	
	corrupted_admin := vanadium.simulate_corrupted_bool()
	println('    Simulated Rowhammer attack on is_admin...')
	if _ := corrupted_admin.get() {
		println('    DANGER: corruption not detected!')
	} else {
		println('    [BLOCKED] Memory corruption detected! Access denied.')
	}
	
	println('')
	println('  [Anti-Rowhammer] Hardened Critical Balance:')

	mut vault_balance := vanadium.HardenedRangedInt.create(0, 99999999, 5000000) or {
		panic(err.str())
	}
	vb := vault_balance.value() or { panic(err.str()) }
	vb_d := vanadium.safe_div_i64(vb, 100) or { panic(err.str()) }
	vb_c := vanadium.safe_mod_i64(vb, 100) or { panic(err.str()) }
	println('    Vault balance: \$${vb_d}.${vb_c:02} (integrity OK)')

	vault_balance = vault_balance.checked_sub(1500000) or { panic(err.str()) }
	vb2 := vault_balance.value() or { panic(err.str()) }
	vb2_d := vanadium.safe_div_i64(vb2, 100) or { panic(err.str()) }
	vb2_c := vanadium.safe_mod_i64(vb2, 100) or { panic(err.str()) }
	println('    After withdrawal: \$${vb2_d}.${vb2_c:02} (integrity OK)')
	
	corrupted_balance := vanadium.simulate_corrupted_ranged(99000000, 5000000, 0, 99999999)
	println('    Simulated Rowhammer on vault balance...')
	if _ := corrupted_balance.value() {
		println('    DANGER: corruption not detected!')
	} else {
		println('    [BLOCKED] Balance corruption detected! Transaction halted.')
	}
	
	println('')
	println('  [Anti-Rowhammer] Hardened Transaction Counter:')

	mut h_counter := vanadium.new_hardened_i64(0)
	h_counter = h_counter.checked_add(1) or { panic(err.str()) }
	h_counter = h_counter.checked_add(1) or { panic(err.str()) }
	h_counter = h_counter.checked_add(1) or { panic(err.str()) }
	println('    Transactions processed: ${h_counter.get() or { panic(err.str()) }} (integrity: ${h_counter.verify()})')
	
	corrupted_counter := vanadium.simulate_corrupted_i64(0, 3)
	println('    Simulated Rowhammer on counter...')
	if _ := corrupted_counter.get() {
		println('    DANGER: corruption not detected!')
	} else {
		println('    [BLOCKED] Counter corruption detected!')
	}
	
	println('')
	println('  [Anti-Spectre] Branchless Index Masking:')

	test_indices := [0, 5, 9, 10, -1, 100]
	array_len := 10
	for idx in test_indices {
		masked := vanadium.safe_index_mask(idx, array_len)
		status := if idx >= 0 && idx < array_len { 'PASS' } else { 'MASKED->0' }
		println('    index=${idx:4d}  masked=${masked}  [${status}]')
	}
	
	print_header('FORMAL PROOFS (debug-only)')

	mut prover := vanadium.new_prover('store system proofs')
	
	prover.prove_commutative('addition is commutative', -100, 100, fn (a i64, b i64) i64 {
		return a + b
	})

	prover.prove_commutative('multiplication is commutative', -50, 50, fn (a i64, b i64) i64 {
		return a * b
	})

	prover.prove_associative('addition is associative', -10, 10, fn (a i64, b i64) i64 {
		return a + b
	})

	prover.prove_associative('multiplication is associative', -5, 5, fn (a i64, b i64) i64 {
		return a * b
	})
	
	prover.prove_for_range('price is always positive after markup', 1, 10000, fn (x i64) bool {
		markup := x + x / 10
		return markup > 0
	})

	prover.prove_for_range('tax is never negative', 0, 99999, fn (amount i64) bool {
		tax := amount * 9 / 100
		return tax >= 0
	})

	prover.prove_for_range('tax is less than amount', 1, 99999, fn (amount i64) bool {
		tax := amount * 9 / 100
		return tax < amount
	})

	prover.prove_for_range('discount rate clamped to 0..20', 0, 500000, fn (loyalty i64) bool {
		rate := vanadium.clamp_i64(loyalty / 1000, 0, 20)
		return rate >= 0 && rate <= 20
	})

	prover.prove_for_range('discount never exceeds subtotal', 1, 50000, fn (subtotal i64) bool {
		discount := subtotal * 20 / 100
		return discount <= subtotal
	})
	
	prover.prove_for_pairs('payment leaves non-negative balance', 0, 100, fn (balance i64, charge i64) bool {
		if charge > balance {
			return true
		}
		return balance - charge >= 0
	})

	prover.prove_for_range('loyalty points from payment are non-negative', 0, 99999, fn (total i64) bool {
		earned := total / 100
		return earned >= 0
	})

	prover.prove_monotonic('tax grows with amount', 0, 50000, fn (x i64) i64 {
		return x * 9 / 100
	})

	prover.prove_monotonic('loyalty earnings grow with spend', 0, 99999, fn (x i64) i64 {
		return x / 100
	})

	prover.prove_monotonic('stock index is monotonic', 0, 10000, fn (x i64) i64 {
		return x
	})
	
	prover.prove_idempotent('clamp is idempotent', -200, 200, fn (x i64) i64 {
		return vanadium.clamp_i64(x, 0, 100)
	})

	prover.prove_idempotent('abs is idempotent', -500, 500, fn (x i64) i64 {
		v := vanadium.safe_abs_i64(x) or { return 0 }
		return v
	})

	prover.prove_idempotent('discount rate clamp is idempotent', -100, 100000, fn (x i64) i64 {
		return vanadium.clamp_i64(x / 1000, 0, 20)
	})
	
	prover.prove_involution('negate is involution', -1000, 1000, fn (x i64) i64 {
		return -x
	})
	
	prover.prove_injective('price times quantity is injective for fixed price', 0, 200, fn (qty i64) i64 {
		return 8999 * qty // keyboard price * qty
	})

	prover.prove_injective('double is injective', 0, 500, fn (x i64) i64 {
		return 2 * x
	})
	
	prover.prove_exists('there exists a discount rate above 0', 1000, 100000, fn (loyalty i64) bool {
		rate := vanadium.clamp_i64(loyalty / 1000, 0, 20)
		return rate > 0
	})

	prover.prove_exists('there exists a price where tax is at least 1', 1, 1000, fn (price i64) bool {
		tax := price * 9 / 100
		return tax >= 1
	})
	
	prover.prove_by_samples('balance stays in range after operations', 0, 99999999, 10000, fn (v i64) bool {
		return v >= 0 && v <= 99999999
	})

	prover.prove_by_samples('stock subtraction never wraps', 0, 10000, 5000, fn (stock i64) bool {
		if stock >= 1 {
			return stock - 1 >= 0
		}
		return true
	})
	
	valid_age := vanadium.RangedIntP{min: 13, max: 120}
	prover.prove_ranged('all valid ages pass age check', valid_age, fn (age i64) bool {
		return age >= 13 && age <= 120
	})

	valid_stock := vanadium.RangedIntP{min: 0, max: 10000}
	prover.prove_ranged('stock is non-negative', valid_stock, fn (s i64) bool {
		return s >= 0
	})
	
	println(prover.report())

	if prover.all_passed() {
		println('  All formal proofs passed.')
	} else {
		println('  WARNING: ${prover.failed_count()} proof(s) failed!')
	}
	
	print_header('LOOP PROOFS (debug-only)')
	
	mut lp_stock := vanadium.new_loop_proof('stock deduction')
	mut remaining := i64(45)
	mut to_deduct := i64(10)
	for to_deduct > 0 {
		lp_stock.iteration()
		lp_stock.check_invariant(remaining >= 0, 'stock must be non-negative') or {
			println('  LOOP ERROR: ${err}')
			break
		}
		lp_stock.check_invariant(to_deduct > 0, 'deduction counter must be positive') or {
			println('  LOOP ERROR: ${err}')
			break
		}
		lp_stock.check_variant(to_deduct) or {
			println('  LOOP ERROR: ${err}')
			break
		}
		remaining--
		to_deduct--
	}
	stock_proof := lp_stock.finish()
	println('  ${stock_proof.name}: passed=${stock_proof.passed}')
	println('    ${stock_proof.detail}')
	
	mut lp_revenue := vanadium.new_loop_proof('revenue accumulation')
	order_amounts := [i64(28495), 15000, 42000, 8999, 3499]
	mut acc_revenue := i64(0)
	mut rev_countdown := i64(order_amounts.len)
	for i, amt in order_amounts {
		lp_revenue.iteration()
		lp_revenue.check_invariant(acc_revenue >= 0, 'accumulated revenue must be non-negative') or {
			println('  LOOP ERROR: ${err}')
			break
		}
		lp_revenue.check_invariant(amt > 0, 'order amount must be positive') or {
			println('  LOOP ERROR: ${err}')
			break
		}
		lp_revenue.check_variant(rev_countdown) or {
			println('  LOOP ERROR: ${err}')
			break
		}
		acc_revenue += amt
		rev_countdown--
		_ = i
	}
	rev_proof := lp_revenue.finish()
	println('  ${rev_proof.name}: passed=${rev_proof.passed}')
	println('    ${rev_proof.detail}')
	
	mut lp_iter := vanadium.new_loop_proof('customer iteration')
	mut cust_remaining := i64(customers.len())
	for ci in 1 .. customers.len() + 1 {
		lp_iter.iteration()
		lp_iter.check_invariant(cust_remaining > 0, 'remaining must be positive') or {
			println('  LOOP ERROR: ${err}')
			break
		}
		lp_iter.check_variant(cust_remaining) or {
			println('  LOOP ERROR: ${err}')
			break
		}
		cust_remaining--
		_ = ci
	}
	iter_proof := lp_iter.finish()
	println('  ${iter_proof.name}: passed=${iter_proof.passed}')
	println('    ${iter_proof.detail}')
	
	print_header('STATE MACHINE: ORDER LIFECYCLE')

	mut order_sm := vanadium.new_state_machine('order lifecycle', 0)
	order_sm.add_state(0, 'created')
	order_sm.add_state(1, 'validated')
	order_sm.add_state(2, 'payment_pending')
	order_sm.add_state(3, 'paid')
	order_sm.add_state(4, 'shipped')
	order_sm.add_state(5, 'delivered')
	order_sm.add_state(6, 'cancelled')
	order_sm.add_state(7, 'refunded')

	order_sm.add_transition(0, 1) // created -> validated
	order_sm.add_transition(0, 6) // created -> cancelled
	order_sm.add_transition(1, 2) // validated -> payment_pending
	order_sm.add_transition(1, 6) // validated -> cancelled
	order_sm.add_transition(2, 3) // payment_pending -> paid
	order_sm.add_transition(2, 6) // payment_pending -> cancelled
	order_sm.add_transition(3, 4) // paid -> shipped
	order_sm.add_transition(3, 7) // paid -> refunded
	order_sm.add_transition(4, 5) // shipped -> delivered
	order_sm.add_transition(4, 7) // shipped -> refunded
	order_sm.add_transition(5, 7) // delivered -> refunded
	
	println('  Simulating order: created -> validated -> payment -> paid -> shipped -> delivered')
	order_sm.step(1) or { println('  ERROR: ${err}') }
	println('    State: ${order_sm.state_name(order_sm.current)}')
	order_sm.step(2) or { println('  ERROR: ${err}') }
	println('    State: ${order_sm.state_name(order_sm.current)}')
	order_sm.step(3) or { println('  ERROR: ${err}') }
	println('    State: ${order_sm.state_name(order_sm.current)}')
	order_sm.step(4) or { println('  ERROR: ${err}') }
	println('    State: ${order_sm.state_name(order_sm.current)}')
	order_sm.step(5) or { println('  ERROR: ${err}') }
	println('    State: ${order_sm.state_name(order_sm.current)}')
	
	println('')
	println('  Attempting invalid: delivered -> created')
	order_sm.step(0) or {
		println('    BLOCKED: ${err}')
	}
	
	println('  Attempting invalid: delivered -> shipped')
	order_sm.step(4) or {
		println('    BLOCKED: ${err}')
	}
	
	println('  Attempting valid: delivered -> refunded')
	order_sm.step(7) or { println('  ERROR: ${err}') }
	println('    State: ${order_sm.state_name(order_sm.current)}')

	println('')
	
	println('  Reachability analysis (debug-only):')
	states_to_check := [0, 1, 2, 3, 4, 5, 6, 7]
	for sid in states_to_check {
		reachable := order_sm.verify_reachable(sid)
		println('    ${order_sm.state_name(sid)}: reachable=${reachable}')
	}

	println('')
	order_sm.verify_no_deadlock() or {
		println('  Deadlock detected: ${err}')
	}

	println('  Trace: ${order_sm.trace}')
	order_sm.verify_trace([0, 1, 2, 3, 4, 5, 7]) or {
		println('  Trace mismatch: ${err}')
	}
	
	print_header('STATE MACHINE: CUSTOMER ACCOUNT')

	mut acct_sm := vanadium.new_state_machine('customer account', 0)
	acct_sm.add_state(0, 'registered')
	acct_sm.add_state(1, 'email_verified')
	acct_sm.add_state(2, 'active')
	acct_sm.add_state(3, 'suspended')
	acct_sm.add_state(4, 'closed')

	acct_sm.add_transition(0, 1) // registered -> email_verified
	acct_sm.add_transition(1, 2) // email_verified -> active
	acct_sm.add_transition(2, 3) // active -> suspended
	acct_sm.add_transition(3, 2) // suspended -> active
	acct_sm.add_transition(2, 4) // active -> closed
	acct_sm.add_transition(3, 4) // suspended -> closed

	println('  Account flow: register -> verify -> activate -> suspend -> reactivate -> close')
	acct_sm.step(1) or { println('  ERROR: ${err}') }
	println('    ${acct_sm.state_name(acct_sm.current)}')
	acct_sm.step(2) or { println('  ERROR: ${err}') }
	println('    ${acct_sm.state_name(acct_sm.current)}')
	acct_sm.step(3) or { println('  ERROR: ${err}') }
	println('    ${acct_sm.state_name(acct_sm.current)}')
	acct_sm.step(2) or { println('  ERROR: ${err}') }
	println('    ${acct_sm.state_name(acct_sm.current)}')
	acct_sm.step(4) or { println('  ERROR: ${err}') }
	println('    ${acct_sm.state_name(acct_sm.current)}')

	println('')
	println('  Attempting invalid: closed -> active')
	acct_sm.step(2) or {
		println('    BLOCKED: ${err}')
	}

	acct_sm.verify_no_deadlock() or {
		println('  Deadlock: ${err}')
	}

	println('  Trace: ${acct_sm.trace}')

	print_separator()
	println('  All proofs and state machines completed.')
	print_separator()
}