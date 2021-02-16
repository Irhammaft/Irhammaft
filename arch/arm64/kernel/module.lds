SECTIONS {
	.plt : { BYTE(0) }
	.init.plt : { BYTE(0) }
	.text.ftrace_trampoline : { BYTE(0) }
	.plt 0 (NOLOAD) : { BYTE(0) }
	.init.plt 0 (NOLOAD) : { BYTE(0) }
	.text.ftrace_trampoline 0 (NOLOAD) : { BYTE(0) }
}
