# pyt.py — Interpreter Pythona od zera

`pyt.py` to własnoręcznie napisany interpreter Pythona (AST-walker).
Parsuje pliki `.py` przez `ast.parse()` (pełna składnia Python 1:1),
a wykonuje AST własnym silnikiem bez użycia `exec()`/`eval()`.

## Użycie

```bash
python pyt.py <plik.py> [argumenty...]
```

## Obsługiwane cechy

### Typy danych
- `int`, `float`, `complex`, `bool`, `str`, `bytes`
- `list`, `tuple`, `dict`, `set`, `frozenset`
- `None`, `True`, `False`, `...` (Ellipsis), `NotImplemented`

### Zmienne i operatory
- Przypisanie: `=`, `+=`, `-=`, `*=`, `/=`, `//=`, `%=`, `**=`, `&=`, `|=`, `^=`, `<<=`, `>>=`
- Walrus operator: `:=`
- Arytmetyczne: `+`, `-`, `*`, `/`, `//`, `%`, `**`, `@` (matmul)
- Porównania: `==`, `!=`, `<`, `<=`, `>`, `>=`, `is`, `is not`, `in`, `not in`
- Logiczne: `and`, `or`, `not`
- Bitowe: `&`, `|`, `^`, `~`, `<<`, `>>`

### Kontrola przepływu
- `if`/`elif`/`else`
- `while`/`else`
- `for ... in ...`/`else` (z `break`, `continue`)
- `try`/`except`/`else`/`finally`
- `with`/`as` (context managers)
- `raise`, `assert`

### Funkcje
- `def`, `return`
- Argumenty pozycyjne, domyślne, `*args`, `**kwargs`, keyword-only
- Closures (domknięcia)
- Dekoratory (`@decorator`)
- `lambda`

### Klasy
- `class` z dziedziczeniem wielokrotnym
- `__init__`, `__repr__`, `__str__`, `__eq__`, `__lt__`, `__len__`, `__iter__`, `__getitem__`, `__setitem__`, `__add__`, `__bool__`, `__contains__`
- Metody wiązane (bound methods)

### Comprehensions
- List comprehension: `[x*2 for x in range(10) if x%2==0]`
- Dict comprehension: `{k: v for k, v in items}`
- Set comprehension: `{x for x in lst}`
- Generator expression: `(x**2 for x in range(n))`

### Strings
- f-strings z formatowaniem: `f"x={x:.2f}"`, `f"{val!r}"`
- Surowe stringi: `r"..."`, triple-quoted `"""..."""`
- Wszystkie metody stringów (przez `str` CPython)

### Import
- `import math`, `import os`, `import sys`, `import re`, ...
- `from math import sqrt, pi`
- `from module import *`
- Import lokalnych plików `.py`

### Wbudowane funkcje
`print`, `input`, `len`, `range`, `enumerate`, `zip`, `map`, `filter`,
`abs`, `min`, `max`, `sum`, `sorted`, `reversed`, `round`, `pow`, `divmod`,
`hash`, `id`, `repr`, `chr`, `ord`, `hex`, `oct`, `bin`, `format`,
`any`, `all`, `callable`, `iter`, `next`, `open`, `isinstance`, `issubclass`,
`hasattr`, `getattr`, `setattr`, `delattr`, `type`, `vars`, `dir`, ...

## Przykłady

### Fibonacci rekurencyjnie

```python
def fib(n):
    if n <= 1:
        return n
    return fib(n-1) + fib(n-2)

for i in range(11):
    print(f"fib({i}) = {fib(i)}")
```

### Klasy i dziedziczenie

```python
class Shape:
    def area(self):
        return 0
    def __repr__(self):
        return f"{type(self).__name__}(area={self.area()})"

class Circle(Shape):
    def __init__(self, r):
        self.r = r
    def area(self):
        import math
        return math.pi * self.r ** 2

class Rect(Shape):
    def __init__(self, w, h):
        self.w = w
        self.h = h
    def area(self):
        return self.w * self.h

shapes = [Circle(5), Rect(4, 6)]
for s in shapes:
    print(s)
```

### Obsługa błędów

```python
def safe_div(a, b):
    try:
        return a / b
    except ZeroDivisionError:
        return float('inf')
    finally:
        print("done")

print(safe_div(10, 2))
print(safe_div(10, 0))
```

### List comprehensions i generatory

```python
matrix = [[1,2,3],[4,5,6],[7,8,9]]
flat = [x for row in matrix for x in row]
print(flat)

primes = [n for n in range(2, 50)
          if all(n % i != 0 for i in range(2, n))]
print(primes)
```

### Closures i dekoratory

```python
def timer(func):
    import time
    def wrapper(*args, **kwargs):
        t = time.time()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.time()-t:.4f}s")
        return result
    return wrapper

@timer
def slow_sum(n):
    return sum(range(n))

slow_sum(1000000)
```

## Architektura

```
pyt.py
  ├── Env          ← Łańcuch środowisk (scope chain)
  ├── PyFunc       ← Funkcja użytkownika (z closure, domyślne wartości)
  ├── PyClass      ← Klasa użytkownika (z dziedziczeniem)
  ├── PyInst       ← Instancja klasy użytkownika
  ├── _BoundMethod ← Metoda związana z instancją
  ├── PyMod        ← Moduł (stdlib lub lokalny .py)
  ├── Interpreter  ← Główny silnik wykonania
  │   ├── stmts()  ← Wykonywanie listy instrukcji
  │   ├── stmt()   ← Pojedyncza instrukcja
  │   ├── expr()   ← Ewaluacja wyrażenia
  │   └── _comp()  ← Comprehensions
  └── _call()      ← Wywołanie funkcji (bind argumentów)
```

## Ograniczenia

- Generatory (`yield`) — zwracają listę zamiast prawdziwego generatora
- `async`/`await` — wykonywane synchronicznie (bez event loop)
- Deskryptory (property, classmethod) — podstawowe wsparcie
- Moduły C extension (np. `numpy`) — przez wrapping CPython
