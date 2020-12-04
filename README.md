# SwiftTex

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
