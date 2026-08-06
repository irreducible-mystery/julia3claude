% simple ASP test: graph 3-coloring
node(1..3). edge(1,2). edge(2,3).
color(red;green;blue).
1 { assign(N,C) : color(C) } 1 :- node(N).
:- edge(X,Y), assign(X,C), assign(Y,C).
#show assign/2.
