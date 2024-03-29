import abc
import enum
import typing
from dataclasses import dataclass
from typing import Optional

class TypeKind(enum.Enum):
    Global = 'GLOBAL'
    Local = 'LOCAL'

@dataclass
class Type:
    kind: TypeKind
    name: str

class GlobalType(enum.Enum):
    Integer = Type(TypeKind.Global, 'INTEGER')
    Real = Type(TypeKind.Global, 'REAL')
    Boolean = Type(TypeKind.Global, 'BOOLEAN')

@dataclass
class VarType:
    type: Type
    is_pointer: bool

@dataclass
class VarsDef:
    names: list[str]
    type: VarType

@dataclass
class TypeDef:
    name: str
    parent_type: Optional[Type]
    varDefs: list[VarsDef]

class Statement(abc.ABC):
    pass

@dataclass
class Program:
    type_defs: list[TypeDef]
    var_defs: list[VarsDef]
    statements: list[Statement]

class Expr(abc.ABC):
    pass

@dataclass
class VarChain:
    variables: list[str]

@dataclass
class AssignStatement(Statement):
    variable: VarChain
    expr: Expr

@dataclass
class PointerStatement(Statement):
    pointer_name: str
    variable: VarChain

@dataclass
class CreateStatement(Statement):
    pointer_name: str

@dataclass
class IfStatement(Statement):
    condition: Expr
    then_branch: list[Statement]
    else_branch: list[Statement]

@dataclass
class WhileStatement(Statement):
    condition: Expr
    body: list[Statement]

@dataclass
class VariableExpr(Expr):
    var_name: VarChain

@dataclass
class ConstExpr(Expr):
    value: typing.Any
    type: Type

@dataclass
class BinOpExpr(Expr):
    left: Expr
    op: str
    right: Expr

@dataclass
class UnOpExpr(Expr):
    op: str
    expr: Expr


