const byteColorDepth = 4,
	sbOffset = 0,
	width = 1400,
	height = 600,
	mem_pages = 3;

const widthAsm = new WebAssembly.Global({ value: "i32", mutable: false }, width);
const heightAsm = new WebAssembly.Global({ value: "i32", mutable: false }, height);
const bCD = new WebAssembly.Global({ value: "i32", mutable: false }, byteColorDepth);

const mem_pagesAsm = new WebAssembly.Memory({
	initial: Math.ceil((width * height * byteColorDepth) / (64 * 1024))
	//maximum: 256
});

var imports = {
	js: {
		width: widthAsm,
		height: heightAsm,
		bCD: bCD,
		mem_pages: mem_pagesAsm
	}
};

fetch("main.wasm")
	.then(response => response.arrayBuffer())
	.then(bytes => WebAssembly.instantiate(bytes, imports))
	.then(results => {
		var instance = results.instance,
			module = instance.exports,
			imageDataArray = new Uint8ClampedArray(mem_pagesAsm.buffer, sbOffset, width * height * byteColorDepth);

		var canvas = document.getElementById("screen");
		canvas.height = height;
		canvas.width = width;
		var ctx = canvas.getContext("2d");
		var img = new ImageData(imageDataArray, width, height);

		var res = (delay = segtimer = 0);
		var seg = 2;
		var start = null;

		// res = module.main();

		function step(timestamp) {
			if (!start) start = timestamp;
			var progress = timestamp - start;

			if (segtimer + 5000 < progress) {
				seg++;
				if (seg > 6) seg = 3;
				segtimer = progress;
			}

			if (delay + 150 < progress) {
				res = module.main(seg);
				ctx.putImageData(img, 0, 0);
				delay = progress;
			}

			if (progress < 25000) {
				window.requestAnimationFrame(step);
			}
		}

		window.requestAnimationFrame(step);

		// Debug
		// console.log(width*height*byteColorDepth);
		// console.log(imageDataArray);
		// console.log(ctx);
		// console.log(res);
		// console.log(global.value);

		//document.getElementById("container").textContent = module.add(1,1);
	})
	.catch(console.error);
