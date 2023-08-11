import BigInt
import Foundation

enum AppError : Error {
    case TimedOut
}

@main
public struct Fibonacci {
    func fibonacciFunctional(_ n: Int) -> BInt {
        // Fibonacci implementation that is tail call optimizable by other compilers (but not Swift)
        func fibonacciTail(_ remaining: Int, _ lastLastfib: BInt, _ lastFib: BInt) -> BInt {
            guard remaining > 1 else { return lastFib }
            return fibonacciTail(remaining - 1, lastFib, lastLastfib + lastFib)
        }
        guard n > 0 else { return BInt(0) }
        return fibonacciTail(n, BInt(0), BInt(1))
    }
    
    func fibonacci(_ n: Int) -> BInt {
        var fib = BInt.ZERO, lastFib = BInt.ONE
        
        if n < 1 {
            return fib
        }
        for _ in 1...n {
            lastFib += fib
            swap(&fib, &lastFib)
        }
        return fib
    }
    
    func cancellableFibonacci(_ n: Int) throws -> BInt {
        var fib = BInt.ZERO, lastFib = BInt.ONE
        
        if n < 1 {
            return fib
        }
        for _ in 1...n {
            lastFib += fib
            swap(&fib, &lastFib)
            try Task.checkCancellation()
        }
        return fib
    }
    
    public static func main() async {
        let fib = Fibonacci()
        for n in 0...99 {
            print("\(n): \((try? fib.cancellableFibonacci(n))?.description ?? "oops")")
        }
        
        let cancellableFibStart: Date = Date()
        do {
            let result: BInt = try await withThrowingTaskGroup(of: BInt.self) { group in
                defer { group.cancelAll() }
                
                group.addTask {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    throw AppError.TimedOut
                }
                group.addTask {
                    return try fib.cancellableFibonacci(100_000)
                }
                
                return try await group.first { _ in true }!
            }
            print(result)
        } catch {
            let elapsedSeconds: Double = cancellableFibStart.distance(to: Date())
            print("timed out after \(String(format: "%.2f", elapsedSeconds))")
        }
        
        let fibStart: Date = Date()
        do {
            let result: BInt = try await withThrowingTaskGroup(of: BInt.self) { group in
                defer { group.cancelAll() }
                
                group.addTask {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    throw AppError.TimedOut
                }
                group.addTask {
                    return fib.fibonacci(100_000)
                }
                
                return try await group.first { _ in true }!
            }
            print(result)
        } catch {
            // Depending on how long fibonacci takes, this can be well beyond the 5 second timeout
            let elapsedSeconds: Double = fibStart.distance(to: Date())
            print("timed out after \(String(format: "%.2f", elapsedSeconds))")
        }
    }
}
