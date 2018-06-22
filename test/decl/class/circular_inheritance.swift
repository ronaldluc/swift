// RUN: rm -rf %t/stats-dir
// RUN: mkdir -p %t/stats-dir
// RUN: %target-typecheck-verify-swift
// RUN: not %target-swift-frontend -typecheck -debug-cycles %s -output-request-graphviz %t.dot -stats-output-dir %t/stats-dir 2> %t.cycles
// RUN: %FileCheck %s < %t.cycles
// RUN: %FileCheck -check-prefix CHECK-DOT %s  < %t.dot

// Check that we produced superclass type requests.
// RUN: %{python} %utils/process-stats-dir.py --evaluate 'SuperclassTypeRequest == 16' %t/stats-dir

class C : B { } // expected-error{{circular class inheritance 'C' -> 'B' -> 'A' -> 'C'}}
class B : A { } // expected-note{{class 'B' declared here}}
class A : C { } // expected-note{{class 'A' declared here}}

class TrivialCycle : TrivialCycle {} // expected-error{{circular class inheritance TrivialCycle}}
protocol P : P {} // expected-error {{circular protocol inheritance P}}

class Isomorphism : Automorphism { }
class Automorphism : Automorphism { } // expected-error{{circular class inheritance Automorphism}}

// FIXME: Useless error
let _ = A() // expected-error{{'A' cannot be constructed because it has no accessible initializers}}

class Left
    : Right.Hand {
  class Hand {}
}

class Right
  : Left.Hand {
  class Hand {}
}

class Outer {
  class Inner : Outer {}
}

class Outer2
    : Outer2.Inner {

  class Inner {}
}

class Outer3
    : Outer3.Inner<Int> {
  class Inner<T> {}
}

// CHECK: ===CYCLE DETECTED===
// CHECK-NEXT: `--{{.*}}SuperclassTypeRequest({{.*Left}}
// CHECK-NEXT:      `--{{.*}}InheritedTypeRequest(circular_inheritance.(file).Left@
// CHECK-NEXT:          `--{{.*}}SuperclassTypeRequest
// CHECK-NEXT:              `--{{.*}}InheritedTypeRequest(circular_inheritance.(file).Right@
// CHECK-NEXT:                  `--{{.*}}SuperclassTypeRequest{{.*(cyclic dependency)}}

// CHECK-DOT: digraph Dependencies
// CHECK-DOT: label="InheritedTypeRequest
