neg(x) = 1 - x
function damped_limit(f, x0, a; n = 20_000)
    x = x0
    for _ in 1:n; x = (1-a)*x + a*f(x) end
    x
end
failures = String[]
fail(msg) = push!(failures, msg)

println("liar map — damped limit vs damping a and start x0:")
println(rpad("a", 8), rpad("x0=0.0", 12), rpad("x0=1.0", 12), rpad("x0=0.3", 12), "x0=0.87")
for a in (0.05, 0.25, 0.5, 0.75, 0.95)
    row = [damped_limit(neg, x0, a) for x0 in (0.0, 1.0, 0.3, 0.87)]
    all(isapprox.(row, 0.5; atol=1e-9)) ||
        fail("liar map did not damp to 0.5 for a=$a")
    println(rpad(a, 8), join([rpad(round(r, digits=6), 12) for r in row]))
end
let x = 0.0, orbit = Float64[]
    for _ in 1:6; push!(orbit, x); x = neg(x) end
    println("\nundamped orbit from 0.0: ", orbit, "  → 2-cycle {0,1}, Cesàro mean 0.5")
end
undamped = [damped_limit(neg, x0, 1.0) for x0 in (0.0, 1.0, 0.3, 0.87)]
any(!isapprox(x, 0.5; atol=1e-9) for x in undamped) ||
    fail("undamped case a=1.0 was not distinguished from the damped regime")
g(x) = x < 0.5 ? 0.9 : 0.1
g_limit = damped_limit(g, 0.0, 0.25)
abs(g_limit - 0.5) > 0.01 ||
    fail("generic 2-cycle {0.1,0.9} damped to its midpoint")
println("a DIFFERENT map, 2-cycle {0.1,0.9}: damped limit (a=0.25) = ",
        round(g_limit, digits=6), "   its midpoint = 0.5")
h(x) = x < 0.5 ? 0.6 : 0.4
h_limit = damped_limit(h, 0.0, 0.25)
abs(h_limit - 0.5) > 0.01 ||
    fail("generic 2-cycle {0.4,0.6} damped to its midpoint")
println("a THIRD map, 2-cycle {0.4,0.6}:     damped limit (a=0.25) = ",
        round(h_limit, digits=6), "   its midpoint = 0.5")

if isempty(failures)
    println("\npal2v_damping: all checks pass (0<a<1 damping, undamped control, non-midpoint controls)")
else
    error("pal2v_damping FAILED: " * join(failures, "; "))
end
