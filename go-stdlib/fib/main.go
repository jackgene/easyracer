package main

import (
	"context"
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
	fib, lastFib := big.NewInt(0), big.NewInt(1)
	if n < 1 {
		return fib, nil
	}
	yield := make(chan struct{}, 1)
	for i := 0; i < n; i++ {
		lastFib.Add(lastFib, fib)
		lastFib, fib = fib, lastFib
		yield <- struct{}{}
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-yield:
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
