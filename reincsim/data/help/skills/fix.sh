perl -e '@lines=<>; $all=join("", @lines); $all=~tr/\x0D\x0A/ /d; $all=~s/(Cost of training)(\s+)/$1 /g; $all=~s/(\-|=) (\-|=)/$1$2/g;$all=~s/More \(\d+%\) \[qpbns\??] //g; for ($x=0;$x<length $all;$x+=52) {print substr($all,$x,52), "\n";}' <$1 >$2