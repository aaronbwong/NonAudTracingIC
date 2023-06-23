Rotate = 0;
FlipHori = 0;
FlipVert = 0;
Dialog.create("Rotate/Flip")
Dialog.addNumber("Rotate N x right angles:",Rotate);
Dialog.addNumber("Flip Horizontally:",FlipHori);
Dialog.show();
Rotate = Dialog.getNumber();
FlipHori = Dialog.getNumber();
for(i = 0; i < Rotate; i++) {
	run("Rotate 90 Degrees Right");
}
if (FlipHori) {
	run("Flip Horizontally");
}
