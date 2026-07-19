"""Przykladowy skrypt do testowania pyt.py (z dokumentacji)."""

def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

print("Fib(10) =", fib(10))

class Counter:
    def __init__(self):
        self.count = 0

    def inc(self):
        self.count += 1

    def __repr__(self):
        return f"Counter({self.count})"

c = Counter()
for _ in range(5):
    c.inc()
print(c)
