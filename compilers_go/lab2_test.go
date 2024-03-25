package main

import "fmt"

var d, e int = 6, 5
var f int

type count int

var (
	x, y    int     = 1, 2
	u, v, w float32 = 1, 2, 3
)

func main() {
	var a, b, c string
	var hello string

	type myString string

	a = "hello,"
	b = " world"
	c = "!"

	f = d + e

	hello = a + b + c
	fmt.Println(hello)
	fmt.Println(f)
}

var k, g bool

func some() {}
