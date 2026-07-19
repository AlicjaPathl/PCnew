import re
import sys
import os
import comp

# Lexer token specifications
TOKEN_SPEC = [
    ('COMMENT',   r'//.*|/\*[\s\S]*?\*/'),
    ('WS',        r'\s+'),
    ('NUMBER',    r'\b0x[0-9a-fA-F]+\b|\b\d+\b'),
    ('STRING',    r'"([^"\\]|\\.)*"'),
    ('CHAR',      r"'([^'\\]|\\.)*'"),
    ('IF',        r'\bif\b'),
    ('ELSE',      r'\belse\b'),
    ('WHILE',     r'\bwhile\b'),
    ('RETURN',    r'\breturn\b'),
    ('BREAK',     r'\bbreak\b'),
    ('INT',       r'\bint\b'),
    ('CHAR_KEY',  r'\bchar\b'),
    ('VOID',      r'\bvoid\b'),
    ('ASM',       r'\b__asm__\b|\basm\b'),
    ('IDENT',     r'\b[a-zA-Z_][a-zA-Z0-9_]*\b'),
    ('OP_EQ',     r'=='),
    ('OP_NE',     r'!='),
    ('OP_LE',     r'<='),
    ('OP_GE',     r'>='),
    ('OP_SHL',    r'<<'),
    ('OP_SHR',    r'>>'),
    ('ASSIGN',    r'='),
    ('PLUS',      r'\+'),
    ('MINUS',     r'-'),
    ('MUL',       r'\*'),
    ('DIV',       r'/'),
    ('MOD',       r'%'),
    ('LPAREN',    r'\('),
    ('RPAREN',    r'\)'),
    ('LBRACE',    r'\{'),
    ('RBRACE',    r'\}'),
    ('LBRACKET',  r'\['),
    ('RBRACKET',  r'\]'),
    ('SEMI',      r';'),
    ('COMMA',     r','),
    ('OP_AND',    r'&&'),
    ('OP_OR',     r'\|\|'),
    ('AMP',       r'&'),
    ('LT',        r'<'),
    ('GT',        r'>'),
]

class Token:
    def __init__(self, type, value, line):
        self.type = type
        self.value = value
        self.line = line
    def __repr__(self):
        return f"Token({self.type}, {repr(self.value)}, line {self.line})"

def tokenize(code):
    tokens = []
    line_num = 1
    position = 0
    # Compile regexes
    regex_parts = []
    for name, expr in TOKEN_SPEC:
        regex_parts.append(f"(?P<{name}>{expr})")
    master_regex = re.compile("|".join(regex_parts))
    
    for match in master_regex.finditer(code):
        kind = match.lastgroup
        value = match.group(kind)
        
        # Track line number
        newlines = value.count('\n')
        line_num += newlines
        
        if kind == 'WS' or kind == 'COMMENT':
            continue
        tokens.append(Token(kind, value, line_num))
        
    return tokens

# AST Node classes
class ProgramNode:
    def __init__(self, globals, functions):
        self.globals = globals
        self.functions = functions

class FunctionNode:
    def __init__(self, ret_type, name, params, body):
        self.ret_type = ret_type
        self.name = name
        self.params = params  # list of (type, name)
        self.body = body

class VarDeclNode:
    def __init__(self, type, name, init_val=None):
        self.type = type
        self.name = name
        self.init_val = init_val
        self.array_size = None  # set by parser if this is a static array

class BlockNode:
    def __init__(self, statements):
        self.statements = statements

class IfNode:
    def __init__(self, cond, then_stmt, else_stmt=None):
        self.cond = cond
        self.then_stmt = then_stmt
        self.else_stmt = else_stmt

class WhileNode:
    def __init__(self, cond, body):
        self.cond = cond
        self.body = body

class ReturnNode:
    def __init__(self, expr=None):
        self.expr = expr

class BreakNode:
    pass

class AsmNode:
    def __init__(self, code):
        self.code = code

class AssignNode:
    def __init__(self, left, right):
        self.left = left
        self.right = right

class BinOpNode:
    def __init__(self, op, left, right):
        self.op = op
        self.left = left
        self.right = right

class UnaryOpNode:
    def __init__(self, op, expr):
        self.op = op
        self.expr = expr

class FuncCallNode:
    def __init__(self, name, args):
        self.name = name
        self.args = args

class LiteralNode:
    def __init__(self, value, type):
        self.value = value
        self.type = type

class VarNode:
    def __init__(self, name):
        self.name = name

# Simple C Parser
class Parser:
    def __init__(self, tokens):
        self.tokens = tokens
        self.pos = 0

    def peek(self, offset=0):
        if self.pos + offset >= len(self.tokens):
            return None
        return self.tokens[self.pos + offset]

    def consume(self, expected_type=None):
        tok = self.peek()
        if tok is None:
            raise Exception("Unexpected EOF")
        if expected_type and tok.type != expected_type:
            raise Exception(f"Line {tok.line}: Expected token of type {expected_type}, got {tok.type} ({repr(tok.value)})")
        self.pos += 1
        return tok

    def parse_program(self):
        globals = []
        functions = []
        
        while self.peek() is not None:
            # Parse top level declaration/definition
            # e.g. int x; void main() { ... }
            type_str = self.parse_type()
            # check if it is a pointer
            while self.peek() and self.peek().type == 'MUL':
                self.consume('MUL')
                type_str += '*'
                
            name_tok = self.consume('IDENT')
            name = name_tok.value
            
            if self.peek() and self.peek().type == 'LPAREN':
                # Function definition
                self.consume('LPAREN')
                params = []
                if self.peek() and self.peek().type != 'RPAREN':
                    while True:
                        p_type = self.parse_type()
                        while self.peek() and self.peek().type == 'MUL':
                            self.consume('MUL')
                            p_type += '*'
                        p_name = self.consume('IDENT').value
                        params.append((p_type, p_name))
                        if self.peek() and self.peek().type == 'COMMA':
                            self.consume('COMMA')
                        else:
                            break
                self.consume('RPAREN')
                
                if self.peek() and self.peek().type == 'SEMI':
                    self.consume('SEMI')
                    continue
                
                # Parse body block
                body = self.parse_block()
                functions.append(FunctionNode(type_str, name, params, body))
            else:
                # Global variable
                init_val = None
                array_size = None
                if self.peek() and self.peek().type == 'LBRACKET':
                    self.consume('LBRACKET')
                    if self.peek() and self.peek().type != 'RBRACKET':
                        sz_tok = self.consume('NUMBER')
                        array_size = int(sz_tok.value, 0)
                    self.consume('RBRACKET')
                    type_str += '[]'
                if self.peek() and self.peek().type == 'ASSIGN':
                    self.consume('ASSIGN')
                    # Parse literal
                    init_tok = self.peek()
                    if init_tok.type in ['NUMBER', 'STRING', 'CHAR']:
                        init_val = self.consume().value
                    else:
                        raise Exception(f"Line {init_tok.line}: Only literals supported in global initializers")
                self.consume('SEMI')
                node = VarDeclNode(type_str, name, init_val)
                node.array_size = array_size
                globals.append(node)
                
        return ProgramNode(globals, functions)

    def parse_type(self):
        tok = self.peek()
        if tok and tok.type in ['INT', 'CHAR_KEY', 'VOID']:
            return self.consume().value
        raise Exception(f"Line {tok.line if tok else 'EOF'}: Expected type, got {tok.type if tok else 'None'} ({repr(tok.value) if tok else 'None'})")

    def parse_block(self):
        self.consume('LBRACE')
        statements = []
        while self.peek() and self.peek().type != 'RBRACE':
            statements.append(self.parse_statement())
        self.consume('RBRACE')
        return BlockNode(statements)

    def parse_statement(self):
        tok = self.peek()
        if tok is None:
            raise Exception("Unexpected EOF in statement")
            
        if tok.type == 'LBRACE':
            return self.parse_block()
            
        if tok.type == 'IF':
            self.consume('IF')
            self.consume('LPAREN')
            cond = self.parse_expression()
            self.consume('RPAREN')
            then_stmt = self.parse_statement()
            else_stmt = None
            if self.peek() and self.peek().type == 'ELSE':
                self.consume('ELSE')
                else_stmt = self.parse_statement()
            return IfNode(cond, then_stmt, else_stmt)
            
        if tok.type == 'WHILE':
            self.consume('WHILE')
            self.consume('LPAREN')
            cond = self.parse_expression()
            self.consume('RPAREN')
            body = self.parse_statement()
            return WhileNode(cond, body)
            
        if tok.type == 'RETURN':
            self.consume('RETURN')
            expr = None
            if self.peek() and self.peek().type != 'SEMI':
                expr = self.parse_expression()
            self.consume('SEMI')
            return ReturnNode(expr)
            
        if tok.type == 'BREAK':
            self.consume('BREAK')
            self.consume('SEMI')
            return BreakNode()
            
        if tok.type == 'ASM':
            self.consume('ASM')
            self.consume('LPAREN')
            code_str = self.consume('STRING').value[1:-1] # strip quotes
            self.consume('RPAREN')
            self.consume('SEMI')
            return AsmNode(code_str)
            
        # Variable declaration
        if tok.type in ['INT', 'CHAR_KEY', 'VOID']:
            type_str = self.parse_type()
            while self.peek() and self.peek().type == 'MUL':
                self.consume('MUL')
                type_str += '*'
            name = self.consume('IDENT').value
            # Support for static array declarations: int arr[N]; char buf[N];
            array_size = None
            if self.peek() and self.peek().type == 'LBRACKET':
                self.consume('LBRACKET')
                if self.peek() and self.peek().type != 'RBRACKET':
                    sz_tok = self.consume('NUMBER')
                    array_size = int(sz_tok.value, 0)
                self.consume('RBRACKET')
                type_str += '[]'
            init_val = None
            if self.peek() and self.peek().type == 'ASSIGN':
                self.consume('ASSIGN')
                init_val = self.parse_expression()
            self.consume('SEMI')
            node = VarDeclNode(type_str, name, init_val)
            node.array_size = array_size
            return node
            
        # Expression statement (e.g. assignment, func call)
        expr = self.parse_expression()
        self.consume('SEMI')
        return expr

    def parse_expression(self):
        return self.parse_assignment()

    def parse_assignment(self):
        # We parse left-hand side
        expr = self.parse_logical_or()
        if self.peek() and self.peek().type == 'ASSIGN':
            self.consume('ASSIGN')
            right = self.parse_assignment()
            return AssignNode(expr, right)
        return expr

    def parse_logical_or(self):
        expr = self.parse_logical_and()
        while self.peek() and self.peek().type == 'OP_OR':
            op = self.consume().value
            right = self.parse_logical_and()
            expr = BinOpNode(op, expr, right)
        return expr

    def parse_logical_and(self):
        expr = self.parse_equality()
        while self.peek() and self.peek().type == 'OP_AND':
            op = self.consume().value
            right = self.parse_equality()
            expr = BinOpNode(op, expr, right)
        return expr

    def parse_equality(self):
        expr = self.parse_relational()
        while self.peek() and self.peek().type in ['OP_EQ', 'OP_NE']:
            op = self.consume().value
            right = self.parse_relational()
            expr = BinOpNode(op, expr, right)
        return expr

    def parse_relational(self):
        expr = self.parse_shift()
        while self.peek() and self.peek().type in ['LT', 'GT', 'OP_LE', 'OP_GE']:
            op = self.consume().value
            right = self.parse_shift()
            expr = BinOpNode(op, expr, right)
        return expr

    def parse_shift(self):
        expr = self.parse_additive()
        while self.peek() and self.peek().type in ['OP_SHL', 'OP_SHR']:
            op = self.consume().value
            right = self.parse_additive()
            expr = BinOpNode(op, expr, right)
        return expr

    def parse_additive(self):
        expr = self.parse_multiplicative()
        while self.peek() and self.peek().type in ['PLUS', 'MINUS']:
            op = self.consume().value
            right = self.parse_multiplicative()
            expr = BinOpNode(op, expr, right)
        return expr

    def parse_multiplicative(self):
        expr = self.parse_unary()
        while self.peek() and self.peek().type in ['MUL', 'DIV', 'MOD']:
            op = self.consume().value
            right = self.parse_unary()
            expr = BinOpNode(op, expr, right)
        return expr

    def parse_unary(self):
        tok = self.peek()
        if tok and tok.type in ['MUL', 'AMP', 'MINUS']:
            op = self.consume().value
            expr = self.parse_unary()
            return UnaryOpNode(op, expr)
        return self.parse_primary()

    def parse_primary(self):
        tok = self.peek()
        if tok is None:
            raise Exception("Unexpected EOF in primary expression")
            
        if tok.type == 'NUMBER':
            val = self.consume().value
            return LiteralNode(int(val, 0), 'int')
            
        if tok.type == 'STRING':
            val = self.consume().value[1:-1] # strip quotes
            return LiteralNode(val, 'string')
            
        if tok.type == 'CHAR':
            val = self.consume().value[1:-1] # strip quotes
            # Handle char escapes
            if val.startswith('\\'):
                escapes = {'n': 10, 't': 9, 'r': 13, '0': 0}
                char_val = escapes.get(val[1], ord(val[1]))
            else:
                char_val = ord(val)
            return LiteralNode(char_val, 'char')
            
        if tok.type == 'IDENT':
            name = self.consume().value
            if self.peek() and self.peek().type == 'LPAREN':
                # Function call
                self.consume('LPAREN')
                args = []
                if self.peek() and self.peek().type != 'RPAREN':
                    while True:
                        args.append(self.parse_expression())
                        if self.peek() and self.peek().type == 'COMMA':
                            self.consume('COMMA')
                        else:
                            break
                self.consume('RPAREN')
                return FuncCallNode(name, args)
            return VarNode(name)
            
        if tok.type == 'LPAREN':
            self.consume('LPAREN')
            expr = self.parse_expression()
            self.consume('RPAREN')
            return expr
            
        raise Exception(f"Line {tok.line}: Unexpected token in expression: {tok.value}")

# Code Generator
class CodeGenerator:
    def __init__(self):
        self.assembly = []
        self.globals = {}      # name -> label
        self.locals = {}       # name -> offset from BP
        self.parameters = {}   # name -> offset from BP
        self.types = {}        # var_name -> type_str
        self.local_count = 0
        self.string_literals = [] # list of (label, value)
        self.label_idx = 0
        self.while_stack = []  # active loops end labels
        
    def gen_label(self, prefix):
        self.label_idx += 1
        return f"{prefix}_{self.label_idx}"

    def emit(self, instruction):
        self.assembly.append(instruction)

    def generate(self, ast):
        # We start by generating the global entry wraps
        self.emit("; --- Bootloader wrap ---")
        self.emit("_global:")
        self.emit("    PUSH BX")
        self.emit("    PUSH AX")
        self.emit("    MOV AX, 0")
        # We fetch boot_string_addr dynamically
        import op
        hex_addr = f"0x{op.BOOT_STRING_ADDR:04X}"
        self.emit(f"    MOV {hex_addr}, n_boot")
        self.emit("    syscall")
        self.emit("    POP AX")
        self.emit("    POP BX")
        self.emit("    jmp _start")
        self.emit("")
        self.emit("_start:")
        self.emit(f"    MOV SP, {op.SP_START}")
        self.emit("    PUSH BX")
        self.emit("    PUSH AX")
        self.emit("    CALL main")
        self.emit("    MOV AX, 60")
        self.emit("    MOV BX, 0")
        self.emit("    syscall")
        self.emit("")

        # Identify all globals
        global_address = 0x1000 # Let's place globals starting at RAM address 0x1000
        for g in ast.globals:
            self.globals[g.name] = g.name
            self.types[g.name] = g.type
            # We will define them in the data section

        # Compile functions
        for f in ast.functions:
            self.compile_function(f)

        # Generate data section at the end
        self.emit("")
        self.emit("; --- Data Section ---")
        self.emit('n_boot db "BOOT"')
        
        # String constants
        for lbl, val in self.string_literals:
            # Escape strings for ASM
            val_escaped = val.replace('\n', '\\n').replace('\t', '\\t').replace('\r', '\\r')
            self.emit(f'{lbl} db "{val_escaped}"')

        # Global variables
        for g in ast.globals:
            array_size = getattr(g, 'array_size', None)
            if array_size is not None:
                # Array: allocate total element bytes initialized to 0
                elem_size = 1 if 'char' in g.type else 4
                total_bytes = array_size * elem_size
                byte_list = ", ".join(["0"] * total_bytes)
                self.emit(f'{g.name} db {byte_list}')
            elif g.init_val is not None:
                if isinstance(g.init_val, int):
                    # integer: write 4 bytes big endian
                    b4 = (g.init_val >> 24) & 0xFF
                    b3 = (g.init_val >> 16) & 0xFF
                    b2 = (g.init_val >> 8) & 0xFF
                    b1 = g.init_val & 0xFF
                    self.emit(f'{g.name} db {b4}, {b3}, {b2}, {b1}')
                elif isinstance(g.init_val, str):
                    # pointer to string constant: we define a local string label first
                    lbl = self.gen_label("str_g")
                    self.string_literals.append((lbl, g.init_val))
                    # global var points to it
                    self.emit(f'{g.name} db 0, 0, {lbl}') # wait, 32-bit address
            else:
                self.emit(f'{g.name} db 0, 0, 0, 0')

        return "\n".join(self.assembly)

    def compile_function(self, f):
        self.locals = {}
        self.parameters = {}
        self.local_count = 0
        
        # Map parameters
        # params: list of (type, name)
        # Offset: standard C convention -> [BP + 8 + 4*idx]
        for idx, (p_type, p_name) in enumerate(f.params):
            self.parameters[p_name] = 8 + 4 * idx
            self.types[p_name] = p_type

        # Scan function body for local variable declarations
        self.scan_locals(f.body)

        self.emit(f"; --- Function {f.name} ---")
        self.emit(f"{f.name}:")
        
        # Prologue
        self.emit("    PUSH BP")
        self.emit("    MOV BP, SP")
        if self.local_count > 0:
            self.emit(f"    SUB SP, {self.local_count * 4}")

        self.epilogue_label = f"epilogue_{f.name}"

        # Compile statement body
        self.compile_statement(f.body)

        # Epilogue
        self.emit(f"{self.epilogue_label}:")
        self.emit("    MOV SP, BP")
        self.emit("    POP BP")
        self.emit("    RET")
        self.emit("")

    def scan_locals(self, node):
        if isinstance(node, BlockNode):
            for stmt in node.statements:
                self.scan_locals(stmt)
        elif isinstance(node, VarDeclNode):
            array_size = getattr(node, 'array_size', None)
            if array_size is not None:
                # Array: allocate array_size slots (each 4 bytes for int, 1 for char)
                elem_size = 1 if 'char' in node.type else 4
                slots = (array_size * elem_size + 3) // 4  # round up to 4-byte words
                self.local_count += slots
                # Variable holds the base address of first slot (lowest address on stack)
                self.locals[node.name] = -4 * self.local_count
                self.types[node.name] = node.type
            else:
                self.local_count += 1
                self.locals[node.name] = -4 * self.local_count
                self.types[node.name] = node.type
        elif isinstance(node, IfNode):
            self.scan_locals(node.then_stmt)
            if node.else_stmt:
                self.scan_locals(node.else_stmt)
        elif isinstance(node, WhileNode):
            self.scan_locals(node.body)

    def compile_statement(self, node):
        if isinstance(node, BlockNode):
            for stmt in node.statements:
                self.compile_statement(stmt)
                
        elif isinstance(node, VarDeclNode):
            array_size = getattr(node, 'array_size', None)
            if array_size is not None:
                offset = self.locals[node.name]
                # Initialize CX to base address of array directly
                self.emit(f"    MOV CX, BP")
                self.emit(f"    SUB CX, {abs(offset)}")
                # zero-initialize array
                elem_size = 1 if 'char' in node.type else 4
                for i in range(array_size):
                    if elem_size == 1:
                        self.emit(f"    MOV AX, 0")
                        self.emit(f"    STORE_B AX, [CX]")
                    else:
                        self.emit(f"    MOV AX, 0")
                        self.emit(f"    STORE AX, [CX]")
                    if i < array_size - 1:
                        self.emit(f"    ADD CX, {elem_size}")
            elif node.init_val is not None:
                self.compile_expression(node.init_val)
                offset = self.locals[node.name]
                self.emit(f"    STORE AX, [BP - {abs(offset)}]")
                
        elif isinstance(node, IfNode):
            self.compile_expression(node.cond)
            self.emit("    CMP AX, 0")
            lbl_else = self.gen_label("else")
            lbl_end = self.gen_label("end_if")
            
            if node.else_stmt:
                self.emit(f"    JZ {lbl_else}")
                self.compile_statement(node.then_stmt)
                self.emit(f"    JMP {lbl_end}")
                self.emit(f"{lbl_else}:")
                self.compile_statement(node.else_stmt)
                self.emit(f"{lbl_end}:")
            else:
                self.emit(f"    JZ {lbl_end}")
                self.compile_statement(node.then_stmt)
                self.emit(f"{lbl_end}:")
                
        elif isinstance(node, WhileNode):
            lbl_start = self.gen_label("while_start")
            lbl_end = self.gen_label("while_end")
            self.while_stack.append(lbl_end)
            
            self.emit(f"{lbl_start}:")
            self.compile_expression(node.cond)
            self.emit("    CMP AX, 0")
            self.emit(f"    JZ {lbl_end}")
            
            self.compile_statement(node.body)
            self.emit(f"    JMP {lbl_start}")
            self.emit(f"{lbl_end}:")
            self.while_stack.pop()
            
        elif isinstance(node, ReturnNode):
            if node.expr:
                self.compile_expression(node.expr)
            self.emit(f"    JMP {self.epilogue_label}")
            
        elif isinstance(node, BreakNode):
            if not self.while_stack:
                raise Exception("Break statement outside of while loop")
            self.emit(f"    JMP {self.while_stack[-1]}")
            
        elif isinstance(node, AsmNode):
            self.emit(f"    {node.code}")
            
        else:
            # Expression statement
            self.compile_expression(node)

    def compile_expression(self, node):
        if isinstance(node, LiteralNode):
            if node.type == 'int' or node.type == 'char':
                self.emit(f"    MOV AX, {node.value}")
            elif node.type == 'string':
                lbl = self.gen_label("str")
                self.string_literals.append((lbl, node.value))
                self.emit(f"    MOV AX, {lbl}")
                
        elif isinstance(node, VarNode):
            # Load variable
            if node.name in self.locals:
                offset = self.locals[node.name]
                var_type = self.types.get(node.name, 'int')
                if var_type.endswith('[]'):
                    self.emit("    MOV AX, BP")
                    self.emit(f"    SUB AX, {abs(offset)}")
                else:
                    self.emit(f"    LOAD AX, [BP - {abs(offset)}]")
            elif node.name in self.parameters:
                offset = self.parameters[node.name]
                self.emit(f"    LOAD AX, [BP + {offset}]")
            elif node.name in self.globals:
                offset = self.globals[node.name]
                var_type = self.types.get(node.name, 'int')
                if var_type.endswith('[]'):
                    self.emit(f"    MOV AX, {node.name}")
                else:
                    self.emit(f"    LOAD AX, [{node.name}]")
            else:
                raise Exception(f"Undefined variable {node.name}")
                
        elif isinstance(node, AssignNode):
            if isinstance(node.left, VarNode):
                self.compile_expression(node.right)
                name = node.left.name
                if name in self.locals:
                    offset = self.locals[name]
                    self.emit(f"    STORE AX, [BP - {abs(offset)}]")
                elif name in self.parameters:
                    offset = self.parameters[name]
                    self.emit(f"    STORE AX, [BP + {offset}]")
                elif name in self.globals:
                    self.emit(f"    STORE AX, [{name}]")
                else:
                    raise Exception(f"Undefined variable {name}")
            elif isinstance(node.left, UnaryOpNode) and node.left.op == '*':
                # Pointer assignment: *ptr = right
                self.compile_expression(node.right)
                self.emit("    PUSH AX")
                # Evaluate pointer expression
                self.compile_expression(node.left.expr)
                self.emit("    POP BX")
                # Determine type of target
                ptr_type = self.get_expr_type(node.left.expr)
                if ptr_type == 'char*':
                    self.emit("    STORE_B BX, [AX]")
                else:
                    self.emit("    STORE BX, [AX]")
            else:
                raise Exception("LHS of assignment must be variable or pointer dereference")
                
        elif isinstance(node, UnaryOpNode):
            if node.op == '*':
                # Dereference: *expr
                self.compile_expression(node.expr)
                # Determine type
                ptr_type = self.get_expr_type(node.expr)
                if ptr_type == 'char*':
                    self.emit("    LOAD_B AX, [AX]")
                else:
                    self.emit("    LOAD AX, [AX]")
            elif node.op == '&':
                # Address-of: &var
                if isinstance(node.expr, VarNode):
                    name = node.expr.name
                    if name in self.locals:
                        offset = self.locals[name]
                        self.emit(f"    MOV AX, BP")
                        self.emit(f"    SUB AX, {abs(offset)}")
                    elif name in self.parameters:
                        offset = self.parameters[name]
                        self.emit(f"    MOV AX, BP")
                        self.emit(f"    ADD AX, {offset}")
                    elif name in self.globals:
                        self.emit(f"    MOV AX, {name}")
                    else:
                        raise Exception(f"Undefined variable {name}")
                else:
                    raise Exception("Cannot take address of non-variable")
            elif node.op == '-':
                self.compile_expression(node.expr)
                self.emit("    NEG AX")
                
        elif isinstance(node, BinOpNode):
            self.compile_expression(node.left)
            self.emit("    PUSH AX")
            self.compile_expression(node.right)
            self.emit("    POP BX")
            
            # BX has left, AX has right.
            # We want to perform operation and leave result in AX.
            if node.op == '+':
                left_type = self.get_expr_type(node.left)
                right_type = self.get_expr_type(node.right)
                if left_type.endswith('*') and left_type != 'char*':
                    self.emit("    MUL AX, 4")
                elif right_type.endswith('*') and right_type != 'char*':
                    self.emit("    MUL BX, 4")
                self.emit("    ADD BX, AX")
                self.emit("    MOV AX, BX")
            elif node.op == '-':
                left_type = self.get_expr_type(node.left)
                if left_type.endswith('*') and left_type != 'char*':
                    self.emit("    MUL AX, 4")
                self.emit("    SUB BX, AX")
                self.emit("    MOV AX, BX")
            elif node.op == '*':
                self.emit("    MUL BX, AX")
                self.emit("    MOV AX, BX")
            elif node.op == '/':
                self.emit("    DIV BX, AX")
                self.emit("    MOV AX, BX")
            elif node.op == '%':
                self.emit("    MOD BX, AX")
                self.emit("    MOV AX, BX")
            elif node.op == '<<':
                self.emit("    SHL BX, AX")
                self.emit("    MOV AX, BX")
            elif node.op == '>>':
                self.emit("    SHR BX, AX")
                self.emit("    MOV AX, BX")
            elif node.op in ['==', '!=', '<', '<=', '>', '>=']:
                # Comparisons: conditionally set AX to 1 or 0
                lbl_true = self.gen_label("cmp_true")
                lbl_end = self.gen_label("cmp_end")
                self.emit("    CMP BX, AX")
                
                cond_jumps = {
                    '==': 'JZ',
                    '!=': 'JNZ',
                    '<': 'JL',
                    '<=': 'JLE',
                    '>': 'JG',
                    '>=': 'JGE'
                }
                self.emit(f"    {cond_jumps[node.op]} {lbl_true}")
                self.emit("    MOV AX, 0")
                self.emit(f"    JMP {lbl_end}")
                self.emit(f"{lbl_true}:")
                self.emit("    MOV AX, 1")
                self.emit(f"{lbl_end}:")
            elif node.op == '&&':
                lbl_false = self.gen_label("and_false")
                lbl_end = self.gen_label("and_end")
                self.emit("    CMP BX, 0")
                self.emit(f"    JZ {lbl_false}")
                self.emit("    CMP AX, 0")
                self.emit(f"    JZ {lbl_false}")
                self.emit("    MOV AX, 1")
                self.emit(f"    JMP {lbl_end}")
                self.emit(f"{lbl_false}:")
                self.emit("    MOV AX, 0")
                self.emit(f"{lbl_end}:")
            elif node.op == '||':
                lbl_true = self.gen_label("or_true")
                lbl_end = self.gen_label("or_end")
                self.emit("    CMP BX, 0")
                self.emit(f"    JNZ {lbl_true}")
                self.emit("    CMP AX, 0")
                self.emit(f"    JNZ {lbl_true}")
                self.emit("    MOV AX, 0")
                self.emit(f"    JMP {lbl_end}")
                self.emit(f"{lbl_true}:")
                self.emit("    MOV AX, 1")
                self.emit(f"{lbl_end}:")
                
        elif isinstance(node, FuncCallNode):
            # Evaluate arguments in reverse order and push
            for arg in reversed(node.args):
                self.compile_expression(arg)
                self.emit("    PUSH AX")
            self.emit(f"    CALL {node.name}")
            if len(node.args) > 0:
                self.emit(f"    ADD SP, {len(node.args) * 4}")

    def get_expr_type(self, node):
        if isinstance(node, VarNode):
            return self.types.get(node.name, 'int')
        if isinstance(node, UnaryOpNode) and node.op == '&':
            sub_type = self.get_expr_type(node.expr)
            return sub_type + '*'
        if isinstance(node, UnaryOpNode) and node.op == '*':
            sub_type = self.get_expr_type(node.expr)
            if sub_type.endswith('*'):
                return sub_type[:-1]
            return 'int'
        if isinstance(node, BinOpNode) and node.op in ['+', '-']:
            left_type = self.get_expr_type(node.left)
            right_type = self.get_expr_type(node.right)
            if left_type.endswith('*'):
                return left_type
            if right_type.endswith('*'):
                return right_type
        return 'int'

def compile_c_to_asm(c_code):
    tokens = tokenize(c_code)
    parser = Parser(tokens)
    ast = parser.parse_program()
    generator = CodeGenerator()
    return generator.generate(ast)

def preprocess_and_compile(input_file):
    # Preprocess
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
        
    includes = re.findall(r'#include\s*[<"]([^>"]+)[>"]', content)
    preprocessed_code = ""
    std_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'std')
    
    impl_map = {
        'stdio.h':  'stdio.c',
        'stdlib.h': 'stdlib.c',
        'string.h': 'string.c',
        'fileio.h': 'fileio.c',
        'gui.h':    'gui.c',
        'http.h':   'http.c',
    }
    
    included_files = set()
    for inc in includes:
        if inc in impl_map and inc not in included_files:
            # 1. Prepend header (.h) file if it exists
            h_file = os.path.join(std_dir, inc)
            if os.path.exists(h_file):
                with open(h_file, 'r', encoding='utf-8') as f:
                    h_code = f.read()
                h_code = re.sub(r'#include\s*[<"][^>"]+[>"]', '', h_code)
                preprocessed_code += f"\n// --- Header {inc} ---\n" + h_code + "\n"
            
            # 2. Prepend implementation (.c) file if it exists
            impl_file = os.path.join(std_dir, impl_map[inc])
            if os.path.exists(impl_file):
                with open(impl_file, 'r', encoding='utf-8') as f:
                    impl_code = f.read()
                impl_code = re.sub(r'#include\s*[<"][^>"]+[>"]', '', impl_code)
                preprocessed_code += f"\n// --- Include {inc} ---\n" + impl_code + "\n"
            included_files.add(inc)
                
    main_code = re.sub(r'#include\s*[<"][^>"]+[>"]', '', content)
    preprocessed_code += "\n// --- Main Program ---\n" + main_code
    
    # Process #define macros
    defines = re.findall(r'#define\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+([^\n]+)', preprocessed_code)
    preprocessed_code = re.sub(r'#define\s+[a-zA-Z_][a-zA-Z0-9_]*\s+[^\n]+', '', preprocessed_code)
    
    # Sort by length to avoid partial shadowing
    defines.sort(key=lambda x: len(x[0]), reverse=True)
    for name, val in defines:
        preprocessed_code = re.sub(r'\b' + name + r'\b', val.strip(), preprocessed_code)
        
    # Strip any other remaining preprocessor lines (e.g. #ifndef, #endif)
    preprocessed_code = re.sub(r'(?m)^#[a-zA-Z_].*$', '', preprocessed_code)
        
    # Compile C to ASM
    asm_code = compile_c_to_asm(preprocessed_code)
    return asm_code

def main():
    if len(sys.argv) < 2:
        print("Usage: python cc.py <input_file.c> [output_file.s]")
        sys.exit(1)
        
    input_file = sys.argv[1]
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    else:
        output_file = os.path.splitext(input_file)[0] + '.s'
        
    print(f"Preprocessing and compiling {input_file} -> {output_file}...")
    try:
        asm_code = preprocess_and_compile(input_file)
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(asm_code)
        print("C Compilation to Assembly successful!")
        
        # Now compile Assembly to Disk .ds!
        disk_file = os.path.splitext(input_file)[0] + '.ds'
        print(f"Compiling generated assembly {output_file} -> {disk_file}...")
        disk_string = comp.compile_to_disk_string(output_file)
        
        with open(disk_file, 'w', encoding='utf-8') as f:
            f.write(disk_string + '\n')
        print(f"Compilation to Disk image successful! Output: {disk_file}")
        
    except Exception as e:
        print(f"Compilation failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
