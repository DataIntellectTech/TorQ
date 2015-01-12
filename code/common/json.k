// Created by Arthur Whitney, kx Systems
// Should be kept up to date if/when updates are available

\d .j
/[]{} Cbg*xhijefcspmdznuvt
q:"\"";s:{q,x,q};t:{s$[#x;@[x;4 7;:;"-"];x]}
J:(($`0`1)!$`false`true;s;{$[#x;x;"null"]};s;t;s)1 2 5 10 12 16h bin

/enclose
e:{(*x),(","/:y),*|x}
j:{$[10=t:@x;s x;99=t;e["{}"](j'!x),'":",'j'. x;-1<t;e["[]"]@j'x;J[-t]@$x]}

/dsclose
d:{1_'(0,&(","=x)&1=+\1 -1 1 -1"{}[]"?x)_-1_x}
k:{$["{"=*x;!/+{(`$k n#x;k(1+n:x?":")_x)}'d x;"["=*x;k'd x;q=*x;1_-1_x;"a">*x;. x;"n"=*x;0N;"t"=*x]}
