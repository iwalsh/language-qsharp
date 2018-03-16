Still TODO
  - Method calls

  - Tuple-deconstruction "let" statements

  - semicolons

  - research numeric literal recognized suffixes

  - array literals [1;2;3]
  - array slicing  a[1..5]
  - array indexing  a[0]

  - Keywords: adjoint, self, auto, controlled

  - function definition

  - operation definition

/// # Summary
/// Given an operation and a target for that operation,
/// applies the given operation twice.
///
/// # Input
/// ## op
/// The operation to be applied.
/// ## target
/// The target to which the operation is to be applied.
///
/// # Type Parameters
/// ## 'T
/// The type expected by the given operation as its input.
///
/// # Example
/// ```Q#
/// // Should be equivalent to the identity.
/// ApplyTwice(H, qubit);
/// ```
///
/// # See Also
/// - Microsoft.Quantum.Primitive.H
/// - @"MyFile"
operation ApplyTwice<'T>(op : ('T => ()), target : 'T) : () {
    // Comment
    body {
        op(target);  // Another comment
        op(target);
    }
}

// Test `return`
return 1;
return ();
return (results, qubits);

// Test `let`
let (a, (b, c)) = (1, (2, 3));
let (x, y) = (1, (2, 3));

// Test `mutable`
mutable counter = 0;

// Test `set`
set counter = counter + 1;
set result[1] = One;

// Test `new`
mutable ary = new Int[i+1];

// Test `for`
for (index in 0 .. n-2) {
    set results[index] = Measure([PauliX], [qubits[index]]);
}

// Test `repeat`
using ancilla = Qubit[1] {
    repeat {
        let anc = ancilla[0];
        H(anc);
        T(anc);
        CNOT(target,anc);
        H(anc);
        (Adjoint T)(anc);
        H(anc);
        T(anc);
        H(anc);
        CNOT(target,anc);
        T(anc);
        Z(target);
        H(anc);
        let result = M([anc],[PauliZ]);
    } until result == Zero
    fixup {
        ();
    }
}

repeat { set result = result - 1; } until result == 0 fixup { (); }

// Test `if`
if (result == One) {
    X(target);
} else {
    Z(target);
}

if (i == 1) {
    X(target);
} elif (i == 2) {
    Y(target);
} else {
    Z(target);
}

// Test array operations
let ary = [1;2;3];
let ary = new Int[i+1];
let concatted = [1;2;3] + [4;5;6];
let ary = a[3..-1..0];
let ary = a[1..3];
let first = a[0];

// Test `fail` (and also interpolated strings)
fail $"Impossible state reached";
fail $"Syndrome {syn} is incorrect";
fail "Error";

// Test literals
let a1 = true;
let a2 = false;
let b = 1e5;
let c = 2.0;
let c = 0xdeadbeef;
let c = 1..5;
let c = 1..2..5;
let d = "Hello \t World";
let d2 = "hello
World";
let e = ();
let f = ("hello", 1, 2.0);
let g = [1;2;3]
let paulis = (PauliI, PauliX, PauliY, PualiZ);
let results = (One, Zero);

// Test operators
let h = 1 + 1;
let i = 2 - 1;
let j = 2 * 3;
let k = 4 / 2;
let l = 2 ^ 3;
let m = 5 % 2;
let n = 1 &&& 3;
let o = 1 ||| 2;
let p = 1 ^^^ 3;
let q = -1;
let r = ~~~2;
let s = true && false;
let t = false || true;
let u = !false;
let v = 1 == 1;
let w = 2 != 1;
let x = 2 > 1;
let y = 3 < 4;
let z = 3 >= 3;
let aa = 3 <= 3;

// Test newtype
newtype TypeA = (Int, TypeB);
newtype typeA = (Int, TypeB);
newtype TypeB = (Double, TypeC);
newtype TypeC = (TypeA, Range);
newtype IntPair : (Int, Int);
newtype IntPairTransform : ((Int, Int) -> (Int, Int))
newType IntPairTransform2 : ((Int, Int) -> IntPair)
newType IntPairTransform3 : (IntPair -> (Int, Int))
