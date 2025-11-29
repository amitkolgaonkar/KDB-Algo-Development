/ u.q — provides .u namespace and update functions

/ Root namespace .u
.u:()

/ Append row to a table
.u.upd:{[tbl; row] @[value tbl; (); ,; row]}

/ Show message (optional)
.u.log:{[msg] show "LOG: ", string msg}
