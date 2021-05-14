#! /bin/sed
s/^\s+//
1s/(.+?):/RUNREPORT: \1\n/
/-{10}/d
/^[a-z]+_\|/d
/p?changes:/d
/^[a-z_]+:/ {
N
s/\n\s+/ /
}
/^(__run_num__|duration|name|result|start_time)|__state_ran__/d
s/__id__/ID/
s/__sls__/SLS/
s/comment:(.+)/Comment: \1\n/
