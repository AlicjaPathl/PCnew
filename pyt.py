#!/usr/bin/env python3
"""
pyt.py — Python interpreter written from scratch.

Uses Python's ast module to parse (1:1 Python syntax), then walks the AST
with a hand-written evaluator: own environments, function calls, classes,
closures, comprehensions, exceptions, imports, f-strings, etc.

Usage: python pyt.py <script.py> [args...]
"""

import sys
import os
import ast
import operator as _op
import importlib as _importlib

# ─────────────────────────────────────────────────────────────────────────────
#  Control-flow signals
# ─────────────────────────────────────────────────────────────────────────────

class _Return(Exception):
    __slots__ = ('value',)
    def __init__(self, v): self.value = v

class _Break(Exception): pass
class _Continue(Exception): pass


# ─────────────────────────────────────────────────────────────────────────────
#  Environment (scope chain)
# ─────────────────────────────────────────────────────────────────────────────

class Env:
    __slots__ = ('_d', 'parent', '_globals', '_nonlocals')

    def __init__(self, parent=None):
        self._d = {}
        self.parent = parent
        self._globals = None
        self._nonlocals = None

    # lookup
    def get(self, name):
        e = self
        while e is not None:
            if name in e._d:
                return e._d[name]
            e = e.parent
        raise NameError(f"name {name!r} is not defined")

    def set(self, name, value):
        self._d[name] = value

    # for global / nonlocal declarations
    def set_in(self, name, value, scope):
        """Write to the first ancestor that already has `name`, else to `scope`."""
        e = self
        while e is not None:
            if name in e._d:
                e._d[name] = value
                return
            e = e.parent
        scope._d[name] = value

    def root(self):
        e = self
        while e.parent:
            e = e.parent
        return e

    def has_local(self, name):
        return name in self._d


# ─────────────────────────────────────────────────────────────────────────────
#  Python objects created by the interpreter
# ─────────────────────────────────────────────────────────────────────────────

class PyFunc:
    """A user-defined function."""
    __slots__ = ('node', 'env', 'interp', 'name', 'defaults', 'kw_defaults')

    def __init__(self, node, env, interp):
        self.node = node
        self.env = env
        self.interp = interp
        self.name = getattr(node, 'name', '<lambda>')
        # Evaluate defaults eagerly at definition time (Python semantics)
        self.defaults = [interp.expr(d, env) for d in node.args.defaults]
        self.kw_defaults = [interp.expr(d, env) if d else None
                            for d in node.args.kw_defaults]

    def __call__(self, *args, **kwargs):
        return _call(self, list(args), kwargs)

    def __repr__(self):
        return f'<function {self.name}>'


class PyClass:
    """A user-defined class."""
    __slots__ = ('name', 'bases', 'ns')

    def __init__(self, name, bases, ns):
        self.name = name
        self.bases = bases
        self.ns = ns

    def __call__(self, *args, **kwargs):
        inst = PyInst(self)
        init = self._lookup('__init__')
        if init is not None:
            _call(init, [inst] + list(args), kwargs)
        return inst

    def _lookup(self, name):
        if name in self.ns:
            return self.ns[name]
        for b in self.bases:
            if isinstance(b, PyClass):
                v = b._lookup(name)
                if v is not None:
                    return v
        return None

    def __repr__(self):
        return f"<class '{self.name}'>"


class PyInst:
    """An instance of a user-defined class."""
    __slots__ = ('cls', 'attrs')

    def __init__(self, cls):
        self.cls = cls
        self.attrs = {}

    def _get(self, name):
        if name in self.attrs:
            return self.attrs[name]
        v = self.cls._lookup(name)
        if v is None:
            raise AttributeError(f"'{self.cls.name}' object has no attribute '{name!r}'")
        if isinstance(v, PyFunc):
            return _BoundMethod(v, self)
        return v

    def _set(self, name, value):
        self.attrs[name] = value

    def __repr__(self):
        m = self.cls._lookup('__repr__')
        if m:
            return _call(m, [self], {})
        m = self.cls._lookup('__str__')
        if m:
            return _call(m, [self], {})
        return f'<{self.cls.name} object at 0x{id(self):x}>'

    def __str__(self):
        m = self.cls._lookup('__str__')
        if m:
            return _call(m, [self], {})
        return self.__repr__()

    def __eq__(self, other):
        m = self.cls._lookup('__eq__')
        if m:
            return _call(m, [self, other], {})
        return NotImplemented

    def __lt__(self, other):
        m = self.cls._lookup('__lt__')
        if m:
            return _call(m, [self, other], {})
        return NotImplemented

    def __add__(self, other):
        m = self.cls._lookup('__add__')
        if m:
            return _call(m, [self, other], {})
        return NotImplemented

    def __len__(self):
        m = self.cls._lookup('__len__')
        if m:
            return _call(m, [self], {})
        raise TypeError(f"object of type '{self.cls.name}' has no len()")

    def __iter__(self):
        m = self.cls._lookup('__iter__')
        if m:
            return iter(_call(m, [self], {}))
        m = self.cls._lookup('__getitem__')
        if m:
            i = 0
            while True:
                try:
                    yield _call(m, [self, i], {})
                    i += 1
                except (IndexError, StopIteration):
                    return
        raise TypeError(f"'{self.cls.name}' object is not iterable")

    def __getitem__(self, key):
        m = self.cls._lookup('__getitem__')
        if m:
            return _call(m, [self, key], {})
        raise TypeError(f"'{self.cls.name}' object is not subscriptable")

    def __setitem__(self, key, value):
        m = self.cls._lookup('__setitem__')
        if m:
            _call(m, [self, key, value], {})
        else:
            raise TypeError(f"'{self.cls.name}' object does not support item assignment")

    def __contains__(self, item):
        m = self.cls._lookup('__contains__')
        if m:
            return _call(m, [self, item], {})
        return NotImplemented

    def __bool__(self):
        m = self.cls._lookup('__bool__')
        if m:
            return bool(_call(m, [self], {}))
        m = self.cls._lookup('__len__')
        if m:
            return bool(_call(m, [self], {}))
        return True


class _BoundMethod:
    __slots__ = ('func', 'inst')

    def __init__(self, func, inst):
        self.func = func
        self.inst = inst

    def __call__(self, *args, **kwargs):
        return _call(self.func, [self.inst] + list(args), kwargs)

    def __repr__(self):
        return f'<bound method {self.func.name} of {self.inst!r}>'


class PyMod:
    """A module (real or user-defined)."""
    __slots__ = ('name', 'ns')

    def __init__(self, name, ns):
        self.name = name
        self.ns = ns

    def __repr__(self):
        return f"<module '{self.name}'>"


# ─────────────────────────────────────────────────────────────────────────────
#  Function call
# ─────────────────────────────────────────────────────────────────────────────

def _call(func, args, kwargs):
    """Call a PyFunc, BoundMethod or callable."""
    if isinstance(func, _BoundMethod):
        return _call(func.func, [func.inst] + list(args), kwargs)
    if isinstance(func, PyClass):
        return func(*args, **kwargs)
    if not isinstance(func, PyFunc):
        return func(*args, **kwargs)

    node = func.node
    env = Env(func.env)   # new frame in closure
    p = node.args
    is_lambda = type(node).__name__ == 'Lambda'

    pos = p.args
    n_pos = len(pos)
    defaults = func.defaults
    n_def = len(defaults)

    # bind positional
    for i, param in enumerate(pos):
        if i < len(args):
            env.set(param.arg, args[i])
        elif i >= n_pos - n_def:
            env.set(param.arg, defaults[i - (n_pos - n_def)])
        else:
            raise TypeError(f"{func.name}() missing argument '{param.arg}'")

    # *args
    if p.vararg:
        env.set(p.vararg.arg, tuple(args[n_pos:]))

    # keyword-only
    for i, param in enumerate(p.kwonlyargs):
        if param.arg in kwargs:
            env.set(param.arg, kwargs.pop(param.arg))
        elif func.kw_defaults[i] is not None:
            env.set(param.arg, func.kw_defaults[i])
        else:
            raise TypeError(f"{func.name}() missing keyword-only argument '{param.arg}'")

    # **kwargs
    if p.kwarg:
        env.set(p.kwarg.arg, dict(kwargs))
    else:
        for k, v in kwargs.items():
            env.set(k, v)

    interp = func.interp
    if is_lambda:
        return interp.expr(node.body, env)

    try:
        interp.stmts(node.body, env)
        return None
    except _Return as r:
        return r.value


# ─────────────────────────────────────────────────────────────────────────────
#  Interpreter
# ─────────────────────────────────────────────────────────────────────────────

_CMP = {
    'Eq': _op.eq, 'NotEq': _op.ne,
    'Lt': _op.lt, 'LtE': _op.le,
    'Gt': _op.gt, 'GtE': _op.ge,
    'Is': _op.is_, 'IsNot': _op.is_not,
    'In': lambda a, b: a in b,
    'NotIn': lambda a, b: a not in b,
}

_BIN = {
    'Add': _op.add, 'Sub': _op.sub, 'Mult': _op.mul,
    'Div': _op.truediv, 'FloorDiv': _op.floordiv,
    'Mod': _op.mod, 'Pow': _op.pow,
    'BitAnd': _op.and_, 'BitOr': _op.or_, 'BitXor': _op.xor,
    'LShift': _op.lshift, 'RShift': _op.rshift,
    'MatMult': _op.matmul,
}

_UNR = {
    'USub': _op.neg, 'UAdd': _op.pos,
    'Invert': _op.invert, 'Not': _op.not_,
}


class Interpreter:
    def __init__(self, filename='<string>'):
        self.filename = filename
        self.genv = Env()
        self._init_builtins()

    # ── Built-ins ─────────────────────────────────────────────────────────────

    def _init_builtins(self):
        g = self.genv.set

        # types
        for name in ('int', 'float', 'str', 'bool', 'bytes', 'bytearray',
                     'list', 'dict', 'tuple', 'set', 'frozenset',
                     'complex', 'memoryview', 'type', 'object'):
            g(name, eval(name))

        # functions
        g('print',      self._print)
        g('input',      input)
        g('len',        len)
        g('range',      range)
        g('enumerate',  enumerate)
        g('zip',        zip)
        g('map',        map)
        g('filter',     filter)
        g('abs',        abs)
        g('min',        min)
        g('max',        max)
        g('sum',        sum)
        g('sorted',     sorted)
        g('reversed',   reversed)
        g('round',      round)
        g('pow',        pow)
        g('divmod',     divmod)
        g('hash',       hash)
        g('id',         id)
        g('repr',       repr)
        g('chr',        chr)
        g('ord',        ord)
        g('hex',        hex)
        g('oct',        oct)
        g('bin',        bin)
        g('format',     format)
        g('any',        any)
        g('all',        all)
        g('callable',   callable)
        g('iter',       iter)
        g('next',       next)
        g('open',       open)
        g('vars',       lambda o=None: o.__dict__ if o else {})
        g('dir',        self._dir)
        g('isinstance', self._isinstance)
        g('issubclass', issubclass)
        g('hasattr',    self._hasattr)
        g('getattr',    self._getattr)
        g('setattr',    self._setattr)
        g('delattr',    delattr)
        g('super',      super)
        g('staticmethod', staticmethod)
        g('classmethod', classmethod)
        g('property',   property)
        g('__import__', self._import)
        g('__name__',   '__main__')
        g('__file__',   self.filename)
        g('__builtins__', {})

        # constants
        g('True',  True); g('False', False); g('None', None)
        g('NotImplemented', NotImplemented)
        g('Ellipsis', ...)

        # exceptions
        for exc in (Exception, BaseException, SystemExit, KeyboardInterrupt,
                    ValueError, TypeError, KeyError, IndexError, AttributeError,
                    NameError, RuntimeError, StopIteration, OSError, IOError,
                    FileNotFoundError, FileExistsError, ZeroDivisionError,
                    OverflowError, NotImplementedError, ImportError, AssertionError,
                    RecursionError, MemoryError, SyntaxError, PermissionError,
                    TimeoutError, ConnectionError, BrokenPipeError, EOFError,
                    ArithmeticError, LookupError, UnicodeDecodeError, UnicodeEncodeError,
                    UnicodeError, GeneratorExit, SystemError, Warning, UserWarning):
            g(exc.__name__, exc)

    def _print(self, *args, sep=' ', end='\n', file=None, flush=False):
        f = file or sys.stdout
        f.write(sep.join(str(a) for a in args) + end)
        if flush:
            f.flush()

    def _dir(self, obj=None):
        if obj is None: return list(self.genv._d.keys())
        if isinstance(obj, (PyInst,)):
            return sorted(set(list(obj.attrs) + list(obj.cls.ns)))
        if isinstance(obj, PyClass):
            return sorted(obj.ns)
        if isinstance(obj, PyMod):
            return sorted(obj.ns)
        return dir(obj)

    def _isinstance(self, obj, types):
        if isinstance(types, tuple):
            return any(self._isinstance(obj, t) for t in types)
        if isinstance(types, PyClass):
            return isinstance(obj, PyInst) and (
                obj.cls is types or any(self._isinstance(obj, b) for b in types.bases))
        return isinstance(obj, types)

    def _hasattr(self, obj, name):
        try:
            self._getattr(obj, name)
            return True
        except (AttributeError, NameError):
            return False

    def _getattr(self, obj, name, *default):
        if isinstance(obj, PyInst):
            try: return obj._get(name)
            except AttributeError:
                if default: return default[0]
                raise
        if isinstance(obj, PyClass):
            v = obj._lookup(name)
            if v is not None: return v
            if default: return default[0]
            raise AttributeError(name)
        if isinstance(obj, PyMod):
            if name in obj.ns: return obj.ns[name]
            if default: return default[0]
            raise AttributeError(f"module '{obj.name}' has no attribute '{name}'")
        return getattr(obj, name, *default)

    def _setattr(self, obj, name, value):
        if isinstance(obj, PyInst):
            obj._set(name, value)
        else:
            setattr(obj, name, value)

    def _import(self, name, *args, **kwargs):
        return self._do_import(name)

    def _do_import(self, name):
        """Import: try real stdlib, then local .py file."""
        try:
            mod = _importlib.import_module(name)
            ns = {}
            for k in dir(mod):
                try: ns[k] = getattr(mod, k)
                except: pass
            return PyMod(name, ns)
        except ImportError:
            pass
        # local file
        for d in sys.path:
            p = os.path.join(d, name.replace('.', os.sep) + '.py')
            if os.path.exists(p):
                return self._import_file(name, p)
        raise ImportError(f"No module named '{name}'")

    def _import_file(self, name, path):
        with open(path, 'r', encoding='utf-8') as f:
            src = f.read()
        sub = Interpreter(path)
        sub.run(ast.parse(src, path))
        return PyMod(name, dict(sub.genv._d))

    # ── Statement execution ───────────────────────────────────────────────────

    def run(self, tree):
        self.stmts(tree.body, self.genv)

    def stmts(self, body, env):
        for node in body:
            self.stmt(node, env)

    def stmt(self, node, env):
        kind = type(node).__name__

        if kind == 'Expr':
            self.expr(node.value, env)

        elif kind == 'Assign':
            v = self.expr(node.value, env)
            for tgt in node.targets:
                self._assign(tgt, v, env)

        elif kind == 'AnnAssign':
            if node.value:
                self._assign(node.target, self.expr(node.value, env), env)

        elif kind == 'AugAssign':
            cur = self.expr(node.target, env)
            rhs = self.expr(node.value, env)
            name = type(node.op).__name__
            res = _BIN[name](cur, rhs)
            self._assign(node.target, res, env)

        elif kind == 'NamedExpr':
            v = self.expr(node.value, env)
            env.set(node.target.id, v)

        elif kind == 'If':
            branch = node.body if self.expr(node.test, env) else node.orelse
            self.stmts(branch, env)

        elif kind == 'While':
            while self.expr(node.test, env):
                try:
                    self.stmts(node.body, env)
                except _Break:
                    break
                except _Continue:
                    continue
            else:
                self.stmts(node.orelse, env)

        elif kind == 'For':
            it = self.expr(node.iter, env)
            broke = False
            for item in it:
                self._assign(node.target, item, env)
                try:
                    self.stmts(node.body, env)
                except _Break:
                    broke = True; break
                except _Continue:
                    continue
            if not broke:
                self.stmts(node.orelse, env)

        elif kind in ('FunctionDef', 'AsyncFunctionDef'):
            fn = PyFunc(node, env, self)
            # apply decorators (outer-first)
            dec = fn
            for d in reversed(node.decorator_list):
                dec = self.expr(d, env)(dec)
            env.set(node.name, dec)

        elif kind == 'ClassDef':
            bases = [self.expr(b, env) for b in node.bases]
            cenv = Env(env)
            cenv.set('__name__', node.name)
            self.stmts(node.body, cenv)
            cls = PyClass(node.name, bases, dict(cenv._d))
            for d in reversed(node.decorator_list):
                cls = self.expr(d, env)(cls)
            env.set(node.name, cls)

        elif kind == 'Return':
            raise _Return(self.expr(node.value, env) if node.value else None)

        elif kind == 'Break':
            raise _Break()

        elif kind == 'Continue':
            raise _Continue()

        elif kind == 'Pass':
            pass

        elif kind == 'Delete':
            for tgt in node.targets:
                self._delete(tgt, env)

        elif kind == 'Global':
            for name in node.names:
                env._globals = getattr(env, '_globals', set())
                env._globals.add(name)

        elif kind == 'Nonlocal':
            # Mark names as nonlocal: assigns must write to enclosing scope
            for name in node.names:
                env._nonlocals = getattr(env, '_nonlocals', set())
                env._nonlocals.add(name)

        elif kind == 'Import':
            for alias in node.names:
                mod = self._do_import(alias.name)
                asname = alias.asname or alias.name.split('.')[0]
                env.set(asname, mod)

        elif kind == 'ImportFrom':
            mod = self._do_import(node.module or '')
            ns = mod.ns if isinstance(mod, PyMod) else {k: getattr(mod, k) for k in dir(mod)}
            for alias in node.names:
                if alias.name == '*':
                    for k, v in ns.items():
                        env.set(k, v)
                else:
                    asname = alias.asname or alias.name
                    env.set(asname, ns.get(alias.name, getattr(mod, alias.name, None)))

        elif kind == 'Raise':
            if node.exc:
                exc = self.expr(node.exc, env)
                if isinstance(exc, type) and issubclass(exc, BaseException):
                    raise exc()
                raise exc
            raise RuntimeError("bare raise")

        elif kind == 'Try':
            try:
                self.stmts(node.body, env)
            except (_Return, _Break, _Continue):
                raise
            except BaseException as e:
                handled = False
                for h in node.handlers:
                    if h.type is None or isinstance(e, self.expr(h.type, env)):
                        if h.name:
                            env.set(h.name, e)
                        self.stmts(h.body, env)
                        if h.name:
                            try: del env._d[h.name]
                            except: pass
                        handled = True
                        break
                if not handled:
                    if node.finalbody:
                        self.stmts(node.finalbody, env)
                    raise
            else:
                self.stmts(node.orelse, env)
            finally:
                if node.finalbody:
                    self.stmts(node.finalbody, env)

        elif kind == 'With':
            ctxs = []
            for item in node.items:
                ctx = self.expr(item.context_expr, env)
                val = ctx.__enter__()
                if item.optional_vars:
                    self._assign(item.optional_vars, val, env)
                ctxs.append(ctx)
            try:
                self.stmts(node.body, env)
            except Exception as e:
                for ctx in reversed(ctxs):
                    if ctx.__exit__(type(e), e, None):
                        return
                raise
            else:
                for ctx in reversed(ctxs):
                    ctx.__exit__(None, None, None)

        elif kind == 'Assert':
            if not self.expr(node.test, env):
                msg = self.expr(node.msg, env) if node.msg else None
                raise AssertionError(msg)

        # else: unknown node — skip silently

    def _assign(self, tgt, value, env):
        kind = type(tgt).__name__
        if kind == 'Name':
            name = tgt.id
            # respect global declarations
            if getattr(env, '_globals', None) and name in env._globals:
                env.root().set(name, value)
            # respect nonlocal declarations — write to enclosing scope
            elif getattr(env, '_nonlocals', None) and name in env._nonlocals:
                e = env.parent
                while e is not None:
                    if name in e._d:
                        e._d[name] = value
                        return
                    e = e.parent
                # Fallback: write to parent
                if env.parent:
                    env.parent._d[name] = value
            else:
                env.set(name, value)
        elif kind in ('Tuple', 'List'):
            # Unpacking, including starred
            elts = tgt.elts
            starred_idx = next((i for i, e in enumerate(elts)
                                if type(e).__name__ == 'Starred'), -1)
            if starred_idx >= 0:
                values = list(value)
                n_after = len(elts) - starred_idx - 1
                before = values[:starred_idx]
                starred = values[starred_idx:len(values) - n_after if n_after else len(values)]
                after = values[len(values) - n_after:] if n_after else []
                for e, v in zip(elts[:starred_idx], before):
                    self._assign(e, v, env)
                self._assign(elts[starred_idx].value, starred, env)
                for e, v in zip(elts[starred_idx+1:], after):
                    self._assign(e, v, env)
            else:
                values = list(value)
                if len(values) != len(elts):
                    raise ValueError(f"not enough values to unpack "
                                     f"(expected {len(elts)}, got {len(values)})")
                for e, v in zip(elts, values):
                    self._assign(e, v, env)
        elif kind == 'Subscript':
            obj = self.expr(tgt.value, env)
            key = self.expr(tgt.slice, env)
            obj[key] = value
        elif kind == 'Attribute':
            obj = self.expr(tgt.value, env)
            if isinstance(obj, PyInst):
                obj._set(tgt.attr, value)
            elif isinstance(obj, PyMod):
                obj.ns[tgt.attr] = value
            else:
                setattr(obj, tgt.attr, value)
        elif kind == 'Starred':
            self._assign(tgt.value, list(value), env)

    def _delete(self, tgt, env):
        kind = type(tgt).__name__
        if kind == 'Name':
            env._d.pop(tgt.id, None)
        elif kind == 'Subscript':
            obj = self.expr(tgt.value, env)
            del obj[self.expr(tgt.slice, env)]
        elif kind == 'Attribute':
            obj = self.expr(tgt.value, env)
            if isinstance(obj, PyInst):
                obj.attrs.pop(tgt.attr, None)
            else:
                delattr(obj, tgt.attr)

    # ── Expression evaluation ─────────────────────────────────────────────────

    def expr(self, node, env):
        if node is None:
            return None
        kind = type(node).__name__

        if kind == 'Constant':
            return node.value

        # Python 3.7 compat nodes
        if kind == 'Num':  return node.n
        if kind == 'Str':  return node.s
        if kind == 'Bytes': return node.s
        if kind == 'NameConstant': return node.value
        if kind == 'Ellipsis': return ...

        if kind == 'Name':
            if node.id in ('True', 'False', 'None'):
                return {'True': True, 'False': False, 'None': None}[node.id]
            return env.get(node.id)

        if kind == 'BinOp':
            l = self.expr(node.left, env)
            r = self.expr(node.right, env)
            fn = _BIN.get(type(node.op).__name__)
            return fn(l, r) if fn else None

        if kind == 'UnaryOp':
            v = self.expr(node.operand, env)
            return _UNR[type(node.op).__name__](v)

        if kind == 'BoolOp':
            is_and = type(node.op).__name__ == 'And'
            result = None
            for val in node.values:
                result = self.expr(val, env)
                if is_and and not result:
                    return result
                if not is_and and result:
                    return result
            return result

        if kind == 'Compare':
            left = self.expr(node.left, env)
            for op, comp in zip(node.ops, node.comparators):
                right = self.expr(comp, env)
                fn = _CMP[type(op).__name__]
                if not fn(left, right):
                    return False
                left = right
            return True

        if kind == 'IfExp':
            return (self.expr(node.body, env) if self.expr(node.test, env)
                    else self.expr(node.orelse, env))

        if kind == 'Call':
            fn = self.expr(node.func, env)
            args = []
            for a in node.args:
                if type(a).__name__ == 'Starred':
                    args.extend(self.expr(a.value, env))
                else:
                    args.append(self.expr(a, env))
            kwargs = {}
            for kw in node.keywords:
                if kw.arg is None:
                    kwargs.update(self.expr(kw.value, env))
                else:
                    kwargs[kw.arg] = self.expr(kw.value, env)
            return self._call(fn, args, kwargs)

        if kind == 'Attribute':
            obj = self.expr(node.value, env)
            return self._getattr(obj, node.attr)

        if kind == 'Subscript':
            obj = self.expr(node.value, env)
            slc = self.expr(node.slice, env)
            return obj[slc]

        if kind == 'Index':    # 3.8 compat
            return self.expr(node.value, env)

        if kind == 'Slice':
            start = self.expr(node.lower, env) if node.lower else None
            stop  = self.expr(node.upper, env) if node.upper else None
            step  = self.expr(node.step,  env) if node.step  else None
            return slice(start, stop, step)

        if kind == 'ExtSlice':  # 3.8 compat
            return tuple(self.expr(d, env) for d in node.dims)

        if kind == 'List':
            return [self.expr(e, env) for e in node.elts]

        if kind == 'Tuple':
            return tuple(self.expr(e, env) for e in node.elts)

        if kind == 'Set':
            return {self.expr(e, env) for e in node.elts}

        if kind == 'Dict':
            result = {}
            for k, v in zip(node.keys, node.values):
                if k is None:
                    result.update(self.expr(v, env))
                else:
                    result[self.expr(k, env)] = self.expr(v, env)
            return result

        if kind == 'Lambda':
            return PyFunc(node, env, self)

        if kind == 'JoinedStr':  # f-string
            parts = []
            for v in node.values:
                if type(v).__name__ == 'FormattedValue':
                    val = self.expr(v.value, env)
                    conv = v.conversion
                    if conv == ord('r'):   val = repr(val)
                    elif conv == ord('a'): val = ascii(val)
                    elif conv == ord('s'): val = str(val)
                    if v.format_spec:
                        spec = ''.join(
                            str(self.expr(p, env)) if type(p).__name__ == 'FormattedValue'
                            else p.value
                            for p in v.format_spec.values
                        )
                        parts.append(format(val, spec))
                    else:
                        parts.append(str(val))
                else:
                    parts.append(str(v.value))
            return ''.join(parts)

        if kind == 'Starred':
            return self.expr(node.value, env)

        if kind == 'NamedExpr':
            v = self.expr(node.value, env)
            env.set(node.target.id, v)
            return v

        if kind == 'ListComp':
            return list(self._comp(node, env, 'list'))

        if kind == 'SetComp':
            return set(self._comp(node, env, 'set'))

        if kind == 'DictComp':
            return dict(self._comp(node, env, 'dict'))

        if kind == 'GeneratorExp':
            return (x for x in self._comp(node, env, 'list'))

        if kind in ('Yield', 'YieldFrom', 'Await'):
            # basic: just eval the value
            return self.expr(node.value, env) if node.value else None

        return None

    def _comp(self, node, env, kind):
        cenv = Env(env)
        result = []

        def run(gen_idx):
            if gen_idx >= len(node.generators):
                if kind == 'dict':
                    result.append((self.expr(node.key, cenv),
                                   self.expr(node.value, cenv)))
                else:
                    result.append(self.expr(node.elt, cenv))
                return
            g = node.generators[gen_idx]
            for item in self.expr(g.iter, cenv if gen_idx > 0 else env):
                self._assign(g.target, item, cenv)
                if all(self.expr(c, cenv) for c in g.ifs):
                    run(gen_idx + 1)

        run(0)
        return result

    def _call(self, fn, args, kwargs):
        if isinstance(fn, (PyFunc, _BoundMethod, PyClass)):
            return _call(fn, args, kwargs)
        if callable(fn):
            return fn(*args, **kwargs)
        raise TypeError(f"'{type(fn).__name__}' object is not callable")


# ─────────────────────────────────────────────────────────────────────────────
#  Entry point
# ─────────────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("pyt.py — Python interpreter (from scratch, AST-walking)")
        print("Użycie: python pyt.py <plik.py> [argumenty...]")
        sys.exit(0)

    script = sys.argv[1]

    if not os.path.exists(script):
        print(f"pyt.py: Błąd: Plik '{script}' nie istnieje.")
        sys.exit(1)

    # Set up sys.argv like the real interpreter would
    sys.argv = sys.argv[1:]

    script_dir = os.path.dirname(os.path.abspath(script))
    if script_dir not in sys.path:
        sys.path.insert(0, script_dir)

    with open(script, 'r', encoding='utf-8') as f:
        source = f.read()

    try:
        tree = ast.parse(source, script)
    except SyntaxError as e:
        sys.stderr.write(f'  File "{e.filename}", line {e.lineno}\n')
        if e.text:
            sys.stderr.write(f'    {e.text.rstrip()}\n')
            sys.stderr.write(f'    {" " * (e.offset - 1)}^\n')
        sys.stderr.write(f'SyntaxError: {e.msg}\n')
        sys.exit(1)

    interp = Interpreter(script)

    try:
        interp.run(tree)
    except SystemExit as e:
        sys.exit(e.code)
    except KeyboardInterrupt:
        sys.stderr.write('\nKeyboardInterrupt\n')
        sys.exit(130)
    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        sys.stderr.write(tb)
        sys.exit(1)


if __name__ == '__main__':
    main()
