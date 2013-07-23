function alt = press2alt(press)
    pp=(press/101325);
    L=0.0065;
    R=8.31447;
    M=0.0289644;
    g=9.80655;
    alt = (1-(pp)^(1/(g*M/R/L)))*288.15/L;
end