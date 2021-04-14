# SwiftTex

Available in Swift Package Manager

SwiftTex is a very simple Latex-like parser. It can parse simple math expressions like:

```
p_{0y} - 2p_{1y} + p_{2y}
```

into an AST that represents

$$
p_{0y} - 2p_{1y} + p_{2y}
$$

## Goals

This project has two goals: First, to parse math expression, and second, to solve, transform, or manipulate those math formulas

Parsing goals:

1. Parse fairly simple math expressions: $$x^2*3 + 8$$
2. Parse function definitions: $$ f(x) = x^2 $$
3. Parse expression equality: $$a_0 = x_1 + y_1$$

Solving goals:

- Substitute an variable into a formula:

$$
a = b + c   \\
f(x) = x^2  \\
f(a) = (b + c)^2
$$

- Ability to expand a math expression, showing each step

$$
f(a) = (b + c)^2        \\
f(a) = (b + c)(b + c)   \\
f(a) = b^2 + 2bc + c^2
$$

- Ability to solve an expression, given values for particular variables

$$
c = 2                       \\
f(a) = b^2 + 2bc + c^2      \\
f(a) = b^2 + 4b + 4         \\
b = 3                       \\
f(a) = 9 + 4*3 + 4          \\
f(a) = 13 + 12              \\
f(a) = 25                   \\
$$


## Next Items

- Rename Mac app to Primer, like a schoolbook primer

- Add `hash` value to each node. The hash should be calculated from the hashes of the child nodes, in a way that respects associative/etc operations. This way, we can quickly compare equality of $$x(y+2)^4$$ with $$(x(2+y)^4$$ and see that they're equivalent.

- SortVisitor that will sort terms alphabetically and by subscript

- CombineLikeTermVisitor that will turn $$xx$$ into $$x^2$$ and $$2x + x$$ into $$3x$$

- RationalNode that represents a fraction between two whole numbers, so that it can be inverted without floating point error

- FormatVisitor that will turn $$x^{1/3}$$ into $$\sqrt[3]{x}$$ and $$(a + b) / (x + y)$$ into $$\frac{a + b}{x + y}$$

## References

http://blog.matthewcheok.com/writing-a-parser-in-swift/

https://github.com/kostub/iosMath

https://github.com/kostub/MathSolver

https://github.com/kostub/MathEditor


