neg(x) = 1 - x
function damped_limit(f, x0, a; n = 20_000)
    x = x0
    for _ in 1:n; x = (1-a)*x + a*f(x) end
    x
end
println("liar map — damped limit vs damping a and start x0:")
println(rpad("a", 8), rpad("x0=0.0", 12), rpad("x0=1.0", 12), rpad("x0=0.3", 12), "x0=0.87")
for a in (0.05, 0.25, 0.5, 0.75, 1.0)
    row = [damped_limit(neg, x0, a) for x0 in (0.0, 1.0, 0.3, 0.87)]
    println(rpad(a, 8), join([rpad(round(r, digits=6), 12) for r in row]))
end
let x = 0.0, orbit = Float64[]
    for _ in 1:6; push!(orbit, x); x = neg(x) end
    println("\nundamped orbit from 0.0: ", orbit, "  → 2-cycle {0,1}, Cesàro mean 0.5")
end
g(x) = x < 0.5 ? 0.9 : 0.1
println("a DIFFERENT map, 2-cycle {0.1,0.9}: damped limit (a=0.25) = ",
        round(damped_limit(g, 0.0, 0.25), digits=6), "   its midpoint = 0.5")
h(x) = x < 0.5 ? 0.6 : 0.4
println("a THIRD map, 2-cycle {0.4,0.6}:     damped limit (a=0.25) = ",
        round(damped_limit(h, 0.0, 0.25), digits=6), "   its midpoint = 0.5")
