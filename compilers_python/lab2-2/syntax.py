import parser_edsl as pe
import re

from data_types import *

VARNAME = pe.Terminal('VARNAME', '[a-z][A-Za-z0-9]*', str)
TYPENAME = pe.Terminal('TYPENAME', '[A-Z][A-Za-z0-9]*', str)
INTEGER = pe.Terminal('INTEGER', '[0-9]+', int, priority=7)
REAL = pe.Terminal('REAL', '[0-9]+(\\.[0-9]*)?(e[-+]?[0-9]+)?', float)

def make_keyword(image):
    return pe.Terminal(image, image, lambda name: None, priority=10)

KW_TYPE, KW_RECORD, KW_VAR, KW_BEGIN, KW_END = map(make_keyword, 'TYPE RECORD VAR BEGIN END'.split())
KW_IF, KW_THEN, KW_ELSE, KW_WHILE, KW_DO = map(make_keyword, 'IF THEN ELSE WHILE DO'.split())
KW_INTEGER, KW_REAL, KW_BOOLEAN = map(make_keyword, 'INTEGER REAL BOOLEAN'.split())
KW_OR, KW_DIV, KW_MOD, KW_AND, KW_NOT, KW_TRUE, KW_FALSE = map(make_keyword, 'OR DIV MOD AND NOT TRUE FALSE'.split())

NProgram, NTypeDefs, NVarDefs, NStatements = map(pe.NonTerminal, 'Program TypeDefs VarDefs Statements'.split())
NVarsDef, NVarNames, NVarChain, NVarsArr  = map(pe.NonTerminal, 'VarsDef VarNames VarChain VarsArr'.split())
NTypeDef, NTypeCommonDef, NTypeExtendDef = map(pe.NonTerminal, 'TypeDef TypeCommonDef TypeExtendDef'.split())
NVarType, NType = map(pe.NonTerminal, 'VarType Type'.split())

NStatement, NExpr, NArithmExpr = map(pe.NonTerminal, 'Statement Expr ArithmExpr'.split())
NCmpOp, NAddOp, NMulOp = map(pe.NonTerminal, 'CmpOp AddOp MulOp'.split())
NTerm, NFactor, NConst = map(pe.NonTerminal, 'Term Factor Const'.split())

NProgram |= KW_TYPE, NTypeDefs, KW_VAR, NVarDefs, KW_BEGIN, NStatements, KW_END, '.', Program

NVarDefs |= NVarsDef, NVarDefs, lambda vars_def, var_defs: vars_def + var_defs
NVarDefs |= lambda: []

NVarsDef |= NVarNames, ':', NVarType, ';', lambda var_names, var_type: list(map(lambda var_name: VarDef(var_name, var_type), var_names))

NVarNames |= VARNAME, ',', NVarNames, lambda var_name, var_names: [var_name] + var_names
NVarNames |= VARNAME, lambda var_name: [var_name]

NVarChain |= NVarsArr, lambda vars_arr: VarChain(vars_arr)
NVarsArr |= VARNAME, '.', NVarsArr, lambda var_name, vars_arr: [var_name] + vars_arr
NVarsArr |= VARNAME, lambda var_name: [var_name]

NVarType |= NType, lambda type: VarType(type, False)
NVarType |= 'POINTER', 'TO', NType, lambda type: VarType(type, True)

NType |= KW_INTEGER, lambda: GlobalType.Integer
NType |= KW_REAL, lambda: GlobalType.Real
NType |= KW_BOOLEAN, lambda: GlobalType.Boolean
NType |= TYPENAME, lambda type_name: Type(TypeKind.Local, type_name)

NTypeDefs |= NTypeDef, NTypeDefs, lambda type_def, type_defs: [type_def] + type_defs
NTypeDefs |= lambda: []

NTypeDef |= NTypeCommonDef
NTypeDef |= NTypeExtendDef

NTypeCommonDef |= TYPENAME, '=', KW_RECORD, NVarDefs, KW_END, ';', \
    lambda type_name, var_defs: TypeDef(type_name, None, var_defs)

NTypeExtendDef |= TYPENAME, '=', KW_RECORD, '(', NType, ')', NVarDefs, KW_END, ';', \
    lambda type_name, parent_type, var_defs: TypeDef(type_name, parent_type, var_defs)

NStatements |= NStatement, NStatements, lambda statement, statements: [statement] + statements
NStatements |= NStatement, lambda statement: [statement]

NStatement |= NVarChain, ':=', NExpr, ';', AssignStatement
NStatement |= VARNAME, '^', ':=', NVarChain, ';', PointerStatement
NStatement |= 'NEW', '(', VARNAME, ')', ';', CreateStatement
NStatement |= KW_IF, NExpr, KW_THEN, NStatements, KW_ELSE, NStatements, KW_END, ';', IfStatement
NStatement |= KW_WHILE, NExpr, KW_DO, NStatements, KW_END, ';', WhileStatement

NExpr |= NArithmExpr
NExpr |= NArithmExpr, NCmpOp, NArithmExpr, BinOpExpr

def make_op_lambda(op):
    return lambda: op

for op in ('>', '<', '>=', '<=', '=', '#'):
    NCmpOp |= op, make_op_lambda(op)

NArithmExpr |= NTerm
NArithmExpr |= '+', NTerm, lambda term: UnOpExpr('+', term)
NArithmExpr |= '-', NTerm, lambda term: UnOpExpr('-', term)
NArithmExpr |= NArithmExpr, NAddOp, NTerm, BinOpExpr

NAddOp |= '+', lambda: '+'
NAddOp |= '-', lambda: '-'
NAddOp |= KW_OR, lambda: 'OR'

NTerm |= NFactor
NTerm |= NTerm, NMulOp, NFactor, BinOpExpr

NMulOp |= '*', lambda: '*'
NMulOp |= '/', lambda: '/'
NMulOp |= KW_DIV, lambda: 'DIV'
NMulOp |= KW_MOD, lambda: 'MOD'
NMulOp |= KW_AND, lambda: 'AND'

NFactor |= KW_NOT, NFactor, lambda factor: UnOpExpr('NOT', factor)
NFactor |= NVarChain, VariableExpr
NFactor |= NConst
NFactor |= '(', NExpr, ')'

NConst |= INTEGER, lambda value: ConstExpr(value, GlobalType.Integer)
NConst |= REAL, lambda value: ConstExpr(value, GlobalType.Real)
NConst |= KW_TRUE, lambda: ConstExpr(True, GlobalType.Boolean)
NConst |= KW_FALSE, lambda: ConstExpr(False, GlobalType.Boolean)

def make_parser():
    parser = pe.Parser(NProgram)
    assert parser.is_lalr_one()

    parser.add_skipped_domain('\\s')
    parser.add_skipped_domain('\\(\\*.*?\\*\\)')

    return parser