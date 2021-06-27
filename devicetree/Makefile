all: dpidmg.dtbo dt-blob.bin dmgbuttons.dtbo

dpidmg.dtbo: dpidmg-overlay.dts
	dtc -O dtb -o dpidmg.dtbo -@ dpidmg-overlay.dts

dmgbuttons.dtbo: dmgbuttons.dts
	dtc -O dtb -o dmgbuttons.dtbo -@ dmgbuttons.dts


dt-blob.bin: dt-blob.dts
	dtc -O dtb -o dt-blob.bin -@ dt-blob.dts
