# Vanadium

Ada-level runtime safety for the V programming language.

Vanadium adds range-checked integers, bounded lists, safe variables,
checked arithmetic, and design-by-contract to V programs. Every
operation that can fail returns a V result type, making it impossible
to silently ignore errors.

## What it catches

| Bug class                        | Plain V   | V + Vanadium |
|----------------------------------|-----------|--------------|
| Integer overflow/underflow       | Silent    | Error        |
| Division by zero                 | Crash     | Error        |
| Array index out of bounds        | Panic     | Error        |
| Uninitialized variable access    | Zero/empty| Error        |
| Buffer beyond capacity           | Unlimited | Error        |
| Value outside logical range      | Nothing   | Error        |
| Mutation of frozen constant      | Possible  | Error        |
| Invalid input to function        | Manual    | Automatic    |

## Quick start

```v
import vanadium

fn main() {
    // Integer that must stay between 1 and 12
    mut month := vanadium.RangedInt.create(1, 12, 3) or {
        eprintln(err)
        return
    }
    month.assign(13) or { eprintln(err) } // Constraint_Error

    // List with max 3 elements, 1-based indexing
    mut names := vanadium.new_safe_list[string](3) or { return }
    names.append('ben') or { eprintln(err) }
    names.append('mark') or { eprintln(err) }
    names.append('jack') or { eprintln(err) }
    names.append('sarah') or { eprintln(err) } // Capacity_Error
    println(names.at(1) or { return }) // ben

    // Variable that must be initialized before use
    mut x := vanadium.new_safe_var[int]('x')
    x.get() or { eprintln(err) } // Access_Error
    x.set(42) or {}
    println(x.get() or { return }) // 42

    // Overflow-checked math
    vanadium.safe_add_i32(2000000000, 2000000000) or {
        eprintln(err) // Overflow_Error
    }
}
```

## API reference

### RangedInt

Integers constrained to a min..max range. Every mutation is checked.

```v
// Create with range and initial value
mut r := vanadium.RangedInt.create(min, max, initial)!

r.value() i64              // read current value
r.assign(v)!               // set new value (checked)
r.in_range(v) bool         // test if v is in range

r.checked_add(v)!          // addition with overflow + range check
r.checked_sub(v)!          // subtraction
r.checked_mul(v)!          // multiplication
r.checked_div(v)!          // division (also checks zero)

r.str() string             // "5 in [1..12]"
```

Example:

```v
mut temp := vanadium.RangedInt.create(-40, 85, 22)!
temp = temp.checked_add(100) or {
    eprintln(err) // Constraint_Error: 22 + 100 = 122 not in -40..85
    return
}
```

### SafeList

Bounded list with configurable index base and capacity limit.

```v
// 1-based indexing (Ada style), max N elements
mut list := vanadium.new_safe_list[T](capacity)!

// Custom lower bound (e.g. index 5..9)
mut list := vanadium.new_bounded_list[T](capacity, lower_bound)!

list.append(val)!              // add element (checked capacity)
list.append_many(vals)!        // add multiple
list.at(index)!                // read at index (checked bounds)
list.set_at(index, val)!       // write at index (checked bounds)
list.remove_at(index)!         // remove and return (checked)
list.first()!                  // first element
list.last()!                   // last element
list.pop()!                    // remove last
list.safe_slice(from, to)!     // sub-list (checked)
list.find(val) ?int            // search, returns index or none
list.contains(val) bool        // membership test
list.each(fn(idx, val))        // iterate with index
list.len() int                 // current length
list.is_empty() bool
list.is_full() bool
list.remaining_capacity() int
list.upper_bound() int         // highest valid index
```

Example:

```v
mut buf := vanadium.new_safe_list[u8](1024)!
for _ in 0 .. 2000 {
    buf.append(0x41) or {
        eprintln(err) // Capacity_Error: list full (max: 1024)
        break
    }
}
```

### SafeVar

Variable that cannot be read before initialization and can be frozen.

```v
mut v := vanadium.new_safe_var[T]('name')          // uninitialized
mut v := vanadium.new_safe_var_init[T]('name', val) // initialized

v.get()!                  // read (error if not initialized)
v.set(val)!               // write (error if frozen)
v.freeze()!               // make immutable
v.is_initialized() bool
v.is_frozen() bool
```

Example:

```v
mut config := vanadium.new_safe_var_init[string]('db_host', 'localhost')
config.freeze()!
config.set('evil.com') or { eprintln(err) } // Frozen_Error
```

### ValidatedVar

Variable with a custom validator function.

```v
mut v := vanadium.new_validated_var[T]('name', validator_fn, 'error message')

v.set(val)!               // write (runs validator first)
v.get()!                   // read (error if not initialized)
v.is_initialized() bool
```

Example:

```v
mut port := vanadium.new_validated_var[int](
    'port',
    fn (v int) bool { return v >= 1 && v <= 65535 },
    'must be 1..65535'
)
port.set(80)!      // ok
port.set(0) or { eprintln(err) }      // Validation_Error
port.set(99999) or { eprintln(err) }  // Validation_Error
```

### Checked arithmetic

All functions return result types. Silent overflow is impossible.

```v
vanadium.safe_add_i64(a, b)!
vanadium.safe_sub_i64(a, b)!
vanadium.safe_mul_i64(a, b)!
vanadium.safe_div_i64(a, b)!
vanadium.safe_mod_i64(a, b)!

vanadium.safe_add_i32(a, b)!
vanadium.safe_sub_i32(a, b)!
vanadium.safe_mul_i32(a, b)!
vanadium.safe_div_i32(a, b)!

vanadium.safe_pow(base, exp)!
vanadium.safe_negate_i64(a)!
vanadium.safe_abs_i64(a)!
vanadium.clamp_i64(val, min, max) i64   // no error, clamps to range
```

### Contracts

Design-by-contract functions for preconditions, postconditions,
and invariants.

```v
vanadium.require(condition, msg)!         // precondition
vanadium.ensure(condition, msg)!          // postcondition
vanadium.check_invariant(condition, msg)! // invariant
vanadium.require_all(conditions, msgs)!   // multiple preconditions
vanadium.safe_assert(cond, ctx, detail)!  // assertion with context
```

Example:

```v
fn withdraw(mut account Account, amount i64) ! {
    vanadium.require(amount > 0, 'amount must be positive')!
    vanadium.require(account.balance >= amount, 'insufficient funds')!

    account.balance = account.balance.checked_sub(amount)!

    vanadium.ensure(account.balance.value() >= 0, 'balance must not be negative')!
}
```

## Error types

Every error message starts with a category prefix:

| Prefix               | Meaning                                  |
|----------------------|------------------------------------------|
| Range_Error          | min > max when creating a range          |
| Constraint_Error     | value outside allowed range              |
| Overflow_Error       | arithmetic overflow                      |
| Underflow_Error      | arithmetic underflow                     |
| Division_Error       | division or modulo by zero               |
| Index_Error          | list index out of bounds                 |
| Capacity_Error       | list is full or capacity invalid         |
| Empty_Error          | operation on empty list                  |
| Access_Error         | read before initialization               |
| Frozen_Error         | write to frozen variable                 |
| Freeze_Error         | freeze before initialization             |
| Validation_Error     | custom validator rejected value          |
| Precondition_Failed  | require() failed                         |
| Postcondition_Failed | ensure() failed                          |
| Invariant_Violated   | check_invariant() failed                 |
| Assertion_Error      | safe_assert() failed                     |

## Usage pattern

Every function that can fail returns `!T`. You must handle the error:

```v
// Option 1: handle and continue
val := list.at(5) or {
    eprintln(err)
    default_value
}

// Option 2: propagate to caller
val := list.at(5)!

// Option 3: handle and return
val := list.at(5) or {
    eprintln(err)
    return
}
```

The V compiler will not let you ignore the result type. This is the
core safety guarantee: if you use vanadium, you cannot accidentally
skip a safety check.

## Performance

All functions use `@[inline]` attributes. Range checks add a
comparison and branch per operation. In the normal (non-error) path,
the overhead is a single branch prediction that the CPU will almost
always predict correctly. The `_unlikely_` hint on error paths helps
the branch predictor and keeps the fast path in the instruction cache.

For tight loops where you have already validated the range externally,
use plain V operations. Use vanadium at boundaries: user input,
configuration, protocol parsing, financial calculations.

## Limitations

| Feature                    | Vanadium | Ada/SPARK |
|----------------------------|----------|-----------|
| Runtime range checking     | Yes      | Yes       |
| Runtime overflow detection | Yes      | Yes       |
| Design by contract         | Yes      | Yes       |
| Compile-time range proof   | No       | Yes       |
| Formal verification        | No       | Yes       |
| Strong type distinction    | No       | Yes       |
| Thread safety              | Yes      | Yes       |

Vanadium catches bugs at runtime. Ada and SPARK can prove their
absence at compile time. For most applications, runtime checking
is sufficient. For avionics, medical devices, or nuclear systems,
use Ada/SPARK.

## Run tests

```
v test vanadium/
```

## License
![License](https://img.shields.io/badge/License-MIT-blue.svg)
