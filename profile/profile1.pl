
sub get_profile {
    return  {
	target => {
	    binary=>'app.elf',
	    srec=>'app.srec',
	    dir=>"../target/sample1",
	    entry_addr=>0x20010000
	},
	platform => {
	    machine=>"sifive_e",
	    isa=>'rv32i',
	    regsize=>32,  ## TODO: move to RISCV object
	    inst_size=>4, ## TODO: move to RISCV object
	    ram=>{start=>0x80000000, end=>0x80003FFF}
	},
	tools => {
	    qemu=>'qemu-system-riscv32',
	    openocd=>'/usr/bin/JLinkGDBServer',
	    writer=>'/usr/bin/JLinkExe',
	    poyov_server=>{
		dir=>'/home/xilinx/fpga',
#		program=>"ssh iana.local 'cd /home/xilinx/fpga;sudo python3 serv.py>aaa.log'",
		program=>"cat>aaa.log",
		addr=>'iana.local',
		port=>'5678'
		    #	    port=>'6789'
	    },
	},
	syscall => {
	    top_dir=>'./file_sys'
	}
    };
}
1;
