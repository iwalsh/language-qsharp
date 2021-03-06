// This file contains some examples of Q# language constructs.
// I've used it to test the syntax highlighting while developing,
// and also maintain a TODO list of unfinished tasks.
// It's not a real Q# program and doesn't even compile -
// it's for experimentation only.

// Nice-to-have, polishes:
//   use "invalid.illegal" on lowercased types and function names
//   move keywords higher in the hierarchy so they are highlighted sooner
//   update the BNF grammar, note where it departs from the highlighting grammar
//   consolidate operation patterns
//   factor out common patterns for identifiers
//   audit variable capture rules & scopes. (is [_[:alpha:]][[:alnum:]]* always correct?)
//   audit lookbehind/lookaheads, remove unnecessary ones

namespace Foo {
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
}

namespace Microsoft.Quantum.Samples {
    // Entangle two qubits.
    // Assumes that both qubits are in the |0> state.
    operation EPR (q1 : Qubit, q2 : Qubit) : () {
        body
        {
            H(q2);
            CNOT(q2, q1);
        }
    }

    // Teleport the quantum state of the source to the target.
    // Assumes that the target is in the |0> state.
    operation Teleport (source : Qubit, target : Qubit) : () {
        body {
            // Get a temporary for the Bell pair
            using (ancilla = Qubit[1]) {
                let temp = ancilla[0];

                // Create a Bell pair between the temporary and the target
                EPR(target, temp);

                // Do the teleportation
                CNOT(source, temp);
                H(source);
                if (M(source) == One) {
                    X(target);
                }
                if (M(temp) == One) {
                    Z(target);
                }
            }
        }
    }
}

namespace Hello.QSharp {
  open MyLibrary;
}

namespace Hello.QSharp {
  let foo = bar;
}

namespace Hello.QSharp {
  function DotProduct (a : Double[], b : Double[]) : Double {}
}

let foo abstract bar;

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
let paulis = (PauliI, PauliX, PauliY, PauliZ);
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
namespace My.NewTypes {
  newtype TypeA = (Int, TypeB);
  newtype typeA = (Int, TypeB);
  newtype TypeB = (Double, TypeC);
  newtype TypeC = (TypeA, Range);
  newtype IntPair : (Int, Int);
  newtype IntPairTransform : ((Int, Int) -> (Int, Int))
  newType IntPairTransform2 : ((Int, Int) -> IntPair)
  newType IntPairTransform3 : (IntPair -> (Int, Int))
}
