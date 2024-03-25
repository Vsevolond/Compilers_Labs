package main

import (
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"os"
)

func splitDeclareBlocks(file *ast.File) {
	file.Decls = splitGlobalDeclare(file.Decls)

	for i := 0; i < len(file.Decls); i++ {
		if funcDecl, ok := file.Decls[i].(*ast.FuncDecl); ok {
			funcDecl.Body.List = splitLocalDeclare(funcDecl.Body.List)
			file.Decls[i] = funcDecl
		}
	}
}

func splitGlobalDeclare(decls []ast.Decl) []ast.Decl {

	if len(decls) > 0 {

		if genDecl, ok := decls[0].(*ast.GenDecl); ok && (genDecl.Tok == token.VAR) {
			var newGenDecls = make([]ast.Decl, 0)

			for _, spec := range genDecl.Specs {
				valueSpec, _ := spec.(*ast.ValueSpec)

				for i := 0; i < len(valueSpec.Names); i++ {
					var name = valueSpec.Names[i]

					if valueSpec.Values == nil {
						newGenDecls = append(newGenDecls, makeGenDecl(name, valueSpec.Type, nil))
					} else {
						var value = valueSpec.Values[i]
						newGenDecls = append(newGenDecls, makeGenDecl(name, valueSpec.Type, []ast.Expr{value}))
					}
				}
			}

			return append(newGenDecls, splitGlobalDeclare(decls[1:])...)

		} else {
			return append([]ast.Decl{decls[0]}, splitGlobalDeclare(decls[1:])...)
		}

	} else {
		return nil
	}
}

func splitLocalDeclare(decls []ast.Stmt) []ast.Stmt {
	if len(decls) > 0 {
		if declStmt, ok := decls[0].(*ast.DeclStmt); ok {
			if genDecl, ok := declStmt.Decl.(*ast.GenDecl); ok && (genDecl.Tok == token.VAR) {

				var newGenDecls = make([]ast.Stmt, 0)

				for _, spec := range genDecl.Specs {
					valueSpec, _ := spec.(*ast.ValueSpec)

					for i := 0; i < len(valueSpec.Names); i++ {
						var name = valueSpec.Names[i]

						if valueSpec.Values == nil {
							newGenDecls = append(newGenDecls, &ast.DeclStmt{Decl: makeGenDecl(name, valueSpec.Type, nil)})
						} else {
							var value = valueSpec.Values[i]
							newGenDecls = append(newGenDecls, &ast.DeclStmt{Decl: makeGenDecl(name, valueSpec.Type, []ast.Expr{value})})
						}
					}
				}

				return append(newGenDecls, splitLocalDeclare(decls[1:])...)

			} else {
				return append([]ast.Stmt{decls[0]}, decls[1:]...)
			}

		} else {
			return append([]ast.Stmt{decls[0]}, decls[1:]...)
		}
	} else {
		return nil
	}
}

func makeGenDecl(name *ast.Ident, varType ast.Expr, value []ast.Expr) *ast.GenDecl {
	return &ast.GenDecl{
		Tok: token.VAR,
		Specs: []ast.Spec{
			&ast.ValueSpec{
				Names:  []*ast.Ident{name},
				Type:   varType,
				Values: value,
			},
		},
	}
}

func main() {
	if len(os.Args) != 2 {
		return
	}

	fset := token.NewFileSet()
	if file, err := parser.ParseFile(fset, os.Args[1], nil, parser.ParseComments); err == nil {
		splitDeclareBlocks(file)

		if format.Node(os.Stdout, fset, file) != nil {
			fmt.Printf("Formatter error: %v\n", err)
		}
		//ast.Fprint(os.Stdout, fset, file, nil)
	} else {
		fmt.Printf("Errors in %s\n", os.Args[1])
	}
}
