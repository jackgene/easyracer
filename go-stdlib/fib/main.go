package main

import (
	"context"
	"errors"
	"log"
	"math/big"
	"time"
)

func Fibonacci(n int) *big.Int {
	fib, lastFib := big.NewInt(0), big.NewInt(1)
	if n < 1 {
		return fib
	}
	for i := 0; i < n; i++ {
		lastFib.Add(lastFib, fib)
		lastFib, fib = fib, lastFib
	}

	return fib
}

func CancellableFibonacci(ctx context.Context, n int) (*big.Int, error) {
	// In Go, nil conforms to context.Context. Check for nil, because we are not savages.
	if ctx == nil {
		return nil, errors.New("ctx cannot be nil")
	}
	fib, lastFib := big.NewInt(0), big.NewInt(1)
	if n < 1 {
		return fib, nil
	}
	for i := 0; i < n; i++ {
		lastFib.Add(lastFib, fib)
		lastFib, fib = fib, lastFib
		if ctxErr := ctx.Err(); ctxErr != nil {
			return nil, ctxErr
		}
	}

	return fib, nil
}

func main() {
	n := 5_000_000
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Second)
	defer cancel()
	fib, err := CancellableFibonacci(ctx, n)
	if err != nil {
		log.Fatalf("Fibonacci calculation failed: %v", err)
		return
	}

	log.Println(fib.Text(10))
}
